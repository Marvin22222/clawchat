import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/mock_agent_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../../widgets/animations/skeleton_loaders.dart';
import '../agents/agent_monitor_screen.dart';
import '../chat/chat_screen.dart';
import '../tasks/tasks_screen.dart';

class HomeHubScreen extends StatefulWidget {
  const HomeHubScreen({super.key});

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedAgent = 'main';
  List<String> _availableAgents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgents();
    });
  }

  void _loadAgents() {
    final auth = context.read<AuthProvider>();
    setState(() {
      _availableAgents = auth.ws.availableAgents;
    });
  }

  void _startChat({String? agent}) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        page: ChatScreen(
          initialAgent: agent ?? _selectedAgent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(auth)),
            SliverToBoxAdapter(child: _buildQuickInput()),
            SliverToBoxAdapter(child: _buildSectionHeader('Zuletzt', Iconsax.clock_1)),
            SliverToBoxAdapter(child: _buildRecentChats()),
            SliverToBoxAdapter(child: _buildSectionHeader('Schnellzugriff', Iconsax.flash_circle_1)),
            SliverToBoxAdapter(child: _buildQuickShortcuts()),
            SliverToBoxAdapter(child: _buildSectionHeader('Agents', Icons.smart_toy_outlined)),
            SliverToBoxAdapter(child: _buildAgentsGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
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
              Iconsax.emoji_happy,
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
            icon: const Icon(Iconsax.refresh, color: AppColors.textSecondary),
            onPressed: _loadAgents,
          ),
          const SizedBox(width: 8),
          _buildAgentBadge(),
        ],
      ),
    );
  }

  Widget _buildAgentBadge() {
    final mockAgents = MockAgentData.getMockAgents();
    final activeCount = mockAgents
        .where((a) => a.status.name == 'live' || a.status.name == 'busy')
        .length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppPageTransitions.fadeSlide(
            page: const AgentMonitorScreen(),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.emoji_happy,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          if (activeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.bgPrimary,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
      child: Row(
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
              onSubmitted: (_) => _startChat(),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.send, color: AppColors.textPrimary, size: 20),
              onPressed: () => _startChat(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDropdown() {
    if (_availableAgents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'main',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
            const Icon(Iconsax.arrow_down_1, color: AppColors.textSecondary, size: 20),
          ],
        ),
      );
    }

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
                  const Icon(Iconsax.tick_square, size: 16, color: AppColors.primary),
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
            const Icon(Iconsax.arrow_down_1, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _getAgentIcon(String agent) {
    switch (agent.toLowerCase()) {
      case 'coding':
      case 'dev':
        return Iconsax.code;
      case 'research':
      case 'search':
        return Iconsax.search_normal_1;
      case 'image':
      case 'vision':
        return Iconsax.image;
      case 'voice':
      case 'audio':
        return Iconsax.microphone;
      default:
        return Icons.smart_toy;
    }
  }

  Widget _buildRecentChats() {
    final auth = context.watch<AuthProvider>();
    final recentChats = auth.chatThreads.take(4).toList();

    if (recentChats.isEmpty) {
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
            Icon(Iconsax.chat_circle_outline, color: AppColors.textMuted, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Noch keine Chats',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: recentChats.map((chat) {
          return _RecentChatTile(
            title: chat.title ?? 'Chat',
            agent: chat.agentName ?? 'main',
            timestamp: chat.updatedAt,
            onTap: () => _startChat(agent: chat.agentName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickShortcuts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _QuickShortcutChip(
            icon: Iconsax.code,
            label: 'Coding',
            color: AppColors.primary,
            onTap: () => _startChat(agent: 'coding'),
          ),
          _QuickShortcutChip(
            icon: Iconsax.search_normal_1,
            label: 'Research',
            color: AppColors.success,
            onTap: () => _startChat(agent: 'research'),
          ),
          _QuickShortcutChip(
            icon: Iconsax.image,
            label: 'Vision',
            color: AppColors.warning,
            onTap: () => _startChat(agent: 'image'),
          ),
          _QuickShortcutChip(
            icon: Iconsax.microphone,
            label: 'Voice',
            color: AppColors.error,
            onTap: () => _startChat(agent: 'voice'),
          ),
          _QuickShortcutChip(
            icon: Iconsax.message,
            label: 'General',
            color: AppColors.info,
            onTap: () => _startChat(),
          ),
        ],
      ),
    );
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
                  AppPageTransitions.fadeSlide(
                    page: const TasksScreen(),
                  ),
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
        child: Column(
          children: [
            Icon(Icons.smart_toy_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Verbinde dich mit dem Gateway',
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Agents werden nach der Verbindung angezeigt',
              style: AppTypography.captionSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
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

class _RecentChatTile extends StatelessWidget {
  final String title;
  final String agent;
  final DateTime? timestamp;
  final VoidCallback onTap;


  const _RecentChatTile({
    required this.title,
    required this.agent,
    this.timestamp,
    required this.onTap,
  });

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Gerade';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month}';
  }

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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.chat, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      agent,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimestamp(timestamp),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickShortcutChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickShortcutChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAgentIcon(agent),
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agent,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getAgentDescription(agent),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Iconsax.arrow_right_1,
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
        return Iconsax.code;
      case 'research':
      case 'search':
        return Iconsax.search_normal_1;
      case 'image':
      case 'vision':
        return Iconsax.image;
      case 'voice':
      case 'audio':
        return Iconsax.microphone;
      default:
        return Icons.smart_toy;
    }
  }

  String _getAgentDescription(String agent) {
    switch (agent.toLowerCase()) {
      case 'coding':
      case 'dev':
        return 'Development';
      case 'research':
      case 'search':
        return 'Research';
      case 'image':
      case 'vision':
        return 'Vision';
      case 'voice':
      case 'audio':
        return 'Voice';
      default:
        return 'General';
    }
  }
}
