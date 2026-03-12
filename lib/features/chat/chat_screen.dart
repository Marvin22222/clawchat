import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
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

  void _sendMessage(String text) {
    final auth = context.read<AuthProvider>();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    // Send to WebSocket
    auth.ws.sendMessage(text, agent: _currentAgent);
    _scrollToBottom();
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
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return ThinkingIndicator(isDark: isDark);
                }
                return MessageBubble(
                  message: _messages[index],
                  isDark: isDark,
                );
              },
            ),
          ),
          
          // Input
          ChatInput(
            onSend: _sendMessage,
            enabled: auth.ws.isConnected,
          ),
        ],
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
