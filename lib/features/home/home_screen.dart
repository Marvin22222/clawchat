import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../chat/chat_screen.dart';
import '../agents/agents_screen.dart';
import '../tasks/tasks_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClawChat'),
        actions: [
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppDimensions.tabletBreakpoint;
          
          if (isDesktop) {
            return _buildDesktopLayout(context, isDark, auth);
          }
          return _buildMobileLayout(context, isDark, auth);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark, AuthProvider auth) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConnectionStatus(context, auth),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickActions(context, isDark, auth),
            const SizedBox(height: AppSpacing.xl),
            _buildAgentsSection(context, isDark, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark, AuthProvider auth) {
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
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Right content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgentsSection(context, isDark, auth),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDesktopWelcomeCard(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildDesktopWelcomeCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.sparkle, color: AppColors.primary, size: 28),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Willkommen bei ClawChat!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Du kannst ClawChat jetzt wie eine Desktop-App nutzen. Probiere die Schnellzugriffe oder wähle einen Agenten aus.',
            style: TextStyle(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TipChip(icon: Iconsax.keyboard, text: 'Strg+K für Suche'),
              _TipChip(icon: Iconsax.mouse, text: 'Rechtsklick für Menü'),
              _TipChip(icon: Iconsax.arrow_up, text: 'Hover für Details'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schnellzugriff',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              // Tablet: 3 columns
              return Row(
                children: [
                  Expanded(child: _QuickActionCard(icon: Iconsax.messages, title: 'Chat', color: AppColors.primary, onTap: auth.ws.isConnected ? () => _navigateTo(context, const ChatScreen()) : null)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _QuickActionCard(icon: Iconsax.robot, title: 'Agents', color: AppColors.secondary, onTap: auth.ws.isConnected ? () => _navigateTo(context, const AgentsScreen()) : null)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _QuickActionCard(icon: Iconsax.task, title: 'Tasks', color: AppColors.info, onTap: auth.ws.isConnected ? () => _navigateTo(context, const TasksScreen()) : null)),
                ],
              );
            }
            // Mobile: 3 columns in a row
            return Row(
              children: [
                Expanded(child: _QuickActionCard(icon: Iconsax.messages, title: 'Chat', color: AppColors.primary, onTap: auth.ws.isConnected ? () => _navigateTo(context, const ChatScreen()) : null)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _QuickActionCard(icon: Iconsax.robot, title: 'Agents', color: AppColors.secondary, onTap: auth.ws.isConnected ? () => _navigateTo(context, const AgentsScreen()) : null)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _QuickActionCard(icon: Iconsax.task, title: 'Tasks', color: AppColors.info, onTap: auth.ws.isConnected ? () => _navigateTo(context, const TasksScreen()) : null)),
              ],
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
        Text(
          'Verfügbare Agents',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (auth.ws.availableAgents.isEmpty && auth.ws.isConnected)
          Text(
            'Lade Agents...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          )
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
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        agent[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
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

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      AppPageTransitions.fadeSlide(
        builder: (_) => screen,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Material(
        color: onTap != null 
            ? (isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.agent[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
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
                  Icon(
                    Iconsax.chevron_right,
                    color: _isHovered ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
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

class _TipChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipChip({required this.icon, required this.text});

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