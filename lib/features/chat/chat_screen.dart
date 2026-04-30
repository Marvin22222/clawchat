import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/services/websocket_service.dart';
import '../../core/services/chat_persistence_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import 'widgets/chat_widgets.dart' hide ThinkingIndicator;
import 'widgets/thinking_indicator.dart';

class ChatScreen extends StatefulWidget {
  final String? initialAgent;

  const ChatScreen({super.key, this.initialAgent});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _currentAgent = 'main';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialAgent != null) {
      _currentAgent = widget.initialAgent!;
    }
    _loadSavedMessages();
    _setupWebSocket();
  }

  Future<void> _loadSavedMessages() async {
    final savedMessages = await ChatPersistenceService.loadMessages();
    if (mounted && savedMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(savedMessages);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final auth = context.read<AuthProvider>();
    
    if (state == AppLifecycleState.paused) {
      // App going to background - save messages and start auto-lock timer
      auth.startAutoLockTimer();
      ChatPersistenceService.saveMessages(_messages);
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - cancel auto-lock if not expired
      auth.cancelAutoLockTimer();
    }
  }

  void _setupWebSocket() {
    final auth = context.read<AuthProvider>();
    auth.ws.onMessage = (content) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last.type == MessageType.assistant) {
            // Create new message with appended content
            final lastMsg = _messages.last;
            _messages[_messages.length - 1] = lastMsg.copyWith(
              content: lastMsg.content + content,
            );
          } else {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              type: MessageType.assistant,
              timestamp: DateTime.now(),
              agentName: _currentAgent,
            ));
          }
          _isTyping = false;
        });
        _scrollToBottom();
      }
    };

    auth.ws.onThinking = (thinking) {
      if (mounted) {
        setState(() {
          _isTyping = true;
        });
      }
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, {List<MessageAttachment>? attachments, String? retryId}) {
    final auth = context.read<AuthProvider>();
    final messageId = retryId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Add user message (or update if retry)
    setState(() {
      final existingIndex = _messages.indexWhere((m) => m.id == messageId);
      final newMessage = ChatMessage(
        id: messageId,
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        attachments: attachments,
      );
      
      if (existingIndex >= 0) {
        _messages[existingIndex] = newMessage;
      } else {
        _messages.add(newMessage);
      }
      _isTyping = true;
    });

    // Send with attachments via WebSocket
    auth.ws.sendMessage(
      text,
      agent: _currentAgent,
      attachments: attachments?.map((a) => {
        'path': a.path,
        'fileName': a.fileName,
        'mimeType': a.mimeType,
      }).toList(),
    ).then((_) {
      // Success - update status
      _updateMessageStatus(messageId, MessageStatus.sent);
      // Persist messages after successful send
      ChatPersistenceService.saveMessages(_messages);
    }).catchError((error) {
      // Error - mark as error and allow retry
      _updateMessageStatus(messageId, MessageStatus.error);
    });
    
    _scrollToBottom();
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        _messages[index] = _messages[index].copyWith(status: status);
      }
    });
  }

  void _retryMessage(String messageId) {
    final message = _messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );
    _sendMessage(
      message.content,
      attachments: message.attachments,
      retryId: messageId,
    );
  }

  void _onImageSelected(String filePath) {
    // Create attachment from file path
    final fileName = filePath.split('/').last;
    final attachment = MessageAttachment(
      path: filePath,
      fileName: fileName,
      mimeType: 'image/jpeg',
    );
    _sendMessage('[Bild]', attachments: [attachment]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentAgent),
            if (auth.ws.isConnected)
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () {
              // Show agent picker
              _showAgentPicker(context, auth);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Bar
          _buildConnectionStatusBar(
            isConnected: auth.ws.isConnected,
            status: auth.ws.status,
            isDark: isDark,
          ),
          // Connection Error Banner
          if (!auth.ws.isConnected && _messages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              color: AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Nicht verbunden. Nachricht senden fehlgeschlagen.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => auth.reconnect(),
                    child: const Text('Erneut'),
                  ),
                ],
              ),
            ),
          
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark, auth.ws.isConnected)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: ThinkingIndicator(),
                        );
                      }
                      
                      final msg = _messages[index];
                      final showDateHeader = index == 0 ||
                          !_isSameDay(msg.timestamp, _messages[index - 1].timestamp);
                      
                      return Column(
                        children: [
                          if (showDateHeader)
                            _DateSeparator(timestamp: msg.timestamp, isDark: isDark),
                          // Render ToolCallCard for tool call messages
                          if (msg.type == MessageType.toolCall && msg.toolData != null)
                            ToolCallCard(
                              toolName: msg.toolData!['tool'] ?? 'Unknown',
                              status: msg.toolData!['status'] ?? 'running',
                              progress: (msg.toolData!['progress'] ?? 0).toDouble(),
                              parameters: msg.toolData!['parameters'],
                              response: msg.toolData!['response'],
                              isDark: isDark,
                            )
                          else
                            MessageBubble(
                              content: msg.content,
                              isUser: msg.type == MessageType.user,
                              isDark: isDark,
                              agentName: msg.agentName,
                              timestamp: msg.timestamp,
                              attachments: msg.attachments,
                              status: msg.status,
                              reactions: msg.reactions,
                              onRetry: msg.status == MessageStatus.error ? () => _retryMessage(msg.id) : null,
                            ),
                        ],
                      );
                  ),
          ),
          
          // Input
          ChatInput(
            onSend: _sendMessage,
            onImageSelected: _onImageSelected,
            enabled: auth.ws.isConnected,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildConnectionStatusBar({
    required bool isConnected,
    required ConnectionStatus status,
    required bool isDark,
  }) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case ConnectionStatus.connected:
        bgColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        icon = Icons.check_circle;
        text = 'Connected';
        break;
      case ConnectionStatus.connecting:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.sync;
        text = 'Connecting...';
        break;
      case ConnectionStatus.error:
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        icon = Icons.error_outline;
        text = 'Connection error';
        break;
      case ConnectionStatus.disconnected:
      default:
        bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
        textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        icon = Icons.wifi_off;
        text = 'Disconnected';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          status == ConnectionStatus.connecting ? _AnimatedSyncIcon(color: textColor) : Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _DateSeparator({required DateTime timestamp, required bool isDark}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    String text;
    if (messageDate == today) {
      text = 'Heute';
    } else if (messageDate == yesterday) {
      text = 'Gestern';
    } else {
      text = '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          Expanded(child: Divider(color: isDark ? Colors.grey[700] : Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isConnected) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.chat_bubble_outline : Icons.wifi_off,
              size: 64,
              color: isDark 
                  ? AppColors.textDarkSecondary 
                  : AppColors.textLightSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isConnected ? 'Keine Nachrichten' : 'Nicht verbunden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isConnected 
                  ? 'Starte eine Unterhaltung!' 
                  : 'Verbinde dich mit dem Gateway',
              style: TextStyle(
                color: isDark 
                    ? AppColors.textDarkSecondary 
                    : AppColors.textLightSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isConnected) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HintChip(icon: Icons.mic, label: 'Voice', isDark: isDark),
                  const SizedBox(width: AppSpacing.sm),
                  _HintChip(icon: Icons.attach_file, label: 'Image', isDark: isDark),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _HintChip({required IconData icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.primary : AppColors.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAgentPicker(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Agent auswählen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (auth.ws.availableAgents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Keine Agents verfügbar',
                  style: TextStyle(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              )
            else
              ...auth.ws.availableAgents.map((agent) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: agent == _currentAgent 
                      ? AppColors.primary 
                      : AppColors.primary.withOpacity(0.3),
                  child: Text(
                    agent[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  agent,
                  style: TextStyle(
                    fontWeight: agent == _currentAgent ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                trailing: agent == _currentAgent
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                selected: agent == _currentAgent,
                onTap: () {
                  setState(() => _currentAgent = agent);
                  auth.ws.switchAgent(agent);
                  Navigator.pop(context);
                },
              )),
          ],
        ),
      ),
    );
  }
}

// Animated sync icon for connection status
class _AnimatedSyncIcon extends StatefulWidget {
  final Color color;
  const _AnimatedSyncIcon({required this.color});
  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Icon(Icons.sync, size: 16, color: widget.color),
        );
      },
    );
  }
}
