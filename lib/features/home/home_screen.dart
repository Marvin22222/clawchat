import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              Container(
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
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Quick Actions
              Text(
                'Schnellzugriff',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Iconsax.messages,
                      title: 'Chat',
                      color: AppColors.primary,
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Iconsax.robot,
                      title: 'Agents',
                      color: AppColors.secondary,
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Iconsax.task,
                      title: 'Tasks',
                      color: AppColors.info,
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
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Agents
              Text(
                'Verfügbare Agents',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              
              if (auth.ws.availableAgents.isEmpty && auth.ws.isConnected)
                Text(
                  'Lade Agents...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark 
                        ? AppColors.textDarkSecondary 
                        : AppColors.textLightSecondary,
                  ),
                )
              else if (!auth.ws.isConnected)
                Text(
                  'Bitte verbinde dich zuerst.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark 
                        ? AppColors.textDarkSecondary 
                        : AppColors.textLightSecondary,
                  ),
                )
              else
                ...auth.ws.availableAgents.map((agent) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    tileColor: isDark 
                        ? AppColors.bgDarkSecondary 
                        : AppColors.bgLightSecondary,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        agent[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(agent),
                    trailing: const Icon(Iconsax.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageTransitions.fadeSlide(
                          builder: (_) => ChatScreen(initialAgent: agent),
                        ),
                      );
                    },
                  ),
                )),
            ],
          ),
        ),
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
    
    return Material(
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
    );
  }
}
