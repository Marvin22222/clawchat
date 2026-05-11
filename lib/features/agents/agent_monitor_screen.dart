import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/mock_agent_data.dart';
import '../../models/agent_session.dart';
import '../../models/agent_status.dart';
import '../../widgets/animations/app_transitions.dart';
import 'widgets/widgets.dart';
import '../chat/chat_screen.dart';

// Navigation callback typedefs
typedef NavigateToChatCallback = void Function(String? agentId);
typedef NavigateToHistoryCallback = void Function(String? agentId);
typedef SendMessageCallback = void Function(String agentId);

/// Main Agent Control Center screen with filter/sort, grid/list view, and animations
class AgentMonitorScreen extends StatefulWidget {
  final NavigateToChatCallback? onNavigateToChat;
  final SendMessageCallback? onSendMessage;
  final NavigateToHistoryCallback? onNavigateToHistory;

  const AgentMonitorScreen({
    super.key,
    this.onNavigateToChat,
    this.onSendMessage,
    this.onNavigateToHistory,
  });

  @override
  State<AgentMonitorScreen> createState() => _AgentMonitorScreenState();
}

class _AgentMonitorScreenState extends State<AgentMonitorScreen>
    with TickerProviderStateMixin {
  // Connection state
  bool _isConnected = true;
  bool _isReconnecting = false;

  // Agent data
  List<AgentSession> _allAgents = [];
  List<AgentSession> _filteredAgents = [];
  bool _isLoading = true;

  // Animation controllers for cards
  final List<AnimationController> _cardControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  // Filter and sort state
  AgentFilter _selectedFilter = AgentFilter.all;
  AgentSort _selectedSort = AgentSort.name;
  AgentViewMode _viewMode = AgentViewMode.list;

  // Selected agent for new task modal
  String? _selectedAgentForTask;

  // WebSocket connection controller (for future real implementation)
  @override
  void initState() {
    super.initState();
    _loadLastSelectedAgent();
    _loadAgents();
  }

  Future<void> _loadLastSelectedAgent() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAgent = prefs.getString('last_selected_agent');
    if (lastAgent != null && mounted) {
      setState(() {
        _selectedAgentForTask = lastAgent;
      });
    }
  }

  Future<void> _storeSelectedAgent(String? agentId) async {
    _selectedAgentForTask = agentId;
    final prefs = await SharedPreferences.getInstance();
    if (agentId != null) {
      await prefs.setString('last_selected_agent', agentId);
    } else {
      await prefs.remove('last_selected_agent');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _allAgents = MockAgentData.getMockAgents();
      _applyFiltersAndSort();
      _isLoading = false;
    });

    // Setup staggered animations after data is loaded
    _setupCardAnimations();
  }

  void _applyFiltersAndSort() {
    // Apply filter
    switch (_selectedFilter) {
      case AgentFilter.all:
        _filteredAgents = List.from(_allAgents);
        break;
      case AgentFilter.active:
        _filteredAgents = _allAgents
            .where((a) => a.status == AgentStatus.live || a.status == AgentStatus.busy)
            .toList();
        break;
      case AgentFilter.idle:
        _filteredAgents = _allAgents
            .where((a) => a.status == AgentStatus.idle)
            .toList();
        break;
      case AgentFilter.error:
        _filteredAgents = _allAgents
            .where((a) => a.status == AgentStatus.error)
            .toList();
        break;
    }

    // Apply sort
    switch (_selectedSort) {
      case AgentSort.name:
        _filteredAgents.sort((a, b) => a.name.compareTo(b.name));
        break;
      case AgentSort.status:
        _filteredAgents.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case AgentSort.lastActive:
        _filteredAgents.sort((a, b) {
          if (a.lastActive == null && b.lastActive == null) return 0;
          if (a.lastActive == null) return 1;
          if (b.lastActive == null) return -1;
          return b.lastActive!.compareTo(a.lastActive!);
        });
        break;
    }
  }

  void _setupCardAnimations() {
    // Dispose old controllers
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();
    _slideAnimations.clear();
    _fadeAnimations.clear();

    // Create controllers for each agent
    for (int i = 0; i < _filteredAgents.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _cardControllers.add(controller);

      // Slide from bottom with offset
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
      _slideAnimations.add(slideAnimation);

      // Fade in
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeIn,
      ));
      _fadeAnimations.add(fadeAnimation);

      // Staggered start - 50ms delay between cards
      Future.delayed(Duration(milliseconds: 50 * i), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  void _onFilterChanged(AgentFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFiltersAndSort();
      _setupCardAnimations();
    });
  }

  void _onSortChanged(AgentSort sort) {
    setState(() {
      _selectedSort = sort;
      _applyFiltersAndSort();
      _setupCardAnimations();
    });
  }

  void _onViewModeChanged(AgentViewMode mode) {
    setState(() {
      _viewMode = mode;
      _setupCardAnimations();
    });
  }

  Future<void> _reconnect() async {
    setState(() => _isReconnecting = true);

    // Simulate reconnection
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isConnected = true;
      _isReconnecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewTaskModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Iconsax.add, color: AppColors.textPrimary),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.emoji_happy,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '🔮 Agent Control Center',
            style: AppTypography.h5,
          ),
        ],
      ),
      actions: [
        // Connection status indicator
        _ConnectionStatusIndicator(
          isConnected: _isConnected,
          isReconnecting: _isReconnecting,
          onReconnect: _reconnect,
        ),
        IconButton(
          icon: const Icon(Iconsax.refresh, color: AppColors.textSecondary),
          onPressed: _loadAgents,
        ),
      ],
    );
  }

  Widget _buildBody() {
    // Connection error state
    if (!_isConnected && !_isReconnecting) {
      return _buildConnectionError();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return _buildContent();
  }

  Widget _buildConnectionError() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.cloud_no_update,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Lost',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to connect to agent services.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _reconnect,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Reconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Empty state when no agents or filtered results
    if (_filteredAgents.isEmpty ||
        _filteredAgents.every((a) => a.status == AgentStatus.idle)) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAgents,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // Filter bar
          SliverToBoxAdapter(
            child: FilterBar(
              selectedFilter: _selectedFilter,
              selectedSort: _selectedSort,
              viewMode: _viewMode,
              onFilterChanged: _onFilterChanged,
              onSortChanged: _onSortChanged,
              onViewModeChanged: _onViewModeChanged,
            ),
          ),

          // Stats summary bar
          SliverToBoxAdapter(
            child: StatsSummaryBar(
              agents: _allAgents,
              onTap: () => _showDetailedStats(context),
            ),
          ),

          // Agent cards
          if (_viewMode == AgentViewMode.grid)
            _buildGridView()
          else
            _buildListView(),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final agent = _filteredAgents[index];
            return AgentCard(
              agent: agent,
              onTap: () => _showAgentDetail(agent),
              onLongPress: () => _showQuickActions(agent),
            );
          },
          childCount: _filteredAgents.length,
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final agent = _filteredAgents[index];
          final animationIndex =
              index < _cardControllers.length ? index : 0;

          if (index >= _cardControllers.length) {
            // Fallback for safety
            return AgentCard(
              agent: agent,
              onTap: () => _showAgentDetail(agent),
              onLongPress: () => _showQuickActions(agent),
            );
          }

          return SlideTransition(
            position: _slideAnimations[animationIndex],
            child: FadeTransition(
              opacity: _fadeAnimations[animationIndex],
              child: AgentCard(
                agent: agent,
                onTap: () => _showAgentDetail(agent),
                onLongPress: () => _showQuickActions(agent),
              ),
            ),
          );
        },
        childCount: _filteredAgents.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.emoji_happy,
              size: 80,
              color: isDark
                  ? AppColors.textDarkSecondary.withValues(alpha: 0.3)
                  : AppColors.textLightSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No agents found',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == AgentFilter.all
                  ? 'No agents available.'
                  : 'No agents match the selected filter.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_selectedFilter != AgentFilter.all)
              ElevatedButton.icon(
                onPressed: () => _onFilterChanged(AgentFilter.all),
                icon: const Icon(Iconsax.close_square),
                label: const Text('Clear Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _showNewTaskModal,
                icon: const Icon(Iconsax.add),
                label: const Text('Start New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAgentDetail(AgentSession agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AgentDetailSheet(
          agent: agent,
          onViewChat: () {
            Navigator.pop(context);
            _navigateToChat(agent);
          },
          onCancelTask: () {
            Navigator.pop(context);
            _cancelAgentTask(agent);
          },
          onSendMessage: () {
            Navigator.pop(context);
            _showSendMessageDialog(agent);
          },
        ),
      ),
    );
  }

  void _showQuickActions(AgentSession agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickActionsSheet(
        agent: agent,
        onSendMessage: () {
          Navigator.pop(context);
          _showSendMessageDialog(agent);
        },
        onCancelTask: () {
          _cancelAgentTask(agent);
        },
        onViewHistory: () {
          Navigator.pop(context);
          _navigateToHistory(agent);
        },
        onResetAgent: () {
          _resetAgent(agent);
        },
      ),
    );
  }

  void _cancelAgentTask(AgentSession agent) {
    setState(() {
      final index = _allAgents.indexWhere((a) => a.id == agent.id);
      if (index != -1) {
        _allAgents[index] = agent.copyWith(
          status: AgentStatus.idle,
          currentTask: null,
          progress: 0.0,
          steps: [],
        );
        _applyFiltersAndSort();
        _setupCardAnimations();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task cancelled for ${agent.name}'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _resetAgent(AgentSession agent) {
    setState(() {
      final index = _allAgents.indexWhere((a) => a.id == agent.id);
      if (index != -1) {
        _allAgents[index] = agent.copyWith(
          status: AgentStatus.idle,
          currentTask: null,
          progress: 0.0,
          steps: [],
          lastActive: DateTime.now(),
        );
        _applyFiltersAndSort();
        _setupCardAnimations();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${agent.name} has been reset'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showNewTaskModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDarkSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '➕ New Task',
                    style: AppTypography.h5,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Iconsax.close_square, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Agent',
                style: AppTypography.label,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgDarkTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: AppColors.bgElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                value: _selectedAgentForTask,
                items: _allAgents.map((agent) {
                  return DropdownMenuItem(
                    value: agent.id,
                    child: Row(
                      children: [
                        Text(agent.avatarEmoji),
                        const SizedBox(width: 8),
                        Text(agent.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  _storeSelectedAgent(value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Task Description',
                style: AppTypography.label,
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What should this agent do?',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgDarkTertiary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Task',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show detailed stats modal
  void _showDetailedStats(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate detailed stats
    final totalAgents = _allAgents.length;
    final activeCount = _allAgents.where((a) => 
        a.status == AgentStatus.live || a.status == AgentStatus.busy).length;
    final busyCount = _allAgents.where((a) => a.status == AgentStatus.busy).length;
    final idleCount = _allAgents.where((a) => a.status == AgentStatus.idle).length;
    final errorCount = _allAgents.where((a) => a.status == AgentStatus.error).length;
    
    // Calculate total messages processed (mock data for demo)
    final totalMessages = _allAgents.length * 42; // Mock: ~42 messages per agent
    final avgResponseTime = '1.2s'; // Mock average
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Detailed Statistics',
                  style: AppTypography.h4,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_square, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.robot,
                    label: 'Total Agents',
                    value: '$totalAgents',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.tick_square_circle,
                    label: 'Active',
                    value: '$activeCount',
                    color: const Color(0xFF22C55E),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.timer_pause,
                    label: 'Busy',
                    value: '$busyCount',
                    color: const Color(0xFFEAB308),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.pause_circle,
                    label: 'Idle',
                    value: '$idleCount',
                    color: const Color(0xFF6B7280),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.warning_2,
                    label: 'Errors',
                    value: '$errorCount',
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.message_text,
                    label: 'Total Msgs',
                    value: '$totalMessages',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Average response time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.speedometer, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Avg Response Time',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    avgResponseTime,
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Navigate to chat screen with the agent
  void _navigateToChat(AgentSession agent) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        builder: (_) => ChatScreen(initialAgent: agent.name),
      ),
    );
  }

  /// Show dialog to send a direct message to an agent
  void _showSendMessageDialog(AgentSession agent) {
    final messageController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(agent.avatarEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              'Message ${agent.name}',
              style: AppTypography.body,
            ),
          ],
        ),
        content: TextField(
          controller: messageController,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: TextStyle(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
            filled: true,
            fillColor: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to ${agent.name}'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
            },
            icon: const Icon(Iconsax.send, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to session history for the agent
  void _navigateToHistory(AgentSession agent) {
    // Import history screen - navigate to it
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        builder: (_) => _AgentHistoryScreen(agent: agent),
      ),
    );
  }
}

/// Stats card widget for detailed stats modal
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.h4.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple history screen for agent sessions
class _AgentHistoryScreen extends StatelessWidget {
  final AgentSession agent;

  const _AgentHistoryScreen({required this.agent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: Row(
          children: [
            Text(agent.avatarEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              '${agent.name} History',
              style: AppTypography.body,
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Agent info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent Details',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 12),
                _HistoryRow(label: 'Name', value: agent.name),
                _HistoryRow(label: 'Role', value: agent.role ?? 'Unknown'),
                _HistoryRow(label: 'Status', value: agent.status.name),
                _HistoryRow(label: 'Started', value: agent.startedAt?.toString().split('.').first ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Recent activity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 12),
                _HistoryRow(label: 'Last Active', value: agent.lastActive?.toString().split('.').first ?? 'Never'),
                _HistoryRow(label: 'Current Task', value: agent.currentTask ?? 'None'),
                _HistoryRow(label: 'Progress', value: '${(agent.progress * 100).toInt()}%'),
                _HistoryRow(label: 'Steps Completed', value: '${agent.steps.length}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Messages processed (mock)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 12),
                _HistoryRow(label: 'Messages Processed', value: '42'),
                _HistoryRow(label: 'Avg Response Time', value: '1.2s'),
                _HistoryRow(label: 'Uptime', value: agent.durationString),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Connection status indicator with reconnect button
class _ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isReconnecting;
  final VoidCallback onReconnect;

  const _ConnectionStatusIndicator({
    required this.isConnected,
    required this.isReconnecting,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    if (isReconnecting) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Reconnecting...',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    if (!isConnected) {
      return IconButton(
        icon: const Icon(Iconsax.cloud_no_update, color: AppColors.error),
        onPressed: onReconnect,
        tooltip: 'Connection lost. Tap to reconnect.',
      );
    }

    // Connected - show subtle indicator
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}