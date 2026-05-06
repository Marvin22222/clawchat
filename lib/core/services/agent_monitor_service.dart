import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/agent_session.dart';
import '../../models/agent_status.dart';

/// Service for managing real-time agent status via WebSocket connection
/// 
/// This service handles:
/// - WebSocket connection management
/// - Agent status updates via WebSocket events
/// - Reconnection logic with exponential backoff
/// - Mock data fallback for development
class AgentMonitorService extends ChangeNotifier {
  // Singleton pattern
  static final AgentMonitorService _instance = AgentMonitorService._internal();
  factory AgentMonitorService() => _instance;
  AgentMonitorService._internal();

  // WebSocket connection
  WebSocketConnection? _connection;
  
  // Agent data
  List<AgentSession> _agents = [];
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  
  // Reconnection config
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  
  // Stream controller for agent updates
  final StreamController<List<AgentSession>> _agentUpdateController =
      StreamController<List<AgentSession>>.broadcast();

  // Getters
  List<AgentSession> get agents => List.unmodifiable(_agents);
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  int get reconnectAttempts => _reconnectAttempts;
  Stream<List<AgentSession>> get agentUpdates => _agentUpdateController.stream;

  /// Active agent count (LIVE or BUSY)
  int get activeCount => _agents
      .where((a) => a.status == AgentStatus.live || a.status == AgentStatus.busy)
      .length;

  /// Error count
  int get errorCount => _agents.where((a) => a.status == AgentStatus.error).length;

  /// Initialize the service - starts connection if not already connected
  Future<void> initialize() async {
    if (_connection != null) return;
    await connect();
  }

  /// Connect to the agent WebSocket endpoint
  Future<bool> connect() async {
    if (_isConnected || _isReconnecting) return _isConnected;

    try {
      _isReconnecting = true;
      notifyListeners();

      // In production, this would connect to the actual WebSocket endpoint
      // For now, use mock data
      await _loadMockData();

      _isConnected = true;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      notifyListeners();

      return true;
    } catch (e) {
      _isConnected = false;
      _isReconnecting = false;
      notifyListeners();
      
      // Attempt reconnection
      await _attemptReconnect();
      return false;
    }
  }

  /// Disconnect from the WebSocket
  void disconnect() {
    _connection?.disconnect();
    _connection = null;
    _isConnected = false;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  /// Attempt to reconnect with exponential backoff
  Future<void> _attemptReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[AgentMonitorService] Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _initialReconnectDelay * (2 ^ (_reconnectAttempts - 1));

    debugPrint('[AgentMonitorService] Reconnection attempt $_reconnectAttempts in $delay');

    _isReconnecting = true;
    notifyListeners();

    await Future.delayed(delay);
    await connect();
  }

  /// Handle incoming WebSocket message
  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'agent_update':
        _handleAgentUpdate(data['payload']);
        break;
      case 'agents_snapshot':
        _handleAgentsSnapshot(data['payload']);
        break;
      case 'agent_removed':
        _handleAgentRemoved(data['payload']);
        break;
      case 'connection_status':
        _handleConnectionStatus(data['payload']);
        break;
      default:
        debugPrint('[AgentMonitorService] Unknown message type: $type');
    }
  }

  void _handleAgentUpdate(Map<String, dynamic>? payload) {
    if (payload == null) return;

    final agentId = payload['id'] as String?;
    if (agentId == null) return;

    final index = _agents.indexWhere((a) => a.id == agentId);
    if (index != -1) {
      _agents[index] = AgentSession.fromJson(payload);
    } else {
      _agents.add(AgentSession.fromJson(payload));
    }

    _agentUpdateController.add(_agents);
    notifyListeners();
  }

  void _handleAgentsSnapshot(List<dynamic>? payload) {
    if (payload == null) return;

    _agents = payload
        .map((json) => AgentSession.fromJson(json as Map<String, dynamic>))
        .toList();

    _agentUpdateController.add(_agents);
    notifyListeners();
  }

  void _handleAgentRemoved(Map<String, dynamic>? payload) {
    final agentId = payload?['id'] as String?;
    if (agentId == null) return;

    _agents.removeWhere((a) => a.id == agentId);
    _agentUpdateController.add(_agents);
    notifyListeners();
  }

  void _handleConnectionStatus(Map<String, dynamic>? payload) {
    final connected = payload?['connected'] as bool? ?? false;
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();

      if (!connected) {
        _attemptReconnect();
      }
    }
  }

  /// Send a message to an agent
  Future<void> sendMessageToAgent(String agentId, String message) async {
    if (!_isConnected) {
      debugPrint('[AgentMonitorService] Cannot send message - not connected');
      return;
    }

    _connection?.send({
      'type': 'send_message',
      'payload': {
        'agentId': agentId,
        'message': message,
      },
    });
  }

  /// Cancel a task for an agent
  Future<void> cancelAgentTask(String agentId) async {
    if (!_isConnected) return;

    _connection?.send({
      'type': 'cancel_task',
      'payload': {'agentId': agentId},
    });
  }

  /// Reset an agent
  Future<void> resetAgent(String agentId) async {
    if (!_isConnected) return;

    _connection?.send({
      'type': 'reset_agent',
      'payload': {'agentId': agentId},
    });
  }

  /// Start a new task for an agent
  Future<void> startTask(String agentId, String taskDescription) async {
    if (!_isConnected) return;

    _connection?.send({
      'type': 'start_task',
      'payload': {
        'agentId': agentId,
        'task': taskDescription,
      },
    });
  }

  /// Load mock data for development
  Future<void> _loadMockData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    _agents = [
      AgentSession(
        id: 'main-agent',
        name: 'Marvis',
        role: 'main',
        status: AgentStatus.live,
        currentTask: 'Heartbeat + Chat',
        progress: 0.8,
        steps: ['Processing messages', 'Monitoring system'],
        lastActive: DateTime.now().subtract(const Duration(seconds: 30)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AgentSession(
        id: 'coding-agent',
        name: 'Cody',
        role: 'coding',
        status: AgentStatus.busy,
        currentTask: 'ClawChat Development',
        progress: 0.95,
        steps: ['Implementing AgentCard', 'Adding animations', 'Testing UI'],
        lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AgentSession(
        id: 'research-agent',
        name: 'Deep Search',
        role: 'research',
        status: AgentStatus.idle,
        currentTask: 'Ready to work',
        progress: 0.0,
        steps: [],
        lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AgentSession(
        id: 'autotask-agent',
        name: 'AutoTask',
        role: 'autotask',
        status: AgentStatus.live,
        currentTask: 'Daily research + updates',
        progress: 0.5,
        steps: ['Checking emails', 'Updating calendar', 'Sending reports'],
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];

    _agentUpdateController.add(_agents);
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _agentUpdateController.close();
    super.dispose();
  }
}

/// Mock WebSocket connection for development
/// In production, this would be replaced with a real WebSocket implementation
class WebSocketConnection {
  final String url;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function()? onDisconnect;
  final void Function()? onConnect;

  WebSocketConnection({
    required this.url,
    required this.onMessage,
    this.onDisconnect,
    this.onConnect,
  });

  void connect() {
    // Mock connection
    onConnect?.call();
  }

  void send(Map<String, dynamic> data) {
    // Mock send - just log
    debugPrint('[WebSocket] Sending: $data');
  }

  void disconnect() {
    onDisconnect?.call();
  }
}