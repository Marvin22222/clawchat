import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Anleitung'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _TipSection(
            title: '💬 Chatten',
            icon: Icons.chat,
            iconColor: AppColors.primary,
            tips: const [
              'Tippe unten auf das Textfeld, um eine Nachricht zu senden',
              'Halte den Sendebutton gedrückt für Sprachnachrichten',
              'Tippe auf eine Nachricht, um sie zu kopieren oder zu bearbeiten',
              'Wische nach links, um Nachrichten zu löschen',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '🤖 Agenten',
            icon: Icons.smart_toy,
            iconColor: AppColors.secondary,
            tips: const [
              'Wechsle Agenten über das Agenten-Menü oben rechts',
              'Coding Agent für Programmieraufgaben',
              'Research Agent für Recherchen und Analysen',
              'Main Agent für allgemeine Gespräche',
              'Speichere bevorzugte Agent-Konfigurationen als Presets',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '⚡ Schnellzugriff',
            icon: Iconsax.flash,
            iconColor: AppColors.warning,
            tips: const [
              'Doppel-tippen Sie auf den Bildschirm für Schnellaktionen',
              'Nutzen Sie die Schnellaktionen-Leiste für häufige Befehle',
              'Speichern Sie häufige Nachrichten als Vorlagen',
              'Lange Texte können mit Templates schnell eingefügt werden',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '📁 Dateien & Bilder',
            icon: Iconsax.image,
            iconColor: AppColors.info,
            tips: const [
              'Tippe auf das Büroklammer-Symbol, um Dateien anzuhängen',
              'Bilder werden automatisch komprimiert vor dem Senden',
              'Wähle die Bildqualität in den Einstellungen',
              'Exportiere Chats als PDF, JSON oder Text',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '🔔 Benachrichtigungen',
            icon: Iconsax.notification,
            iconColor: AppColors.success,
            tips: const [
              'Konfiguriere Push-Benachrichtigungen in den Einstellungen',
              'Setze Ruhezeiten für keine Störungen',
              'Teste Benachrichtigungen, um sicherzustellen, dass sie funktionieren',
              'Auto-Play für Sprachnachrichten aktivieren',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '🔒 Sicherheit',
            icon: Iconsax.lock,
            iconColor: AppColors.error,
            tips: const [
              'Aktiviere Face ID / Touch ID für schnellen Login',
              'Nutze Auto-Sperre für zusätzlichen Schutz',
              'Token wird sicher im verschlüsselten Speicher abgelegt',
              'Melde dich ab, wenn du das Gerät teilst',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TipSection(
            title: '🎨 Anpassung',
            icon: Iconsax.color_swatch,
            iconColor: AppColors.primary,
            tips: const [
              'Wähle zwischen Hell, Dunkel oder System-Theme',
              'Ändere die Akzentfarbe nach deinem Geschmack',
              'Verschiedene Theme-Stile verfügbar (OLED Black, Purple, Ocean...)',
              'Passe die Sprach-Empfindlichkeit für Voice Input an',
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _TipSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<String> tips;

  const _TipSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}