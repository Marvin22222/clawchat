import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/websocket_service.dart';
import '../../core/services/chat_persistence_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import 'widgets/chat_widgets.dart' hide ThinkingIndicator, ToolCallCard;
import 'widgets/thinking_indicator.dart';
import 'widgets/tool_execution_card.dart';

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
  bool _showScrollToBottom = false;
  String _currentAgent = 'main';
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _isAppInForeground = true;
    if (widget.initialAgent != null) {
      _currentAgent = widget.initialAgent!;
    }
    _loadSavedMessages();
    _setupWebSocket();
  }

  void _onScroll() {
    final atBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100;
    if (atBottom != !_showScrollToBottom) {
      setState(() => _showScrollToBottom = !atBottom);
    }
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
    
    _isAppInForeground = (state == AppLifecycleState.resumed);
    
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
    
    auth.ws.onStreamingStart = () {
      if (mounted) {
        setState(() {
          final msgId = DateTime.now().millisecondsSinceEpoch.toString();
          _currentStreamingMessageId = msgId;
          _messages.add(ChatMessage(
            id: msgId,
            content: '',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
            agentName: _currentAgent,
            isStreaming: true,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    };

    auth.ws.onMessage = (content) {
      if (mounted) {
        setState(() {
          if (_currentStreamingMessageId != null) {
            // Append to streaming message
            final idx = _messages.indexWhere((m) => m.id == _currentStreamingMessageId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(
                content: _messages[idx].content + content,
              );
            }
          } else if (_messages.isNotEmpty && _messages.last.type == MessageType.assistant) {
            // Fallback: append to last assistant message
            final lastMsg = _messages.last;
            _messages[_messages.length - 1] = lastMsg.copyWith(
              content: lastMsg.content + content,
            );
          } else {
            // Create new message if none exists
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              type: MessageType.assistant,
              timestamp: DateTime.now(),
              agentName: _currentAgent,
            ));
          }
        });
        _scrollToBottom();
      }
    };

    auth.ws.onStreamingEnd = () {
      if (mounted) {
        // Find the message that just finished streaming
        final streamingIndex = _messages.indexWhere((m) => m.isStreaming);
        String? finalContent;
        String? agentName;
        
        if (streamingIndex >= 0) {
          finalContent = _messages[streamingIndex].content;
          agentName = _messages[streamingIndex].agentName;
        }
        
        setState(() {
          if (_currentStreamingMessageId != null) {
            final idx = _messages.indexWhere((m) => m.id == _currentStreamingMessageId);
            if (idx >= 0) {
              _messages[idx] = _messages[idx].copyWith(isStreaming: false);
            }
          }
          _currentStreamingMessageId = null;
          _isTyping = false;
        });
        
        // Show notification for incoming message if app is in background
        if (finalContent != null && finalContent.isNotEmpty) {
          _showIncomingMessageNotification(finalContent, agentName ?? 'main');
        }
        
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

  /// Show notification for incoming message when app is in background
  void _showIncomingMessageNotification(String content, String agentName) {
    if (!_isAppInForeground && NotificationService().isInitialized) {
      final notif = NotificationService();
      // Parse sender from agent name or use default
      final sender = agentName == 'main' ? 'Assistant' : agentName;
      notif.showMessageNotification(
        sender: sender,
        message: content,
      );
    }
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

    // Haptic feedback on message send
    HapticService.onMessageSent();

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

  void _editMessage(String messageId) {
    // Find the message to edit
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex < 0) return;

    final message = _messages[messageIndex];
    if (message.type != MessageType.user) return;

    final editController = TextEditingController(text: message.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: Text(
          'Nachricht bearbeiten',
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
        ),
        content: TextField(
          controller: editController,
          maxLines: 5,
          autofocus: true,
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Nachricht eingeben...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            filled: true,
            fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.content) {
                setState(() {
                  _messages[messageIndex] = message.copyWith(
                    content: newText,
                    isEdited: true,
                  );
                });
                // Persist after edit
                ChatPersistenceService.saveMessages(_messages);
                HapticService.lightImpact();
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Speichern',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
            icon: const Icon(Icons.download),
            onPressed: () => _showExportSheet(context),
            tooltip: 'Chat exportieren',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
          ),
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
            child: Stack(
              children: [
                _messages.isEmpty
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
                            ToolExecutionCard(
                              toolName: msg.toolData!['tool'] ?? 'Unknown',
                              toolDescription: msg.toolData!['description'],
                              status: _getToolStatus(msg.toolData!['status'] ?? 'running'),
                              parameters: msg.toolData!['parameters'],
                              result: msg.toolData!['response']?.toString(),
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
                              isEdited: msg.isEdited,
                              isStreaming: msg.isStreaming,
                              onRetry: msg.status == MessageStatus.error ? () => _retryMessage(msg.id) : null,
                              onEdit: msg.type == MessageType.user ? () => _editMessage(msg.id) : null,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // Scroll to bottom FAB
            if (_showScrollToBottom)
              Positioned(
                bottom: 80,
                right: AppSpacing.md,
                child: FloatingActionButton.small(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                    HapticService.lightImpact();
                  },
                  backgroundColor: isDark ? AppColors.bgDarkTertiary : AppColors.primary,
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ),
              ),
          ],
        ),
        // Input
        ChatInput(
          onSend: _sendMessage,
          onImageSelected: _onImageSelected,
          enabled: auth.ws.isConnected,
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  ToolStatus _getToolStatus(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return ToolStatus.running;
      case 'completed':
      case 'success':
        return ToolStatus.completed;
      case 'error':
      case 'failed':
        return ToolStatus.error;
      default:
        return ToolStatus.running;
    }
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

  void _showSearchSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    List<int> searchResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Nachrichten durchsuchen...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (query) {
                      final results = <int>[];
                      if (query.isNotEmpty) {
                        for (int i = 0; i < _messages.length; i++) {
                          if (_messages[i].content.toLowerCase().contains(query.toLowerCase())) {
                            results.add(i);
                          }
                        }
                      }
                      setModalState(() => searchResults = results);
                    },
                  ),
                ),
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchController.text.isEmpty
                                ? 'Tippe um zu suchen'
                                : 'Keine Ergebnisse gefunden',
                            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final msgIndex = searchResults[index];
                            final msg = _messages[msgIndex];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: msg.type == MessageType.user ? AppColors.primary : AppColors.secondary,
                                radius: 16,
                                child: Icon(
                                  msg.type == MessageType.user ? Icons.person : Icons.smart_toy,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                msg.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
                              ),
                              subtitle: Text(
                                _formatMessageTime(msg.timestamp),
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                // Scroll to message
                                _scrollToIndex(msgIndex);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMessageTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inHours < 1) return 'Vor ${diff.inMinutes} Min';
    if (diff.inDays < 1) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays < 7) return 'Vor ${diff.inDays} Tagen';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  void _scrollToIndex(int index) {
    // Approximate scroll position
    final offset = index * 80.0;
    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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

  void _showExportSheet(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Chat exportieren',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Icons.code, color: AppColors.primary),
                ),
                title: const Text('Als JSON'),
                subtitle: const Text('Export für Backup oder Analyse'),
                onTap: () {
                  Navigator.pop(context);
                  final json = ChatPersistenceService.exportAsJson(_messages);
                  _shareExport('Chat als JSON exportiert', json, 'clawchat_export.json');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Icons.text_snippet, color: AppColors.secondary),
                ),
                title: const Text('Als Text'),
                subtitle: const Text('Lesbare Formatierung'),
                onTap: () {
                  Navigator.pop(context);
                  final text = ChatPersistenceService.exportAsText(_messages);
                  _shareExport('Chat als Text exportiert', text, 'clawchat_export.txt');
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  void _shareExport(String title, String content, String filename) {
    // Save to temporary file and share
    _exportAndShare(content, filename).then((success) {
      if (success) {
        HapticService.mediumImpact();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export fehlgeschlagen'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  Future<bool> _exportAndShare(String content, String filename) async {
    try {
      // Get temporary directory and write file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      
      // Share the file using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ClawChat Export',
        text: 'ClawChat Chat-Export',
      );
      return true;
    } catch (e) {
      AppLogger.error('Export failed: $e', tag: 'EXPORT');
      // Fallback to clipboard
      try {
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(Text('$filename wurde in die Zwischenablage kopiert')),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
