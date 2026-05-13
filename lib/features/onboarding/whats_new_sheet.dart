import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/constants/app_config.dart';

class WhatsNewSheet extends StatelessWidget {
  final VoidCallback onClose;

  const WhatsNewSheet({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Icon(Iconsax.sparkle, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Was ist neu?',
                          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Version ${AppConfig.appVersion}',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Iconsax.close-circle),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Features list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  _NewFeatureItem(
                    icon: Iconsax.user_rounded,
                    iconColor: AppColors.primary,
                    title: 'Agent Management',
                    description: 'Wechsle zwischen verschiedenen Agents für unterschiedliche Aufgaben - Coding, Research und mehr!',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _NewFeatureItem(
                    icon: Iconsax.eye,
                    iconColor: AppColors.info,
                    title: 'Volle Transparenz',
                    description: 'Sieh alle Tool Calls and Denkprozesse des AI in Echtzeit.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _NewFeatureItem(
                    icon: Iconsax.messages_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Verbessertes Chat-Erlebnis',
                    description: 'Elegantes Interface mit Dark/Light Mode Support.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _NewFeatureItem(
                    icon: Iconsax.flash,
                    iconColor: AppColors.warning,
                    title: 'Performance Optimierungen',
                    description: 'Schnellere Ladezeiten und flüssigere Animationen.',
                  ),
                  SizedBox(height: AppSpacing.md),
                  _NewFeatureItem(
                    icon: Iconsax.lock,
                    iconColor: AppColors.error,
                    title: 'Sicherheit',
                    description: 'Face ID / Touch ID Support und Auto-Sperre.',
                  ),
                ],
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Weiter geht\'s!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewFeatureItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _NewFeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}