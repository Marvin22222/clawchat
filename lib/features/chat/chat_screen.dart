import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/empty_state.dart';
import '../../core/constants/typography.dart';
import '../../core/services/websocket_service.dart';
import '../../core/services/chat_persistence_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/chat_export_service.dart';
import '../../core/services/image_compression_service.dart';
import '../../core/services/error_handler_service.dart';
import '../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agent_presets_provider.dart';
import '../../models/message.dart';
import '../../widgets/animations/chat_message_animation.dart';
import '../../widgets/animations/skeleton_loaders.dart';
import 'widgets/chat_widgets.dart' hide ThinkingIndicator, ToolCallCard;
import 'widgets/thinking_indicator.dart';
import 'widgets/tool_execution_card.dart';
import 'widgets/agent_typing_indicator.dart';
import 'providers/lazy_notification_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? initialAgent;

  const ChatScreen({super.key, this.initialAgent});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _hapticsTriggeredForMessages = {};
  bool _isTyping = false;
  bool _isStreaming = false;
  bool _showScrollToBottom = false;
  String _currentAgent = 'main';
  bool _isAppInForeground = true;
  bool _isRefreshing = false;
  
  // Lazy loading state
  bool _isLoadingOlder = false;
  bool _hasMoreOlderMessages = true;
  static const int _messagesPerPage = 50;
  
  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<int> _searchResults = [];

  // Reply state
  ChatMessage? _replyToMessage;
  
  // Export state
  bool _isExportingPdf = false;

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
    
    // Lazy loading: detect scroll near top
    if (_scrollController.position.pixels <= 200 && !_isLoadingOlder && _hasMoreOlderMessages) {
      _loadOlderMessages();
    }
  }

  bool _isAtBottom() {
    return _scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100;
  }

  void _scrollToBottom({bool smooth = true}) {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (smooth) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  /// Auto-scroll to bottom only if user is already at bottom (reading history)
  void _scrollToBottomIfAtBottom() {
    if (_isAtBottom()) {
      _scrollToBottom();
    }
  }

  Future<void> _loadSavedMessages() async {
    final savedMessages = await ChatPersistenceService.loadMessages();
    if (mounted && savedMessages.isNotEmpty) {
      setState(() {
        _messages.addAll(savedMessages);
      });
      // Check if there are more messages available
      if (savedMessages.length >= _messagesPerPage) {
        final oldestMessage = savedMessages.first;
        _hasMoreOlderMessages = await ChatPersistenceService.hasOlderMessages(oldestMessage.timestamp);
      } else {
        _hasMoreOlderMessages = false;
      }
    }
  }
  
  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlderMessages || _messages.isEmpty) return;
    
    setState(() => _isLoadingOlder = true);
    
    // Get the oldest message's timestamp as the anchor point
    final oldestMessage = _messages.first;
    final olderMessages = await ChatPersistenceService.loadOlderMessages(
      beforeTimestamp: oldestMessage.timestamp,
      limit: _messagesPerPage,
    );
    
    if (mounted) {
      setState(() {
        if (olderMessages.isNotEmpty) {
          // Insert older messages at the beginning (maintaining chronological order)
          _messages.insertAll(0, olderMessages);
          _hasMoreOlderMessages = olderMessages.length >= _messagesPerPage;
        } else {
          _hasMoreOlderMessages = false;
        }
        _isLoadingOlder = false;
      });
      
      // Keep scroll position after loading older messages
      if (olderMessages.isNotEmpty && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // Calculate scroll offset to maintain current view position
            final estimatedItemHeight = 80.0;
            final offset = olderMessages.length * estimatedItemHeight;
            _scrollController.jumpTo(
              (_scrollController.position.pixels + offset).clamp(0.0, _scrollController.position.maxScrollExtent),
            );
          }
        });
      }
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


  Future<void> _refresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    final auth = context.read<AuthProvider>();
    
    // Reconnect WebSocket if disconnected
    if (!auth.ws.isConnected) {
      await auth.reconnect();
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Reload saved messages
    final savedMessages = await ChatPersistenceService.loadMessages();
    
    if (mounted) {
      setState(() {
        _messages.clear();
        if (savedMessages.isNotEmpty) {
          _messages.addAll(savedMessages);
        }
        _isRefreshing = false;
      });
      
      // Scroll to bottom after refresh
      _scrollToBottom();
      
      // Haptic feedback
      HapticService.lightImpact();
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
          _isStreaming = true;
        });
        _scrollToBottomIfAtBottom();
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
        _scrollToBottomIfAtBottom();
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
          _isStreaming = false;
        });
        
        // Show notification for incoming message if app is in background
        if (finalContent != null && finalContent.isNotEmpty) {
          _showIncomingMessageNotification(finalContent, agentName ?? 'main');
        }
        
        _scrollToBottomIfAtBottom();
      }
    };

    auth.ws.onThinking = (thinking) {
      if (mounted) {
        setState(() {
          // Only show thinking if we're not streaming
          if (!_isStreaming) {
            _isTyping = true;
          }
        });
      }
    };
    
    // Error callback - show error snackbar when WebSocket has an error
    auth.ws.onError = (error) {
      if (mounted) {
        ErrorHandlerService.showParsedError(
          context,
          error,
          onRetry: () => auth.reconnect(),
        );
      }
    };
    
    // Connected callback - show success message (optional, can be noisy)
    auth.ws.onConnected = () {
      if (mounted) {
        // Only show if there are messages (toast might be annoying on initial connect)
        if (_messages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Erneut verbunden'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    };
    
    // Disconnected callback - show warning if there are messages
    auth.ws.onDisconnected = () {
      if (mounted && _messages.isNotEmpty && _currentStreamingMessageId == null) {
        ErrorHandlerService.showNetworkError(
          context,
          customMessage: 'Verbindung verloren',
          onRetry: () => auth.reconnect(),
        );
      }
    };
  }

  /// Show notification for incoming message when app is in background
  void _showIncomingMessageNotification(String content, String agentName) {
    // Lazy access notification service - only initialized when actually needed
    final notif = context.read<LazyNotificationProvider>();
    if (!_isAppInForeground && notif.isInitialized) {
      final sender = agentName == 'main' ? 'Assistant' : agentName;
      notif.showMessageNotification(
        sender: sender,
        message: content,
      );
    }
  }

  void _sendMessage(String text, {List<MessageAttachment>? attachments, String? retryId}) {
    final auth = context.read<AuthProvider>();
    final messageId = retryId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Capture reply state before clearing
    final replyTo = _replyToMessage;
    
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
        replyToId: replyTo?.id,
        replyToContent: replyTo?.content,
      );
      
      if (existingIndex >= 0) {
        _messages[existingIndex] = newMessage;
      } else {
        _messages.add(newMessage);
      }
      _isTyping = true;
      // Clear reply state after sending
      _replyToMessage = null;
    });

    // Haptic feedback on message send
    HapticService.onMessageSent();
    // Haptic when message bubble appears (only first time, not on retry)
    if (!_hapticsTriggeredForMessages.contains(messageId)) {
      _hapticsTriggeredForMessages.add(messageId);
      // Delay slightly so user sees the bubble appear first
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) HapticService.lightImpact();
      });
    }

    // Send with attachments and reply info via WebSocket
    auth.ws.sendMessage(
      text,
      agent: _currentAgent,
      attachments: attachments?.map((a) => {
        'path': a.path,
        'fileName': a.fileName,
        'mimeType': a.mimeType,
      }).toList(),
      replyToId: replyTo?.id,
      replyToContent: replyTo?.content,
    ).then((_) {
      // Success - update status
      _updateMessageStatus(messageId, MessageStatus.sent);
      // Persist messages after successful send
      ChatPersistenceService.saveMessages(_messages);
    }).catchError((error) {
      // Error - mark as error and allow retry
      _updateMessageStatus(messageId, MessageStatus.error);
      // Show error snackbar to user
      ErrorHandlerService.showParsedError(context, error, onRetry: () => _retryMessage(messageId));
    });
    
    _scrollToBottomIfAtBottom();
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

  void _editMessage(String messageId) async {
    // Find the message to edit
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex < 0) return;

    final message = _messages[messageIndex];
    if (message.type != MessageType.user) return;

    final editController = TextEditingController(text: message.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLoading = false;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
            title: Text(
              'Nachricht bearbeiten',
              style: AppTypography.h5.copyWith(color: isDark ? AppColors.textDark : AppColors.textLight),
            ),
            content: TextField(
              controller: editController,
              maxLines: 5,
              autofocus: true,
              enabled: !isLoading,
              style: AppTypography.body.copyWith(color: isDark ? AppColors.textDark : AppColors.textLight),
              decoration: InputDecoration(
                hintText: 'Nachricht eingeben...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                filled: true,
                fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
              ),
            ),
            actions: [
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  'Abbrechen',
                  style: AppTypography.button.copyWith(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final newText = editController.text.trim();
                  if (newText.isEmpty || newText == message.content) {
                    Navigator.pop(dialogContext);
                    return;
                  }

                  setDialogState(() => isLoading = true);

                  // Call API to update message
                  final auth = context.read<AuthProvider>();
                  final updatedMessage = await auth.api.editMessage(
                    messageId: messageId,
                    newContent: newText,
                  );

                  if (!mounted) return;

                  if (updatedMessage != null) {
                    // Update with server response
                    setState(() {
                      _messages[messageIndex] = updatedMessage;
                    });
                    ChatPersistenceService.saveMessages(_messages);
                    HapticService.mediumImpact();
                  } else {
                    // Fallback to local update if API fails
                    setState(() {
                      _messages[messageIndex] = message.copyWith(
                        content: newText,
                        isEdited: true,
                      );
                    });
                    ChatPersistenceService.saveMessages(_messages);
                    HapticService.lightImpact();
                    // Show error snackbar
                    ScaffoldMessenger.of(this).showSnackBar(
                      SnackBar(
                        content: Text('Nachricht lokal gespeichert (Server-Fehler)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }

                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Speichern',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    // Find the message index
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex < 0) return;

    final message = _messages[messageIndex];
    if (message.type != MessageType.user) return;

    // Store for undo
    final deletedMessage = message;

    // Remove from local list immediately
    setState(() {
      _messages.removeAt(messageIndex);
    });

    // Persist updated list
    ChatPersistenceService.saveMessages(_messages);

    // Show undo snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Nachricht gelöscht'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            // Restore the message
            setState(() {
              _messages.insert(messageIndex, deletedMessage);
            });
            ChatPersistenceService.saveMessages(_messages);
          },
        ),
      ),
    );

    // Call API to delete on server (fire and forget)
    final auth = context.read<AuthProvider>();
    auth.api.deleteMessage(messageId).then((success) {
      if (!success) {
        AppLogger.error('Failed to delete message on server: $messageId', tag: 'CHAT');
      }
    });
  }

  void _onImageSelected(String filePath) async {
    // Show compressing indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.textDark 
                  : AppColors.textLight,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Komprimiere Bild...'),
          ],
        ),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Compress image before upload
    final result = await ImageCompressionService.compress(filePath);
    
    // Hide snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    
    if (result != null && mounted) {
      // Show size reduction info
      if (result.compressionRatio < 1.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.formattedOriginal} → ${result.formattedCompressed}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      // Create attachment from compressed file
      final fileName = result.compressedFile.path.split('/').last;
      final attachment = MessageAttachment(
        path: result.compressedFile.path,
        fileName: fileName,
        mimeType: 'image/jpeg',
      );
      _sendMessage('[Bild]', attachments: [attachment]);
    } else {
      // Fallback to original if compression failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bild zu groß - komprimiere automatisch'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        final fileName = filePath.split('/').last;
        final attachment = MessageAttachment(
          path: filePath,
          fileName: fileName,
          mimeType: 'image/jpeg',
        );
        _sendMessage('[Bild]', attachments: [attachment]);
      }
    }
  }

  void _addReaction(String messageId, String emoji) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index >= 0) {
        final msg = _messages[index];
        final currentReactions = Map<String, int>.from(msg.reactions ?? {});
        if (currentReactions.containsKey(emoji)) {
          // Toggle off if already reacted
          final count = currentReactions[emoji]!;
          if (count > 1) {
            currentReactions[emoji] = count - 1;
          } else {
            currentReactions.remove(emoji);
          }
        } else {
          // Add reaction
          currentReactions[emoji] = 1;
        }
        _messages[index] = msg.copyWith(reactions: currentReactions.isEmpty ? null : currentReactions);
      }
    });
    ChatPersistenceService.saveMessages(_messages);
    HapticService.mediumImpact();
  }

  void _setReplyTo(ChatMessage message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _clearReplyTo() {
    setState(() {
      _replyToMessage = null;
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= AppDimensions.tabletBreakpoint;

    return Scaffold(
      appBar: _isSearching ? AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_1),
          onPressed: _cancelSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nachrichten durchsuchen...',
            border: InputBorder.none,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.close_square),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ) : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentAgent),
            if (auth.ws.isConnected)
              Text(
                'Online',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.cloud_download),
            onPressed: () => _showExportSheet(context),
            tooltip: 'Chat exportieren',
          ),
          IconButton(
            icon: const Icon(Iconsax.search_normal_1),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Iconsax.robot_outlined),
            onPressed: () {
              // Show agent picker
              _showAgentPicker(context, auth);
            },
          ),
        ],
      ),
      body: isDesktop 
          ? _buildDesktopChatLayout(context, isDark, auth)
          : _buildMobileChatLayout(context, isDark, auth),
    );
  }

  Widget _buildDesktopChatLayout(BuildContext context, bool isDark, AuthProvider auth) {
    return Row(
      children: [
        // Chat list sidebar
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
            border: Border(
              right: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            children: [
              // Sidebar header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Iconsax.messages_3, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Agent list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: auth.ws.availableAgents.length,
                  itemBuilder: (context, index) {
                    final agent = auth.ws.availableAgents[index];
                    final isSelected = agent == _currentAgent;
                    return _DesktopAgentListItem(
                      agent: agent,
                      isSelected: isSelected,
                      onTap: () => setState(() => _currentAgent = agent),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Main chat content
        Expanded(
          child: Column(
            children: [
              _buildConnectionStatusBar(
                isConnected: auth.ws.isConnected,
                status: auth.ws.status,
                isDark: isDark,
              ),
              if (!auth.ws.isConnected && _messages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.error.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Iconsax.wifi_slash, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Nicht verbunden.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => auth.reconnect(),
                        child: const Text('Erneut'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(isDark, auth.ws.isConnected)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 200,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _messages.length + (_isLoadingOlder ? 1 : 0) + (_isTyping || _isStreaming ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoadingOlder && index == 0) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text('Loading...', style: AppTypography.label.copyWith(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
                                  ],
                                ),
                              ),
                            );
                          }
                          final messageIndex = _isLoadingOlder ? index - 1 : index;
                          if (_isTyping || _isStreaming) {
                            final typingIndex = _messages.length + (_isLoadingOlder ? 1 : 0);
                            if (index == typingIndex) {
                              return _buildDesktopTypingIndicator(isDark);
                            }
                          }
                          return _buildMessageItem(context, _messages[messageIndex], isDark, auth);
                        },
                      ),
              ),
              _buildMessageInput(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(),
                const SizedBox(width: 4),
                _TypingDot(delay: 0.2),
                const SizedBox(width: 4),
                _TypingDot(delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage msg, bool isDark, AuthProvider auth) {
    final showDateHeader = _messages.indexOf(msg) == 0 ||
        !_isSameDay(msg.timestamp, _messages[_messages.indexOf(msg) - 1].timestamp);
    
    return Column(
      children: [
        if (showDateHeader)
          _DateSeparator(timestamp: msg.timestamp, isDark: isDark),
        if (msg.type == MessageType.toolCall && msg.toolData != null)
          ToolExecutionCard(
            toolName: msg.toolData!['tool'] ?? 'Unknown',
            toolDescription: msg.toolData!['description'],
            status: _getToolStatus(msg.toolData!['status'] ?? 'running'),
            parameters: msg.toolData!['parameters'],
            result: msg.toolData!['response']?.toString(),
          )
        else
          AnimatedMessageBubble(
            key: ValueKey(msg.id),
            animate: true,
            child: MessageBubble(
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
              onDelete: msg.type == MessageType.user ? () => _deleteMessage(msg.id) : null,
              messageId: msg.id,
              onReact: (emoji) => _addReaction(msg.id, emoji),
              onReply: () => _setReplyTo(msg),
              replyToContent: msg.replyToContent,
              isFirstInGroup: _isFirstInGroup(_messages.indexOf(msg)),
              isLastInGroup: _isLastInGroup(_messages.indexOf(msg)),
              isSameSenderAsPrevious: _isSameSenderAsPrevious(_messages.indexOf(msg)),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileChatLayout(BuildContext context, bool isDark, AuthProvider auth) {
    return Column(
      children: [
        if (!auth.ws.isConnected && _messages.isNotEmpty)
          OfflineBanner(onRetry: () => auth.reconnect()),
        _buildConnectionStatusBar(
          isConnected: auth.ws.isConnected,
          status: auth.ws.status,
          isDark: isDark,
        ),
        if (!auth.ws.isConnected && _messages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.error.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Iconsax.wifi_slash, color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Nicht verbunden. Nachricht senden fehlgeschlagen.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => auth.reconnect(),
                  child: const Text('Erneut'),
                ),
              ],
            ),
          ),
        if (_isSearching && _searchQuery.isNotEmpty)
          Expanded(
            child: Container(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              child: _buildSearchResultsList(isDark),
            ),
          )
        else
          Expanded(
            child: Stack(
              children: [
                _messages.isEmpty
                    ? _buildEmptyState(isDark, auth.ws.isConnected)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        displacement: 50,
                        backgroundColor: isDark ? AppColors.bgDarkSecondary : Colors.white,
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          cacheExtent: 200,
                          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                          itemCount: _messages.length + (_isLoadingOlder ? 1 : 0) + (_isTyping || _isStreaming ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoadingOlder && index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Loading older messages...',
                                        style: AppTypography.label.copyWith(
                                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final messageIndex = _isLoadingOlder ? index - 1 : index;
                            if (_isTyping || _isStreaming) {
                              final typingIndex = _messages.length + (_isLoadingOlder ? 1 : 0);
                              if (index == typingIndex) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      AgentTypingIndicator(),
                                    ],
                                  ),
                                );
                              }
                              if (index > typingIndex) {
                                final adjustedIndex = messageIndex - 1;
                                return _buildMessageBubble(_messages[adjustedIndex], isDark, auth, _scrollController);
                              }
                            }
                            return _buildMessageBubble(_messages[messageIndex], isDark, auth, _scrollController);
                          },
                        ),
                      ),
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: Material(
                      color: isDark ? AppColors.bgDarkSecondary : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      elevation: 4,
                      child: InkWell(
                        onTap: _scrollToBottom,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            Iconsax.arrow_down,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        _buildMessageInput(isDark),
      ],
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return ChatInput(
      onSend: _sendMessage,
      onImageSelected: _onImageSelected,
      enabled: context.watch<AuthProvider>().ws.isConnected,
      replyTo: _replyToMessage != null ? {'id': _replyToMessage!.id, 'content': _replyToMessage!.content.length > 50 ? '${_replyToMessage!.content.substring(0, 50)}...' : _replyToMessage!.content} : null,
      onCancelReply: _replyToMessage != null ? _clearReplyTo : null,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if message at index is the first in a group of consecutive messages from the same sender
  bool _isFirstInGroup(int index) {
    if (index == 0) return true;
    final currentMsg = _messages[index];
    final prevMsg = _messages[index - 1];
    // First if previous message is from different sender
    if (currentMsg.type != prevMsg.type) return true;
    if (currentMsg.type == MessageType.user) return true; // User is always "first" since no consecutive user messages in normal flow
    // For assistant, check agent name
    return currentMsg.agentName != prevMsg.agentName;
  }

  /// Check if message at index is the last in a group of consecutive messages from the same sender
  bool _isLastInGroup(int index) {
    if (index == _messages.length - 1) return true;
    final currentMsg = _messages[index];
    final nextMsg = _messages[index + 1];
    // Last if next message is from different sender
    if (currentMsg.type != nextMsg.type) return true;
    if (currentMsg.type == MessageType.user) return true; // User is always "last"
    // For assistant, check agent name
    return currentMsg.agentName != nextMsg.agentName;
  }

  /// Check if message at index is from the same sender as the previous message
  bool _isSameSenderAsPrevious(int index) {
    if (index == 0) return false;
    final currentMsg = _messages[index];
    final prevMsg = _messages[index - 1];
    // User messages are never consecutive in normal chat (user sends one, then waits)
    if (currentMsg.type == MessageType.user || prevMsg.type == MessageType.user) return false;
    // Both are assistant - check agent name
    return currentMsg.agentName == prevMsg.agentName;
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
        icon = Iconsax.tick_square_circle;
        text = 'Connected';
        break;
      case ConnectionStatus.connecting:
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Iconsax.sync;
        text = 'Connecting...';
        break;
      case ConnectionStatus.error:
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        icon = Iconsax.warning_2_outline;
        text = 'Connection error';
        break;
      case ConnectionStatus.disconnected:
      default:
        bgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
        textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        icon = Iconsax.wifi_slash;
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
            style: AppTypography.label.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  // ========== SEARCH FUNCTIONALITY ==========
  
  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _cancelSearch();
      } else {
        _isSearching = true;
        _searchFocusNode.requestFocus();
      }
    });
  }
  
  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _searchResults = [];
        } else {
          _searchResults = [];
          final lowerQuery = query.toLowerCase();
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].content.toLowerCase().contains(lowerQuery)) {
              _searchResults.add(i);
            }
          }
        }
      });
    });
  }
  
  void _scrollToIndex(int index) {
    // Calculate approximate scroll position based on message index
    // Each message takes roughly 80 pixels (avatar + padding + text)
    final offset = index * 80.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
  
  Widget _buildSearchResultsList(bool isDark) {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Text(
          'Tippe um zu suchen',
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal_1_off,
              size: 48,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keine Ergebnisse gefunden',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match count header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            '${_searchResults.length} Treffer für "$_searchQuery"',
            style: AppTypography.label.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final msgIndex = _searchResults[index];
              final msg = _messages[msgIndex];
              return _SearchResultItem(
                message: msg,
                query: _searchQuery,
                isDark: isDark,
                onTap: () {
                  _cancelSearch();
                  _scrollToIndex(msgIndex);
                },
              );
            },
          ),
        ),
      ],
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
              style: AppTypography.caption.copyWith(
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
    if (isConnected) {
      return BetterEmptyState(
        icon: Iconsax.arrow_up_2,
        title: 'Starte ein Gespräch mit deinem Agent!',
        subtitle: 'Schreib eine Nachricht oder nutze Voice/Image',
        isDark: isDark,
        animationType: BetterEmptyStateAnimationType.pulse,
      );
    }
    return BetterEmptyState(
      icon: Iconsax.wifi_slash,
      title: 'Nicht verbunden',
      subtitle: 'Verbinde dich mit dem Gateway',
      isDark: isDark,
      animationType: BetterEmptyStateAnimationType.fade,
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
            style: AppTypography.label.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAgentPicker(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presetsProvider = context.read<AgentPresetsProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Agent auswählen',
                      style: AppTypography.h5.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    if (presetsProvider.presets.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPresetPicker(context, auth, presetsProvider);
                        },
                        icon: const Icon(Iconsax.bookmark, size: 18),
                        label: const Text('Presets'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Agent list
              Flexible(
                child: auth.ws.availableAgents.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Keine Agents verfügbar',
                          style: AppTypography.body.copyWith(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        shrinkWrap: true,
                        itemCount: auth.ws.availableAgents.length,
                        itemBuilder: (context, index) {
                          final agent = auth.ws.availableAgents[index];
                          return ListTile(
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
                              style: AppTypography.body.copyWith(
                                fontWeight: agent == _currentAgent ? FontWeight.bold : FontWeight.normal,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                            ),
                            trailing: agent == _currentAgent
                                ? Icon(Iconsax.tick_square, color: AppColors.primary)
                                : null,
                            selected: agent == _currentAgent,
                            onTap: () {
                              setState(() => _currentAgent = agent);
                              auth.ws.switchAgent(agent);
                              presetsProvider.clearActivePreset();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
              // Presets hint
              if (presetsProvider.presets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    '${presetsProvider.presets.length} Preset(s) verfügbar - tippe auf "Presets" für mehr',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetPicker(BuildContext context, AuthProvider auth, AgentPresetsProvider presetsProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Presets',
                      style: AppTypography.h5.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAgentPicker(context, auth);
                      },
                      icon: const Icon(Iconsax.arrow_left_1, size: 18),
                      label: const Text('Agents'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Presets list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: presetsProvider.presets.length,
                  itemBuilder: (context, index) {
                    final preset = presetsProvider.presets[index];
                    final modelType = presetsProvider.getPresetModelType(preset);
                    final isActive = presetsProvider.activePresetId == preset.id;
                    final isCurrentAgent = _currentAgent == preset.agentId;
                    
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                              : null,
                          color: isActive ? null : AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Icon(
                          Iconsax.bookmark,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        preset.name,
                        style: AppTypography.body.copyWith(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${preset.agentId} • ${modelType.displayName}',
                            style: AppTypography.label.copyWith(
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          if (preset.systemPrompt != null && preset.systemPrompt!.isNotEmpty)
                            Text(
                              preset.systemPrompt!.length > 40 
                                  ? '${preset.systemPrompt!.substring(0, 40)}...' 
                                  : preset.systemPrompt!,
                              style: AppTypography.captionSmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                        ],
                      ),
                      trailing: isActive
                          ? Icon(Iconsax.tick_square_circle, color: AppColors.success)
                          : (!isCurrentAgent 
                              ? Chip(
                                  label: Text(
                                    preset.agentId,
                                    style: AppTypography.captionSmall,
                                  ),
                                  backgroundColor: AppColors.warning.withOpacity(0.2),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null),
                      onTap: () {
                        // Switch agent
                        setState(() => _currentAgent = preset.agentId);
                        auth.ws.switchAgent(preset.agentId);
                        
                        // Apply preset system prompt if present
                        if (preset.systemPrompt != null && preset.systemPrompt!.isNotEmpty) {
                          auth.ws.setSystemPrompt(preset.systemPrompt!);
                        } else {
                          auth.ws.clearSystemPrompt();
                        }
                        
                        // Set active preset
                        presetsProvider.setActivePreset(preset.id);
                        

                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              // Clear preset option
              if (presetsProvider.activePresetId != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        auth.ws.clearSystemPrompt();
                        presetsProvider.clearActivePreset();
                        Navigator.pop(context);
                      },
                      child: const Text('Preset zurücksetzen'),
                    ),
                  ),
                ),
            ],
          ),
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
                      prefixIcon: const Icon(Iconsax.search_normal_1),
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
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
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
                                  msg.type == MessageType.user ? Iconsax.user : Iconsax.robot,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                msg.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                ),
                              ),
                              subtitle: Text(
                                _formatMessageTime(msg.timestamp),
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
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

// Search result item with highlighted text
class _SearchResultItem extends StatelessWidget {
  final ChatMessage message;
  final String query;
  final bool isDark;
  final VoidCallback onTap;
  
  const _SearchResultItem({
    required this.message,
    required this.query,
    required this.isDark,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: message.type == MessageType.user 
                  ? AppColors.primary 
                  : AppColors.secondary,
              radius: 16,
              child: Icon(
                message.type == MessageType.user ? Iconsax.user : Iconsax.robot,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message preview with highlighted match
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                      children: _buildHighlightedText(message.content, query),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Navigate icon
            Icon(
              Iconsax.chevron_right,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }
      
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: AppColors.primary.withOpacity(0.3),
          fontWeight: FontWeight.w600,
        ),
      ));
      
      start = index + query.length;
    }
    
    return spans;
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
          child: Icon(Iconsax.sync, size: 16, color: widget.color),
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
                style: AppTypography.h5.copyWith(
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
                  child: const Icon(Iconsax.code, color: AppColors.primary),
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
                  child: const Icon(Iconsax.text_block, color: AppColors.secondary),
                ),
                title: const Text('Als Text'),
                subtitle: const Text('Lesbare Formatierung'),
                onTap: () {
                  Navigator.pop(context);
                  final text = ChatPersistenceService.exportAsText(_messages);
                  _shareExport('Chat als Text exportiert', text, 'clawchat_export.txt');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Iconsax.paperclip, color: AppColors.error),
                ),
                title: const Text('Als PDF'),
                subtitle: const Text('Druckfertiges Format'),
                onTap: () {
                  Navigator.pop(context);
                  _exportPdf();
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
                  const Icon(Iconsax.tick_square_circle, color: Colors.white, size: 20),
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

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    
    try {
      final pdfBytes = await ChatExportService.exportAsPdf(_messages);
      await ChatExportService.sharePdf(pdfBytes, 'clawchat_export.pdf');
      HapticService.mediumImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF Export erfolgreich'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('PDF export failed: $e', tag: 'EXPORT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.warning_2, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('PDF Export fehlgeschlagen'),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }
}
// Desktop helper widgets

class _TypingDot extends StatefulWidget {
  final double delay;

  const _TypingDot({this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                .withOpacity(0.5 + (_animation.value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _DesktopAgentListItem extends StatefulWidget {
  final String agent;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopAgentListItem({
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DesktopAgentListItem> createState() => _DesktopAgentListItemState();
}

class _DesktopAgentListItemState extends State<_DesktopAgentListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primary.withOpacity(0.15)
              : (_isHovered ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)) : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: widget.isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: widget.isSelected ? AppColors.primary : AppColors.secondary,
                    child: Text(
                      widget.agent[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.agent,
                          style: TextStyle(
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: widget.isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.textDark : AppColors.textLight),
                          ),
                        ),
                        if (widget.isSelected)
                          Text(
                            'Aktiv',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isSelected)
                    Icon(
                      Iconsax.check,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
