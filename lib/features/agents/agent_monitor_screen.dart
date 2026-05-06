import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/mock_agent_data.dart';
import '../../models/agent_session.dart';
import '../../models/agent_status.dart';
import 'widgets/widgets.dart';

/// Main Agent Control Center screen with filter/sort, grid/list view, and animations
class AgentMonitorScreen extends StatefulWidget {
  const AgentMonitorScreen({super.key});

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

  // WebSocket connection controller (for future real implementation)
  @override
  void initState() {
    super.initState();
    _loadAgents();
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
        child: const Icon(Icons.add, color: AppColors.textPrimary),
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
              Icons.pets,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '🔮 Agent Control Center',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
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
                Icons.cloud_off,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Lost',
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to connect to agent services.',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _reconnect,
              icon: const Icon(Icons.refresh),
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
              onTap: () {
                // TODO: Show detailed stats
              },
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
              Icons.pets,
              size: 80,
              color: isDark
                  ? AppColors.textDarkSecondary.withValues(alpha: 0.3)
                  : AppColors.textLightSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No agents found',
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == AgentFilter.all
                  ? 'No agents available.'
                  : 'No agents match the selected filter.',
              style: TextStyle(
                color:
                    isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_selectedFilter != AgentFilter.all)
              ElevatedButton.icon(
                onPressed: () => _onFilterChanged(AgentFilter.all),
                icon: const Icon(Icons.clear),
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
                icon: const Icon(Icons.add),
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
            // TODO: Navigate to chat
          },
          onCancelTask: () {
            Navigator.pop(context);
            _cancelAgentTask(agent);
          },
          onSendMessage: () {
            Navigator.pop(context);
            // TODO: Open message dialog
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
          // TODO: Open message dialog
        },
        onCancelTask: () {
          _cancelAgentTask(agent);
        },
        onViewHistory: () {
          // TODO: Navigate to history
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
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Agent',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
                  // TODO: Store selected agent
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Task Description',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
                  child: const Text(
                    'Start Task',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            const Text(
              'Reconnecting...',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (!isConnected) {
      return IconButton(
        icon: const Icon(Icons.cloud_off, color: AppColors.error),
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