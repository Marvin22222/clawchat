import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/skeleton_loaders.dart';
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
      MaterialPageRoute(
        builder: (_) => ChatScreen(
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
            onPressed: _loadAgents,
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
              icon: const Icon(Icons.send, color: AppColors.textPrimary, size: 20),
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
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
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
