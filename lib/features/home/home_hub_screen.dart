import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/typography.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/task_service.dart';
import '../../../models/session.dart';
import '../tasks/models/task_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/feedback/skeleton_loader.dart';
import '../chat_new/modern_chat_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({super.key});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedAgent = 'main';
  late SessionService _sessionService;
  late TaskService _taskService;
  List<Session> _recentSessions = [];
  List<TaskModel> _runningTasks = [];
  List<String> _availableAgents = [];
  bool _isLoading = true;

  StreamSubscription? _sessionsSub;
  StreamSubscription? _tasksSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  void _initServices() {
    final auth = context.read<AuthProvider>();
    _sessionService = SessionService(auth.ws);
    _taskService = TaskService(auth.ws);
    _availableAgents = auth.ws.availableAgents;
    
    _setupListeners();
    _loadData();
  }

  void _setupListeners() {
    _sessionsSub = _sessionService.onSessionsChanged.listen((sessions) {
      setState(() {
        _recentSessions = sessions.take(6).toList();
        _isLoading = false;
      });
    });

    _taskService.onTasksChanged.listen((tasks) {
      setState(() {
        _runningTasks = tasks.where((t) => t.status == TaskStatus.running).toList();
      });
    });
  }

  void _loadData() {
    _sessionService.requestSessionList();
    _taskService.requestTaskList();
  }

  void _startChat({String? agent, String? initialMessage}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModernChatScreen(
          initialAgent: agent ?? _selectedAgent,
          initialMessage: initialMessage,
        ),
      ),
    );
  }

  void _sendQuickMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _startChat(agent: _selectedAgent, initialMessage: text);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _sessionsSub?.cancel();
    _tasksSub?.cancel();
    _sessionService.dispose();
    _taskService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildQuickInput()),
            SliverToBoxAdapter(child: _buildSectionHeader('Laufende Tasks', Icons.sync, showViewAll: true)),
            SliverToBoxAdapter(child: _buildRunningTasks()),
            SliverToBoxAdapter(child: _buildSectionHeader('Letzte Chats', Icons.chat_bubble_outline)),
            SliverToBoxAdapter(child: _buildRecentSessions()),
            SliverToBoxAdapter(child: _buildSectionHeader('Agents', Icons.smart_toy_outlined)),
            SliverToBoxAdapter(child: _buildAgentsGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets,
              color: AppColors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ClawChat',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      auth.ws.isConnected ? 'Verbunden' : 'Getrennt',
                      style: AppTypography.captionSmall.copyWith(
                        color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              _buildAgentDropdown(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Was möchtest du wissen?',
                    hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onSubmitted: (_) => _sendQuickMessage(),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.textPrimary, size: 20),
                  onPressed: _sendQuickMessage,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: PopupMenuButton<String>(
        initialValue: _selectedAgent,
        onSelected: (agent) => setState(() => _selectedAgent = agent),
        offset: const Offset(0, 40),
        color: AppColors.bgElevated,
        itemBuilder: (context) => _availableAgents.map((agent) {
          return PopupMenuItem<String>(
            value: agent,
            child: Row(
              children: [
                Icon(
                  _getAgentIcon(agent),
                  size: 18,
                  color: agent == _selectedAgent ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  agent,
                  style: AppTypography.body.copyWith(
                    color: agent == _selectedAgent ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (agent == _selectedAgent) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          );
        }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getAgentIcon(_selectedAgent),
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedAgent,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getAgentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'coding':
      case 'dev':
        return Icons.code;
      case 'research':
      case 'search':
        return Icons.search;
      case 'image':
      case 'vision':
        return Icons.image;
      case 'voice':
      case 'audio':
        return Icons.mic;
      default:
        return Icons.smart_toy;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool showViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const Spacer(),
          if (showViewAll)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                );
              },
              child: Text(
                'Alle anzeigen',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningTasks() {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: SkeletonLoader(width: 200, height: 80),
          ),
        ),
      );
    }

    if (_runningTasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.textMuted, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Keine laufenden Tasks',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _runningTasks.length,
        itemBuilder: (context, index) {
          final task = _runningTasks[index];
          return _RunningTaskCard(
            task: task,
            onTap: () => _showTaskDetails(task),
          );
        },
      ),
    );
  }

  void _showTaskDetails(TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailsSheet(task: task),
    );
  }

  Widget _buildRecentSessions() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonLoader(height: 72),
            ),
          ),
        ),
      );
    }

    if (_recentSessions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Noch keine Chats',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Starte oben eine neue Konversation',
              style: AppTypography.captionSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: _recentSessions.map((session) {
          return _SessionCard(
            session: session,
            onTap: () => _startChat(agent: session.agentId),
            onDelete: () => _sessionService.deleteSession(session.id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgentsGrid() {
    if (_availableAgents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Verbinde dich mit dem Gateway um Agents zu sehen',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _availableAgents.map((agent) {
          return _AgentCard(
            agent: agent,
            onTap: () => _startChat(agent: agent),
          );
        }).toList(),
      ),
    );
  }
}

class _RunningTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _RunningTaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: task.progress,
                    strokeWidth: 2,
                    color: AppColors.primary,
                    backgroundColor: AppColors.bgTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    task.name,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: task.progress,
              backgroundColor: AppColors.bgTertiary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(task.progress * 100).toInt()}%',
              style: AppTypography.captionSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: session.isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    session.isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
                    color: session.isActive ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (session.agentId != null) ...[
                            Icon(
                              _getAgentIcon(session.agentId!),
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              session.agentId!,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Icon(
                            Icons.message,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.messageCount}',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(session.lastMessageAt ?? session.createdAt),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  color: AppColors.bgElevated,
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Löschen', style: AppTypography.body.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAgentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'coding':
      case 'dev':
        return Icons.code;
      case 'research':
      case 'search':
        return Icons.search;
      default:
        return Icons.smart_toy;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class _AgentCard extends StatelessWidget {
  final String agent;
  final VoidCallback onTap;

  const _AgentCard({required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getAgentIcon(agent),
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                agent,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAgentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'coding':
      case 'dev':
        return Icons.code;
      case 'research':
      case 'search':
        return Icons.search;
      case 'image':
      case 'vision':
        return Icons.image;
      case 'voice':
      case 'audio':
        return Icons.mic;
      default:
        return Icons.smart_toy;
    }
  }
}

class _TaskDetailsSheet extends StatelessWidget {
  final TaskModel task;

  const _TaskDetailsSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(task.name, style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatusChip(status: task.status),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(task.progress * 100).toInt()}%',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LinearProgressIndicator(
            value: task.progress,
            backgroundColor: AppColors.bgTertiary,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (task.agent != null)
            _DetailRow(label: 'Agent', value: task.agent!),
          if (task.cronExpression != null)
            _DetailRow(label: 'Cron', value: task.cronExpression!),
          _DetailRow(label: 'Erstellt', value: _formatDate(task.createdAt)),
          if (task.lastProgressMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      task.lastProgressMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Schließen'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Neu starten'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.running:
        color = AppColors.info;
        label = 'Läuft';
        break;
      case TaskStatus.completed:
        color = AppColors.success;
        label = 'Fertig';
        break;
      case TaskStatus.failed:
        color = AppColors.error;
        label = 'Fehler';
        break;
      case TaskStatus.pending:
        color = AppColors.warning;
        label = 'Ausstehend';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.captionSmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
