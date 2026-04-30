import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/services/websocket_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import 'widgets/chat_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String? initialAgent;

  const ChatScreen({super.key, this.initialAgent});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _currentAgent = 'main';

  @override
  void initState() {
    super.initState();
    if (widget.initialAgent != null) {
      _currentAgent = widget.initialAgent!;
    }
    _setupWebSocket();
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
        title: Text(_currentAgent),
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
                        return ThinkingIndicator(isDark: isDark);
                      }
                      final msg = _messages[index];
                      
                      // Render ToolCallCard for tool call messages
                      if (msg.type == MessageType.toolCall && msg.toolData != null) {
                        return ToolCallCard(
                          toolName: msg.toolData!['tool'] ?? 'Unknown',
                          status: msg.toolData!['status'] ?? 'running',
                          progress: (msg.toolData!['progress'] ?? 0).toDouble(),
                          parameters: msg.toolData!['parameters'],
                          response: msg.toolData!['response'],
                          isDark: isDark,
                        );
                      }
                      
                      return MessageBubble(
                        content: msg.content,
                        isUser: msg.type == MessageType.user,
                        isDark: isDark,
                        agentName: msg.agentName,
                        timestamp: msg.timestamp,
                        attachments: msg.attachments,
                        status: msg.status,
                        onRetry: msg.status == MessageStatus.error ? () => _retryMessage(msg.id) : null,
                      );
                    },
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
          Icon(icon, size: 16, color: textColor),
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
          ],
        ),
      ),
    );
  }

  void _showAgentPicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent auswählen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ...auth.ws.availableAgents.map((agent) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  agent[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(agent),
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
