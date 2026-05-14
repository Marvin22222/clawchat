import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/utils/logger.dart';
import '../models/task_model.dart';

enum TaskEventType {
  taskCreated,
  taskStarted,
  taskProgress,
  taskCompleted,
  taskFailed,
}

class TaskEvent {
  final TaskEventType type;
  final TaskModel task;

  TaskEvent({required this.type, required this.task});
}

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  TaskStatus? _filterStatus;
  bool _isLoading = false;
  String? _error;
  
  WebSocketChannel? _channel;
  String? _gatewayUrl;
  String? _token;
  
  // Callback für Task Events
  final List<void Function(TaskEvent)> _listeners = [];

  List<TaskModel> get tasks {
    if (_filterStatus == null) return _tasks;
    return _tasks.where((t) => t.status == _filterStatus).toList();
  }
  
  List<TaskModel> get allTasks => _tasks;
  TaskStatus? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get runningCount => _tasks.where((t) => t.status == TaskStatus.running).length;
  int get completedCount => _tasks.where((t) => t.status == TaskStatus.completed).length;
  int get failedCount => _tasks.where((t) => t.status == TaskStatus.failed).length;
  int get pendingCount => _tasks.where((t) => t.status == TaskStatus.pending).length;

  void setFilter(TaskStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> connect(String gatewayUrl, String token) async {
    _gatewayUrl = gatewayUrl;
    _token = token;
    
    try {
      String wsUrl;
      if (gatewayUrl.startsWith('http://')) {
        wsUrl = gatewayUrl.replaceFirst('http://', 'ws://');
      } else if (gatewayUrl.startsWith('https://')) {
        wsUrl = gatewayUrl.replaceFirst('https://', 'wss://');
      } else {
        wsUrl = 'wss://$gatewayUrl';
      }
      
      if (!wsUrl.contains('?')) {
        wsUrl += '?token=$token';
      } else {
        wsUrl += '&token=$token';
      }
      wsUrl += '&type=tasks';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String);
      final type = message['type'] as String;
      
      switch (type) {
        case 'task_created':
          final task = TaskModel.fromJson(message['task']);
          _tasks.insert(0, task);
          notifyListeners();
          break;
          
        case 'task_started':
          _updateTask(message['task_id'], TaskStatus.running);
          break;
          
        case 'task_progress':
          // Progress updates können hier verarbeitet werden
          break;
          
        case 'task_completed':
          _updateTask(
            message['task_id'], 
            TaskStatus.completed,
            completedAt: DateTime.now(),
          );
          break;
          
        case 'task_failed':
          _updateTask(
            message['task_id'], 
            TaskStatus.failed,
            errorMessage: message['error'],
          );
          break;
          
        case 'tasks_list':
          _tasks = (message['tasks'] as List)
              .map((t) => TaskModel.fromJson(t))
              .toList();
          break;
      }
      
      notifyListeners();
    } catch (e) {
      AppLogger.error('Task WebSocket error: $e', tag: 'TASK_PROVIDER');
    }
  }

  void _updateTask(
    String taskId, 
    TaskStatus status, {
    DateTime? completedAt,
    String? errorMessage,
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final oldTask = _tasks[index];
      final updatedTask = oldTask.copyWith(
        status: status,
        completedAt: completedAt,
        errorMessage: errorMessage,
      );
      _tasks[index] = updatedTask;
      
      TaskEventType eventType;
      switch (status) {
        case TaskStatus.running:
          eventType = TaskEventType.taskStarted;
          break;
        case TaskStatus.completed:
          eventType = TaskEventType.taskCompleted;
          break;
        case TaskStatus.failed:
          eventType = TaskEventType.taskFailed;
          break;
        default:
          eventType = TaskEventType.taskProgress;
      }
      
      notifyListeners();
    }
  }

  // Demo-Daten laden (falls kein WebSocket verfügbar)
  void loadDemoTasks() {
    _tasks = [
      TaskModel(
        id: '1',
        name: 'Trading News Bot',
        status: TaskStatus.completed,
        agent: 'trading-agent',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        cronExpression: '0 9 * * *',
      ),
      TaskModel(
        id: '2',
        name: 'AI News Daily',
        status: TaskStatus.completed,
        agent: 'news-agent',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        completedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        cronExpression: '30 8 * * *',
      ),
      TaskModel(
        id: '3',
        name: 'Market Analysis',
        status: TaskStatus.running,
        agent: 'analysis-agent',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        cronExpression: '0 */2 * * *',
      ),
      TaskModel(
        id: '4',
        name: 'Portfolio Sync',
        status: TaskStatus.pending,
        agent: 'portfolio-agent',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        cronExpression: '*/15 * * * *',
      ),
      TaskModel(
        id: '5',
        name: 'Backup Service',
        status: TaskStatus.failed,
        agent: 'backup-agent',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        errorMessage: 'Connection timeout after 30s',
      ),
    ];
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    _isLoading = false;
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
