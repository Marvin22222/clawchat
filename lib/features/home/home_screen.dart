import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/notification_settings_service.dart';
import '../../core/services/storage_info_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../../widgets/animated_theme_toggle.dart';
import '../chat/chat_screen.dart';
import '../agents/agents_screen.dart';
import '../tasks/tasks_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notification_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _welcomeAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showWelcomeBack = false;
  int _messagesToday = 12; // Mock data - in real app would come from stats service
  
  @override
  void initState() {
    super.initState();
    _welcomeAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeAnimController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _welcomeAnimController, curve: Curves.elasticOut),
    );
    
    // Check if should show welcome back (after 30 min away - simplified for demo)
    _checkWelcomeBack();
  }

  void _checkWelcomeBack() {
    // In a real app, you'd track last active time
    // For now, we'll show it randomly or based on time
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 8) {
      setState(() => _showWelcomeBack = true);
      _welcomeAnimController.forward();
    }
  }

  void _dismissWelcomeBack() {
    _welcomeAnimController.reverse().then((_) {
      if (mounted) setState(() => _showWelcomeBack = false);
    });
  }

  @override
  void dispose() {
    _welcomeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: _buildAppBar(context, isDark, settings),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= AppDimensions.tabletBreakpoint;
              
              if (isDesktop) {
                return _buildDesktopLayout(context, isDark, auth, settings);
              }
              return _buildMobileLayout(context, isDark, auth, settings);
            },
          ),
          // Welcome back overlay
          if (_showWelcomeBack) _buildWelcomeBackOverlay(context, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, ThemeProvider theme) {
    return AppBar(
      title: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.claw, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('ClawChat'),
        ],
      ),
      actions: [
        _buildQuickSettingsRow(context, isDark, settings),
        _buildNotificationBell(context),
        IconButton(
          icon: const Icon(Iconsax.setting_2),
          onPressed: () {
            Navigator.push(
              context,
              AppPageTransitions.fadeSlide(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickSettingsRow(BuildContext context, bool isDark, ThemeProvider settings) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dark/Light mode toggle - Animated sun/moon
          AnimatedThemeToggle(
            isDark: isDark,
            onToggle: () => settings.toggleTheme(),
            size: 36,
          ),
          const SizedBox(width: AppSpacing.xs),
          // Notification toggle
          FutureBuilder<bool>(
            future: NotificationSettingsService.getNotificationsEnabled(),
            builder: (context, snapshot) {
              final notifEnabled = snapshot.data ?? true;
              return _QuickToggle(
                icon: notifEnabled ? Iconsax.notification : Iconsax.notification_slash,
                isActive: notifEnabled,
                onTap: () async {
                  await NotificationSettingsService.setNotificationsEnabled(!notifEnabled);
                  if (mounted) setState(() {});
                },
                tooltip: notifEnabled ? 'Notifications An' : 'Notifications Aus',
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          // Sound toggle
          _QuickToggle(
            icon: settings.isDarkMode ? Iconsax.volume_high : Iconsax.volume_slash,
            isActive: settings.isDarkMode,
            onTap: () => settings.toggleTheme(),
            tooltip: 'Sound',
          ),
          const SizedBox(width: AppSpacing.sm),
          // Agent selector dropdown
          _buildAgentSelector(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAgentSelector(BuildContext context, bool isDark) {
    final auth = context.read<AuthProvider>();
    final agents = auth.ws.availableAgents;
    
    return PopupMenuButton<String>(
      tooltip: 'Agent wechseln',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.robot, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            const Text('Agent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Iconsax.arrow_down_1, size: 12, color: AppColors.primary),
          ],
        ),
      ),
      itemBuilder: (context) => [
        if (agents.isEmpty)
          const PopupMenuItem(
            enabled: false,
            child: Text('Keine Agents verfügbar'),
          )
        else
          ...agents.map((agent) => PopupMenuItem(
            value: agent,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    agent[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(agent),
              ],
            ),
          )),
      ],
      onSelected: (agent) {
        if (auth.ws.isConnected) {
          Navigator.push(
            context,
            AppPageTransitions.fadeSlide(
              builder: (_) => ChatScreen(initialAgent: agent),
            ),
          );
        }
      },
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return FutureBuilder<bool>(
      future: NotificationSettingsService.getNotificationsEnabled(),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? true;
        
        return IconButton(
          icon: Stack(
            children: [
              Icon(
                enabled ? Iconsax.notification : Iconsax.notification_slash,
                color: enabled ? null : AppColors.error,
              ),
              if (!enabled)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => NotificationQuickSheet.show(context),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark, AuthProvider auth, ThemeProvider settings) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatus(context, auth),
            const SizedBox(height: AppSpacing.lg),
            _buildAppShortcuts(context, isDark, auth),
            const SizedBox(height: AppSpacing.xl),
            _buildDashboardCards(context, isDark, auth),
            const SizedBox(height: AppSpacing.xl),
            _buildAgentsSection(context, isDark, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark, AuthProvider auth, ThemeProvider settings) {
    return SafeArea(
      child: Padding(
        padding: Responsive.padding(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar - Navigation & Status
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConnectionStatusCard(context, auth),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDesktopNavigation(context, isDark, auth),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAppShortcuts(context, isDark, auth),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Right content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboardCards(context, isDark, auth),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAgentsSection(context, isDark, auth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppShortcuts(BuildContext context, bool isDark, AuthProvider auth) {
    final shortcuts = [
      _AppShortcutData(icon: Iconsax.message_add, title: 'Neuer Chat', color: AppColors.primary, action: () {
        if (auth.ws.isConnected) _navigateTo(context, const ChatScreen());
      }),
      _AppShortcutData(icon: Iconsax.repeat, title: 'Agent wechseln', color: AppColors.secondary, action: () {
        if (auth.ws.isConnected) _navigateTo(context, const AgentsScreen());
      }),
      _AppShortcutData(icon: Iconsax.task, title: 'Aufgaben', color: AppColors.info, action: () {
        if (auth.ws.isConnected) _navigateTo(context, const TasksScreen());
      }),
      _AppShortcutData(icon: Iconsax.setting_2, title: 'Einstellungen', color: AppColors.warning, action: () {
        _navigateTo(context, const SettingsScreen());
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width < AppDimensions.tabletBreakpoint)
          Text(
            'Schnellzugriffe',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            return _AppShortcutWidget(
              data: shortcuts[index],
              isDark: isDark,
              isEnabled: auth.ws.isConnected || shortcuts[index].title == 'Einstellungen',
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboardCards(BuildContext context, bool isDark, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              // Tablet/Desktop: 2x2 grid
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _DashboardCard(
                      title: 'Aktive Agents',
                      value: '${auth.ws.availableAgents.length}',
                      subtitle: 'online',
                      icon: Iconsax.robot,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _DashboardCard(
                      title: 'Nachrichten heute',
                      value: '$_messagesToday',
                      subtitle: 'gesendet',
                      icon: Iconsax.messages,
                      color: AppColors.secondary,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _StorageDashboardCard(isDark: isDark),
                  ),
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _DashboardCard(
                      title: 'Verbindung',
                      value: auth.ws.isConnected ? 'OK' : 'Getrennt',
                      subtitle: auth.ws.isConnected ? 'verbunden' : '',
                      icon: auth.ws.isConnected ? Iconsax.global : Iconsax.global_edit,
                      color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            }
            // Mobile: vertical list
            return Column(
              children: [
                _DashboardCard(
                  title: 'Aktive Agents',
                  value: '${auth.ws.availableAgents.length}',
                  subtitle: 'online',
                  icon: Iconsax.robot,
                  color: AppColors.primary,
                  isDark: isDark,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _DashboardCard(
                  title: 'Nachrichten heute',
                  value: '$_messagesToday',
                  subtitle: 'gesendet',
                  icon: Iconsax.messages,
                  color: AppColors.secondary,
                  isDark: isDark,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _StorageDashboardCard(isDark: isDark, compact: true),
                const SizedBox(height: AppSpacing.sm),
                _DashboardCard(
                  title: 'Verbindung',
                  value: auth.ws.isConnected ? 'Verbunden' : 'Getrennt',
                  subtitle: '',
                  icon: auth.ws.isConnected ? Iconsax.global : Iconsax.global_edit,
                  color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                  isDark: isDark,
                  compact: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Gerade';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Widget _buildWelcomeBackOverlay(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _welcomeAnimController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.xl),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDark : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'welcome_icon',
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.sparkle,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Willkommen zurück! 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Du hast $_messagesToday neue Nachrichten',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WelcomeStatChip(
                            icon: Iconsax.message,
                            text: '$_messagesToday Nachrichten',
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _WelcomeStatChip(
                            icon: Iconsax.calendar,
                            text: '${DateTime.now().day}. ${_getMonthName(DateTime.now().month)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton.icon(
                        onPressed: _dismissWelcomeBack,
                        icon: const Icon(Iconsax.arrow_right),
                        label: const Text('Weiter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    return months[month - 1];
  }

  Widget _buildConnectionStatus(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: auth.ws.isConnected 
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: auth.ws.isConnected 
                  ? AppColors.success 
                  : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            auth.ws.isConnected ? 'Verbunden' : 'Getrennt',
            style: TextStyle(
              color: auth.ws.isConnected 
                  ? AppColors.success 
                  : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                auth.ws.isConnected ? 'Verbunden' : 'Getrennt',
                style: TextStyle(
                  color: auth.ws.isConnected ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (auth.ws.isConnected) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${auth.ws.availableAgents.length} Agents verfügbar',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopNavigation(BuildContext context, bool isDark, AuthProvider auth) {
    return Column(
      children: [
        _DesktopNavItem(
          icon: Iconsax.messages,
          title: 'Chat',
          isSelected: true,
          onTap: auth.ws.isConnected
              ? () {
                  Navigator.push(
                    context,
                    AppPageTransitions.fadeSlide(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DesktopNavItem(
          icon: Iconsax.robot,
          title: 'Agents',
          onTap: auth.ws.isConnected
              ? () {
                  Navigator.push(
                    context,
                    AppPageTransitions.fadeSlide(
                      builder: (_) => const AgentsScreen(),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DesktopNavItem(
          icon: Iconsax.task,
          title: 'Aufgaben',
          onTap: auth.ws.isConnected
              ? () {
                  Navigator.push(
                    context,
                    AppPageTransitions.fadeSlide(
                      builder: (_) => const TasksScreen(),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DesktopNavItem(
          icon: Iconsax.setting_2,
          title: 'Einstellungen',
          onTap: () {
            Navigator.push(
              context,
              AppPageTransitions.fadeSlide(
                builder: (_) => const SettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgentsSection(BuildContext context, bool isDark, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Verfügbare Agents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (auth.ws.availableAgents.isNotEmpty)
              TextButton.icon(
                onPressed: () => _navigateTo(context, const AgentsScreen()),
                icon: const Icon(Iconsax.arrow_right, size: 16),
                label: const Text('Alle anzeigen'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (auth.ws.availableAgents.isEmpty && auth.ws.isConnected)
          _buildLoadingAgentsCard(context, isDark)
        else if (!auth.ws.isConnected)
          Text(
            'Bitte verbinde dich zuerst.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              
              if (isWide) {
                // Desktop/Tablet: Grid of cards
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: auth.ws.availableAgents.map((agent) => SizedBox(
                    width: 200,
                    child: _AgentCard(agent: agent, onTap: () => _navigateTo(context, ChatScreen(initialAgent: agent))),
                  )).toList(),
                );
              }
              
              // Mobile: List
              return Column(
                children: auth.ws.availableAgents.map((agent) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    tileColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
                    leading: Hero(
                      tag: 'agent_avatar_${agent}_home',
                      child: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          agent[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    title: Text(agent),
                    trailing: const Icon(Iconsax.chevron_right),
                    onTap: () => _navigateTo(context, ChatScreen(initialAgent: agent)),
                  ),
                )).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoadingAgentsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        builder: (_) => screen,
      ),
    );
  }
}

// Quick toggle button widget
class _QuickToggle extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _QuickToggle({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_QuickToggle> createState() => _QuickToggleState();
}

class _QuickToggleState extends State<_QuickToggle> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animController.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isActive 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive 
                      ? AppColors.primary 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.textDarkSecondary 
                          : AppColors.textLightSecondary),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// App shortcut data class
class _AppShortcutData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback action;

  const _AppShortcutData({
    required this.icon,
    required this.title,
    required this.color,
    required this.action,
  });
}

// App shortcut widget (iOS/Android style)
class _AppShortcutWidget extends StatefulWidget {
  final _AppShortcutData data;
  final bool isDark;
  final bool isEnabled;

  const _AppShortcutWidget({
    required this.data,
    required this.isDark,
    required this.isEnabled,
  });

  @override
  State<_AppShortcutWidget> createState() => _AppShortcutWidgetState();
}

class _AppShortcutWidgetState extends State<_AppShortcutWidget> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.isEnabled) {
          setState(() => _isPressed = true);
          _bounceController.forward();
        }
      },
      onTapUp: (_) {
        if (widget.isEnabled) {
          setState(() => _isPressed = false);
          _bounceController.reverse();
          widget.data.action();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _bounceController.reverse();
      },
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: widget.isEnabled
                    ? (widget.isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: widget.data.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: widget.isEnabled
                          ? widget.data.color.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: Icon(
                      widget.data.icon,
                      size: 32,
                      color: widget.isEnabled
                          ? widget.data.color
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.data.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isEnabled
                          ? (widget.isDark ? AppColors.textDark : AppColors.textLight)
                          : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Dashboard card widget
class _DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool compact;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.compact = false,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _flipController.forward().then((_) {
                _flipController.reverse();
              });
            },
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: EdgeInsets.all(widget.compact ? AppSpacing.md : AppSpacing.lg),
              child: widget.compact ? _buildCompactContent() : _buildFullContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(widget.icon, color: widget.color, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              if (widget.subtitle.isNotEmpty)
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(widget.icon, color: widget.color, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Welcome stat chip
class _WelcomeStatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _WelcomeStatChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Desktop nav item
class _DesktopNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DesktopNavItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_DesktopNavItem> createState() => _DesktopNavItemState();
}

class _DesktopNavItemState extends State<_DesktopNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? AppColors.primary.withOpacity(0.1)
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
                  Icon(
                    widget.icon,
                    color: widget.isSelected 
                        ? AppColors.primary 
                        : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.isSelected 
                          ? AppColors.primary 
                          : (isDark ? AppColors.textDark : AppColors.textLight),
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
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

// Agent card with hero animation
class _AgentCard extends StatefulWidget {
  final String agent;
  final VoidCallback onTap;

  const _AgentCard({required this.agent, required this.onTap});

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> {
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
        transform: _isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Hero(
                    tag: 'agent_avatar_${widget.agent}_home',
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.agent[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.agent,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isHovered ? 0.1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Iconsax.chevron_right,
                      color: _isHovered ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                    ),
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
// Storage dashboard card widget
class _StorageDashboardCard extends StatefulWidget {
  final bool isDark;
  final bool compact;

  const _StorageDashboardCard({
    required this.isDark,
    this.compact = false,
  });

  @override
  State<_StorageDashboardCard> createState() => _StorageDashboardCardState();
}

class _StorageDashboardCardState extends State<_StorageDashboardCard> {
  int _totalSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final total = await StorageInfoService.getTotalSize();
    if (mounted) {
      setState(() {
        _totalSize = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to settings storage section
        Navigator.push(
          context,
          AppPageTransitions.fadeSlide(
            builder: (_) => const SettingsScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(widget.compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: widget.compact ? _buildCompactContent() : _buildFullContent(),
      ),
    );
  }

  Widget _buildFullContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(Iconsax.database, color: AppColors.info, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speicher',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isLoading ? '...' : StorageInfoService.formatBytes(_totalSize),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              Text(
                'Cache & Daten',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Iconsax.chevron_right,
          color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(Iconsax.database, color: AppColors.info, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speicher',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              Text(
                _isLoading ? '...' : StorageInfoService.formatBytes(_totalSize),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
