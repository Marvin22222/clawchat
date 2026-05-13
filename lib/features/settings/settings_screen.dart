import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/image_compression_service.dart';
import '../../core/services/notification_settings_service.dart';
import '../../core/services/theme_service.dart';
import '../chat/providers/lazy_notification_provider.dart';
import '../chat/templates/templates_widget.dart';
import '../../core/services/templates_service.dart';
import '../../models/message_template.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agent_presets_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../../widgets/animations/smooth_bottom_sheet.dart';
import '../../widgets/animations/skeleton_loaders.dart';
import '../agents/agents_screen.dart';
import '../notifications/notification_sheet.dart';
import 'chat_export_screen.dart';
import '../../core/services/storage_info_service.dart';
import '../../core/services/app_data_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _gatewayUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _showToken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      _gatewayUrlController.text = auth.gatewayUrl ?? '';
    });
  }

  @override
  void dispose() {
    _gatewayUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Connection Section
          _SectionHeader(title: 'Verbindung'),
          
          // Gateway URL
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.link, color: AppColors.primary, size: 20),
            ),
            title: const Text('Gateway URL'),
            subtitle: Text(
              auth.gatewayUrl ?? 'Nicht verbunden',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.edit, size: 18),
            onTap: () => _showGatewayUrlDialog(context, auth),
          ),
          
          // Token
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.key, color: AppColors.secondary, size: 20),
            ),
            title: const Text('Access Token'),
            subtitle: Text(
              _showToken 
                  ? (auth.token?.isNotEmpty == true ? auth.token! : 'Nicht gesetzt')
                  : '••••••••••••••••',
              style: AppTypography.caption.copyWith(
                fontFamily: _showToken ? null : 'monospace',
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: IconButton(
              icon: Icon(_showToken ? Iconsax.eye_off : Iconsax.eye, size: 20),
              onPressed: () => setState(() => _showToken = !_showToken),
            ),
            onTap: () => _showTokenDialog(context, auth),
          ),
          
          // Connection Status
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (auth.isConnected ? AppColors.success : AppColors.error).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                auth.isConnected ? Iconsax.cloud_done : Iconsax.cloud_no_update,
                color: auth.isConnected ? AppColors.success : AppColors.error,
                size: 20,
              ),
            ),
            title: const Text('Verbindungsstatus'),
            subtitle: Text(
              auth.isConnected ? 'Verbunden' : 'Nicht verbunden',
              style: AppTypography.label.copyWith(
                color: auth.isConnected ? AppColors.success : AppColors.error,
              ),
            ),
            trailing: auth.isConnected
                ? TextButton(
                    onPressed: () => auth.disconnect(),
                    child: const Text('Trennen'),
                  )
                : TextButton(
                    onPressed: () => auth.connect(),
                    child: const Text('Verbinden'),
                  ),
          ),
          
          // Notifications
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.notification, color: AppColors.primary, size: 20),
            ),
            title: const Text('Push-Benachrichtigungen'),
            subtitle: const Text('Neue Nachrichten melden'),
            trailing: Consumer<LazyNotificationProvider>(
              builder: (context, notif, _) => Switch(
                value: notif.isEnabled,
                onChanged: (value) {
                  notif.setEnabled(value);
                  HapticService.lightImpact();
                },
              ),
            ),
          ),
          
          // Sound & Vibration
          Consumer<LazyNotificationProvider>(
            builder: (context, notif, _) => Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: const Icon(Iconsax.speaker, color: AppColors.secondary, size: 20),
                  ),
                  title: const Text('Ton'),
                  trailing: Switch(
                    value: notif.soundEnabled,
                    onChanged: (value) {
                      notif.setSoundEnabled(value);
                      HapticService.lightImpact();
                    },
                  ),
                  onTap: () => notif.setSoundEnabled(!notif.soundEnabled),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: const Icon(Iconsax.mobile, color: AppColors.info, size: 20),
                  ),
                  title: const Text('Vibration'),
                  trailing: Switch(
                    value: notif.vibrationEnabled,
                    onChanged: (value) {
                      notif.setVibrationEnabled(value);
                      HapticService.lightImpact();
                    },
                  ),
                  onTap: () => notif.setVibrationEnabled(!notif.vibrationEnabled),
                ),
              ],
            ),
          ),
          
          // Quiet Hours
          _buildQuietHoursTile(context),
          
          // Quick Settings & Test
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.setting_2, color: AppColors.warning, size: 20),
            ),
            title: const Text('Schnelleinstellungen'),
            subtitle: const Text('Alle Benachrichtigungsoptionen'),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => NotificationQuickSheet.show(context),
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.notification_circle, color: AppColors.success, size: 20),
            ),
            title: const Text('Test-Benachrichtigung'),
            subtitle: const Text('Prüfen ob Benachrichtigungen funktionieren'),
            onTap: () => _sendTestNotification(context),
          ),

          const Divider(),

          // Appearance Section
          _SectionHeader(title: 'Darstellung'),
          
          // Theme Mode (Dark/Light/System)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                theme.useSystemTheme 
                    ? Iconsax.mobile 
                    : (theme.isDarkMode ? Iconsax.moon : Iconsax.sun_1),
                color: AppColors.info,
                size: 20,
              ),
            ),
            title: const Text('Theme Modus'),
            subtitle: Text(
              _getThemeModeName(theme),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showThemeModeSelector(context, theme),
          ),

          // Theme Type Selection
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.color_swatch, color: AppColors.warning, size: 20),
            ),
            title: const Text('Theme Stil'),
            subtitle: Text(
              theme.themeType.label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showThemeTypeSelector(context, theme),
          ),

          // Accent Color Selection
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(Iconsax.color_circle, color: theme.accentColor, size: 20),
            ),
            title: const Text('Akzent Farbe'),
            subtitle: Text(
              _getAccentColorName(theme.accentColor),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showAccentColorSelector(context, theme),
          ),

          const Divider(),

          // Security Section
          _SectionHeader(title: 'Sicherheit'),
          
          // Biometrics
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.finger_print, color: AppColors.success, size: 20),
            ),
            title: const Text('Face ID / Touch ID'),
            subtitle: const Text('Schneller Login mit Biometrie'),
            value: auth.useBiometrics,
            onChanged: (value) => auth.setUseBiometrics(value),
          ),
          
          // Auto-lock
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.lock, color: AppColors.error, size: 20),
            ),
            title: const Text('Auto-Sperre'),
            subtitle: Text(
              auth.autoLockMinutes != null
                  ? 'Nach ${auth.autoLockMinutes} Min. Inaktivität'
                  : 'Deaktiviert',
            ),
            value: auth.autoLockMinutes != null,
            onChanged: (value) => auth.setAutoLockMinutes(value ? 5 : null),
          ),
          
          // Auto-lock timeout selector
          if (auth.autoLockMinutes != null)
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16),
              child: DropdownButtonFormField<int>(
                value: auth.autoLockMinutes ?? 5,
                decoration: const InputDecoration(
                  labelText: 'Automatische Sperre nach',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 Minute')),
                  DropdownMenuItem(value: 5, child: Text('5 Minuten')),
                  DropdownMenuItem(value: 15, child: Text('15 Minuten')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    auth.setAutoLockMinutes(value);
                  }
                },
              ),
            ),
          ,

          // Voice Settings Section
          _SectionHeader(title: 'Sprache & Audio'),
          
          // Voice Input Mode
          Consumer<VoiceSettingsProvider>(
            builder: (context, voiceSettings, _) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  voiceSettings.inputMode == VoiceInputMode.pushToTalk
                      ? Iconsax.touch
                      : Iconsax.microphone,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text('Eingabemodus'),
              subtitle: Text(
                voiceSettings.inputMode.displayName,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showVoiceInputModeSelector(context, voiceSettings),
            ),
          ),
          
          // Transcription Language
          Consumer<VoiceSettingsProvider>(
            builder: (context, voiceSettings, _) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.translate, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Sprache für Transkription'),
              subtitle: Text(
                voiceSettings.transcriptionLanguageName,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showLanguageSelector(context, voiceSettings),
            ),
          ),
          
          // Voice Sensitivity
          Consumer<VoiceSettingsProvider>(
            builder: (context, voiceSettings, _) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.waves, color: AppColors.warning, size: 20),
              ),
              title: const Text('Sprach-Empfindlichkeit'),
              subtitle: Text(
                voiceSettings.sensitivityLabel,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showVoiceSensitivitySettings(context, voiceSettings),
            ),
          ),
          
          // Playback Speed
          Consumer<VoiceSettingsProvider>(
            builder: (context, voiceSettings, _) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.speedometer, color: AppColors.info, size: 20),
              ),
              title: const Text('Wiedergabe-Geschwindigkeit'),
              subtitle: Text(
                '${voiceSettings.playbackSpeed.toStringAsFixed(1)}x',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showPlaybackSpeedSelector(context, voiceSettings),
            ),
          ),
          
          // Auto-play Voice
          Consumer<VoiceSettingsProvider>(
            builder: (context, voiceSettings, _) => SwitchListTile(
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.play_circle, color: AppColors.success, size: 20),
              ),
              title: const Text('Auto-Play Sprachnachrichten'),
              subtitle: Text(
                voiceSettings.autoPlayVoice ? 'An' : 'Aus',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              value: voiceSettings.autoPlayVoice,
              onChanged: (value) => voiceSettings.setAutoPlayVoice(value),
            ),
          ),
          
          // Test Voice Message Button
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.microphone_none, color: AppColors.error, size: 20),
            ),
            title: const Text('Sprachnachricht testen'),
            subtitle: const Text('Aufnahme- und Wiedergabequalität prüfen'),
            onTap: () => _showVoiceTestDialog(context),
          ),

          const Divider();

          // Agent Settings Section
          _SectionHeader(title: 'Agent Einstellungen'),
          
          // Default Agent
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.robot, color: Colors.white, size: 20),
            ),
            title: const Text('Standard Agent'),
            subtitle: Text(
              auth.selectedAgent ?? 'main',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showAgentSelector(context, auth),
          ),
          
          // Agent Capabilities
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.global, color: AppColors.info, size: 20),
            ),
            title: const Text('Verfügbare Agents'),
            subtitle: Text(
              '${auth.ws.availableAgents.length} Agents verfügbar',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                AppPageTransitions.fadeSlide(
                  builder: (_) => const AgentsScreen(),
                ),
              );
            },
          ),

          // Agent Presets
          Consumer<AgentPresetsProvider>(
            builder: (context, presetsProvider, _) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.bookmark, color: AppColors.warning, size: 20),
              ),
              title: const Text('Agent Presets'),
              subtitle: Text(
                '${presetsProvider.presets.length} Preset(s) gespeichert',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showPresetsManager(context, presetsProvider, auth),
            ),
          ),

          const Divider(),

          // Media & Image Section
          _SectionHeader(title: 'Medien & Bilder'),
          
          // Image Quality
          FutureBuilder<ImageQualityPreset>(
            future: ImageCompressionService.getQualityPreset(),
            builder: (context, snapshot) {
              final preset = snapshot.data ?? ImageQualityPreset.medium;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Iconsax.image, color: AppColors.primary, size: 20),
                ),
                title: const Text('Bildqualität'),
                subtitle: Text(
                  preset.displayName,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
                trailing: const Icon(Iconsax.chevron_right),
                onTap: () => _showImageQualitySelector(context, preset),
              );
            },
          ),

          const Divider();

          // Data & Export Section
          _SectionHeader(title: 'Daten & Export'),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.cloud_download, color: AppColors.success, size: 20),
            ),
            title: const Text('Chat Export'),
            subtitle: const Text('Chats als JSON, Text oder PDF exportieren'),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                AppPageTransitions.fadeSlide(
                  builder: (_) => const ChatExportScreen(),
                ),
              );
            },
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.arrow_up_1, color: AppColors.info, size: 20),
            ),
            title: const Text('Alle Chats exportieren'),
            subtitle: const Text('Vollständiges Backup erstellen'),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showFullBackupDialog(context),
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.arrow_down_1, color: AppColors.warning, size: 20),
            ),
            title: const Text('Backup wiederherstellen'),
            subtitle: const Text('Aus Backup wiederherstellen'),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showRestoreBackupDialog(context),
          ),
          
          // Speicher Section
          _SectionHeader(title: 'Speicher'),
          
          FutureBuilder<Map<String, int>>(
            future: _getStorageBreakdown(),
            builder: (context, snapshot) {
              final total = snapshot.data?['total'] ?? 0;
              final cache = snapshot.data?['cache'] ?? 0;
              final messages = snapshot.data?['messages'] ?? 0;
              final attachments = snapshot.data?['attachments'] ?? 0;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Icon(Iconsax.database, color: AppColors.primary, size: 20),
                    ),
                    title: const Text('Speicherplatz'),
                    subtitle: Text(
                      '${StorageInfoService.formatBytes(total)} verwendet',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    trailing: const Icon(Iconsax.chevron_right),
                    onTap: () => _showStorageDetails(context, cache, messages, attachments),
                  ),
                  // Storage progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: _StorageUsageBar(
                      cacheSize: cache,
                      messagesSize: messages,
                      attachmentsSize: attachments,
                    ),
                  ),
                ],
              );
            },
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.trash, color: AppColors.info, size: 20),
            ),
            title: const Text('Cache leeren'),
            subtitle: const Text('Temporäre Dateien entfernen'),
            onTap: () => _showClearCacheDialog(context),
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.ban, color: AppColors.error, size: 20),
            ),
            title: const Text(
              'Alle Daten löschen',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Chats, Anhänge und Cache entfernen'),
            onTap: () => _showDeleteAllDataDialog(context),
          ),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.export, color: AppColors.success, size: 20),
            ),
            title: const Text('Daten exportieren'),
            subtitle: const Text('Vollständiges Backup als JSON'),
            onTap: () => _exportData(context),
          ),
          
          // Auto-Cleanup Settings
          _buildAutoCleanupTile(context),

          const Divider(),

          // Message Templates Section
          _SectionHeader(title: 'Nachrichten-Vorlagen'),
          
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.template, color: AppColors.primary, size: 20),
            ),
            title: const Text('Vorlagen verwalten'),
            subtitle: const Text('Schnellantworten und Textbausteine'),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showTemplatesManager(context),
          ),

          const Divider(),

          // About Section
          _SectionHeader(title: 'Über'),
          
          const ListTile(
            leading: Icon(Iconsax.info_circle),
            title: Text('Version'),
            subtitle: Text(AppStrings.appVersion),
          ),
          
          const ListTile(
            leading: Icon(Iconsax.code),
            title: Text('ClawChat'),
            subtitle: Text('OpenClaw iOS App'),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Icon(Iconsax.logout, color: AppColors.error, size: 20),
            ),
            title: const Text(
              'Abmelden',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Abmelden?'),
                  content: const Text('Möchtest du dich wirklich abmelden?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Abmelden',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              
              if (confirm == true && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _getThemeName(Color color) {
    return _getAccentColorName(color);
  }

  String _getAccentColorName(Color color) {
    if (color == AppColors.primary) return 'Indigo (Standard)';
    if (color == Colors.blue) return 'Blau';
    if (color == Colors.purple) return 'Lila';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.red) return 'Rot';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.teal) return 'Teal';
    return 'Indigo';
  }

  String _getThemeModeName(ThemeProvider theme) {
    if (theme.useSystemTheme) return 'System';
    return theme.isDarkMode ? 'Dunkel' : 'Hell';
  }

  void _showThemeModeSelector(BuildContext context, ThemeProvider theme) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.35,
      maxChildSize: 0.4,
      minChildSize: 0.3,
      snapSizes: const [0.3, 0.35, 0.4],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Modus',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            _ThemeModeOption(
              icon: Iconsax.mobile,
              name: 'System',
              description: 'Folgt dem iOS/Android System',
              isSelected: theme.useSystemTheme,
              onTap: () {
                theme.setUseSystemTheme(true);
                HapticService.lightImpact();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeModeOption(
              icon: Iconsax.moon,
              name: 'Dunkel',
              description: 'Immer dunkles Theme',
              isSelected: !theme.useSystemTheme && theme.isDarkMode,
              onTap: () {
                theme.setUseSystemTheme(false);
                theme.setDarkMode(true);
                HapticService.lightImpact();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ThemeModeOption(
              icon: Iconsax.sun_1,
              name: 'Hell',
              description: 'Immer helles Theme',
              isSelected: !theme.useSystemTheme && !theme.isDarkMode,
              onTap: () {
                theme.setUseSystemTheme(false);
                theme.setDarkMode(false);
                HapticService.lightImpact();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeTypeSelector(BuildContext context, ThemeProvider theme) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.7,
      minChildSize: 0.35,
      snapSizes: const [0.35, 0.5, 0.7],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Stil',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.2,
                children: [
                  _ThemeTypeOption(
                    type: AppThemeType.dark,
                    isSelected: theme.themeType == AppThemeType.dark,
                    onTap: () {
                      theme.setThemeType(AppThemeType.dark);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeTypeOption(
                    type: AppThemeType.oledBlack,
                    isSelected: theme.themeType == AppThemeType.oledBlack,
                    onTap: () {
                      theme.setThemeType(AppThemeType.oledBlack);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeTypeOption(
                    type: AppThemeType.purple,
                    isSelected: theme.themeType == AppThemeType.purple,
                    onTap: () {
                      theme.setThemeType(AppThemeType.purple);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeTypeOption(
                    type: AppThemeType.ocean,
                    isSelected: theme.themeType == AppThemeType.ocean,
                    onTap: () {
                      theme.setThemeType(AppThemeType.ocean);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeTypeOption(
                    type: AppThemeType.forest,
                    isSelected: theme.themeType == AppThemeType.forest,
                    onTap: () {
                      theme.setThemeType(AppThemeType.forest);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeTypeOption(
                    type: AppThemeType.sunset,
                    isSelected: theme.themeType == AppThemeType.sunset,
                    onTap: () {
                      theme.setThemeType(AppThemeType.sunset);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccentColorSelector(BuildContext context, ThemeProvider theme) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.6,
      minChildSize: 0.35,
      snapSizes: const [0.35, 0.5, 0.6],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akzent Farbe',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                children: [
                  _AccentColorOption(
                    color: AppColors.primary,
                    name: 'Indigo',
                    isSelected: theme.accentColor == AppColors.primary,
                    onTap: () {
                      theme.setAccentColor(AppColors.primary);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.blue,
                    name: 'Blau',
                    isSelected: theme.accentColor == Colors.blue,
                    onTap: () {
                      theme.setAccentColor(Colors.blue);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.purple,
                    name: 'Lila',
                    isSelected: theme.accentColor == Colors.purple,
                    onTap: () {
                      theme.setAccentColor(Colors.purple);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.pink,
                    name: 'Pink',
                    isSelected: theme.accentColor == Colors.pink,
                    onTap: () {
                      theme.setAccentColor(Colors.pink);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.red,
                    name: 'Rot',
                    isSelected: theme.accentColor == Colors.red,
                    onTap: () {
                      theme.setAccentColor(Colors.red);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.orange,
                    name: 'Orange',
                    isSelected: theme.accentColor == Colors.orange,
                    onTap: () {
                      theme.setAccentColor(Colors.orange);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.teal,
                    name: 'Teal',
                    isSelected: theme.accentColor == Colors.teal,
                    onTap: () {
                      theme.setAccentColor(Colors.teal);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _AccentColorOption(
                    color: Colors.green,
                    name: 'Grün',
                    isSelected: theme.accentColor == Colors.green,
                    onTap: () {
                      theme.setAccentColor(Colors.green);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    _gatewayUrlController.text = auth.gatewayUrl ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gateway URL ändern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _gatewayUrlController,
              decoration: const InputDecoration(
                labelText: 'Gateway URL',
                hintText: 'https://gateway.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tipp: Nach dem Ändern wird automatisch neu verbunden.',
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              auth.setGatewayUrl(_gatewayUrlController.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gateway URL aktualisiert - verbinde neu...')),
              );
              // Auto reconnect with new URL
              auth.connect();
            },
            child: const Text('Speichern & Verbinden'),
          ),
        ],
      ),
    );
  }

  void _showTokenDialog(BuildContext context, AuthProvider auth) {
    _tokenController.text = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Token ändern'),
        content: TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            labelText: 'Access Token',
            hintText: 'Dein Access Token',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (_tokenController.text.trim().isNotEmpty) {
                auth.setToken(_tokenController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token aktualisiert')),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider theme) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.6,
      minChildSize: 0.35,
      snapSizes: const [0.35, 0.5, 0.6],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Farbe',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                children: [
                  _ThemeColorOption(
                    color: AppColors.primary,
                    name: 'Indigo',
                    isSelected: theme.accentColor == AppColors.primary,
                    onTap: () {
                      theme.setAccentColor(AppColors.primary);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.blue,
                    name: 'Blau',
                    isSelected: theme.accentColor == Colors.blue,
                    onTap: () {
                      theme.setAccentColor(Colors.blue);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.purple,
                    name: 'Lila',
                    isSelected: theme.accentColor == Colors.purple,
                    onTap: () {
                      theme.setAccentColor(Colors.purple);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.pink,
                    name: 'Pink',
                    isSelected: theme.accentColor == Colors.pink,
                    onTap: () {
                      theme.setAccentColor(Colors.pink);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.red,
                    name: 'Rot',
                    isSelected: theme.accentColor == Colors.red,
                    onTap: () {
                      theme.setAccentColor(Colors.red);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.orange,
                    name: 'Orange',
                    isSelected: theme.accentColor == Colors.orange,
                    onTap: () {
                      theme.setAccentColor(Colors.orange);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  _ThemeColorOption(
                    color: Colors.teal,
                    name: 'Teal',
                    isSelected: theme.accentColor == Colors.teal,
                    onTap: () {
                      theme.setAccentColor(Colors.teal);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAgentSelector(BuildContext context, AuthProvider auth) {
    final agents = auth.ws.availableAgents;
    
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.7,
      minChildSize: 0.35,
      snapSizes: const [0.35, 0.5, 0.7],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Standard Agent wählen',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: agents.isEmpty
                  ? const Center(
                      child: Text('Keine Agents verfügbar'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: agents.length,
                      itemBuilder: (context, index) {
                        final agent = agents[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                            child: Center(
                              child: Text(
                                agent[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(agent),
                          trailing: auth.selectedAgent == agent
                              ? const Icon(Iconsax.tick_square_circle, color: AppColors.success)
                              : null,
                          onTap: () {
                            auth.setSelectedAgent(agent);
                            HapticService.lightImpact();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showFullBackupDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      title: Text(
        'Alle Chats exportieren',
        style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dies erstellt ein vollständiges Backup aller Chat-Nachrichten im JSON-Format.',
            style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Das Backup kann später über "Backup wiederherstellen" importiert werden.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDark : AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to ChatExportScreen with full export
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatExportScreen(),
              ),
            );
          },
          icon: const Icon(Iconsax.cloud_download, size: 18),
          label: const Text('Exportieren'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

void _showRestoreBackupDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      title: Text(
        'Backup wiederherstellen',
        style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.warning_2, color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Backup-Wiederherstellung wird in einer zukünftigen Version verfügbar sein.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Um ein Backup wiederherzustellen, benötigst du eine zuvor exportierte JSON-Datei.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showTemplatesManager(BuildContext context) {
  showSmoothBottomSheet(
    context: context,
    initialChildSize: 0.7,
    maxChildSize: 0.9,
    minChildSize: 0.5,
    snapSizes: const [0.5, 0.7, 0.9],
    animationDuration: const Duration(milliseconds: 200),
    builder: (context, scrollController) => _TemplatesManagerContent(
      scrollController: scrollController,
    ),
  );
}

class _TemplatesManagerContent extends StatefulWidget {
  final ScrollController scrollController;

  const _TemplatesManagerContent({required this.scrollController});

  @override
  State<_TemplatesManagerContent> createState() => _TemplatesManagerContentState();
}

class _TemplatesManagerContentState extends State<_TemplatesManagerContent> {
  List<MessageTemplate> _customTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await TemplatesService.getCustomTemplates();
    if (mounted) {
      setState(() {
        _customTemplates = templates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nachrichten-Vorlagen',
                  style: AppTypography.h4.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                IconButton(
                  icon: Icon(Iconsax.add_circle, color: AppColors.primary),
                  onPressed: () => _showAddTemplateDialog(),
                ),
              ],
            ),
          ),
          // Custom templates list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _customTemplates.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _customTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _customTemplates[index];
                          return _TemplateListItem(
                            template: template,
                            onEdit: () => _showEditTemplateDialog(template),
                            onDelete: () => _confirmDeleteTemplate(template),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.template,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine eigenen Vorlagen',
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: _showAddTemplateDialog,
            icon: const Icon(Iconsax.add),
            label: const Text('Vorlage erstellen'),
          ),
        ],
      ),
    );
  }

  void _showAddTemplateDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final shortcutController = TextEditingController();
    String selectedCategory = 'quick';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
          title: const Text('Neue Vorlage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'z.B. Begrüßung',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'quick', child: Text('Schnellantworten')),
                    DropdownMenuItem(value: 'code', child: Text('Code')),
                    DropdownMenuItem(value: 'links', child: Text('Links')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: shortcutController,
                  decoration: const InputDecoration(
                    labelText: 'Shortcut (optional, z.B. /hi)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt',
                    hintText: 'Vorlagen-Text hier eingeben...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                  return;
                }
                
                final template = MessageTemplate(
                  id: TemplatesService.generateId(),
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  shortcut: shortcutController.text.trim().isEmpty ? null : shortcutController.text.trim(),
                  isCustom: true,
                  category: selectedCategory,
                );
                
                await TemplatesService.saveTemplate(template);
                if (context.mounted) Navigator.pop(context);
                _loadTemplates();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Erstellen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTemplateDialog(MessageTemplate template) {
    final titleController = TextEditingController(text: template.title);
    final contentController = TextEditingController(text: template.content);
    final shortcutController = TextEditingController(text: template.shortcut ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        title: const Text('Vorlage bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: shortcutController,
                decoration: const InputDecoration(
                  labelText: 'Shortcut (z.B. /hello)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                return;
              }
              
              final updated = template.copyWith(
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                shortcut: shortcutController.text.trim().isEmpty ? null : shortcutController.text.trim(),
              );
              
              await TemplatesService.updateTemplate(updated);
              if (context.mounted) Navigator.pop(context);
              _loadTemplates();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTemplate(MessageTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vorlage löschen?'),
        content: Text('Möchtest du die Vorlage "${template.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await TemplatesService.deleteTemplate(template.id);
              if (context.mounted) Navigator.pop(context);
              _loadTemplates();
            },
            child: const Text('Löschen', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TemplateListItem extends StatelessWidget {
  final MessageTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateListItem({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon() {
    switch (template.category) {
      case 'code':
        return Iconsax.code;
      case 'links':
        return Iconsax.link_21;
      case 'custom':
        return Iconsax.star;
      default:
        return Iconsax.flash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(_getCategoryIcon(), color: AppColors.primary, size: 20),
        ),
        title: Text(
          template.title,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (template.shortcut != null)
              Text(
                template.shortcut!,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            Text(
              template.content.length > 50
                  ? '${template.content.substring(0, 50)}...'
                  : template.content,
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Iconsax.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Iconsax.trash, size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

void _showPresetsManager(BuildContext context, AgentPresetsProvider presetsProvider, AuthProvider auth) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      snapSizes: const [0.5, 0.7, 0.9],
      builder: (context, scrollController) => _PresetsManagerContent(
        presetsProvider: presetsProvider,
        auth: auth,
        scrollController: scrollController,
      ),
    );
  }

class _PresetsManagerContent extends StatelessWidget {
  final AgentPresetsProvider presetsProvider;
  final AuthProvider auth;
  final ScrollController scrollController;

  const _PresetsManagerContent({
    required this.presetsProvider,
    required this.auth,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agent Presets',
                  style: AppTypography.h4,
                ),
                IconButton(
                  icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
                  onPressed: () => _showPresetEditor(context, presetsProvider, auth),
                ),
              ],
            ),
          ),
          // Presets list
          Expanded(
            child: presetsProvider.isLoading
                ? const SettingsScreenSkeleton()
                : presetsProvider.presets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.bookmark_border,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Keine Presets vorhanden',
                              style: AppTypography.body.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton.icon(
                              onPressed: () => _showPresetEditor(context, presetsProvider, auth),
                              icon: const Icon(Iconsax.add),
                              label: const Text('Preset erstellen'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: presetsProvider.presets.length,
                        itemBuilder: (context, index) {
                          final preset = presetsProvider.presets[index];
                          final modelType = presetsProvider.getPresetModelType(preset);
                          return _PresetListItem(
                            preset: preset,
                            modelType: modelType,
                            onEdit: () => _showPresetEditor(context, presetsProvider, auth, preset: preset),
                            onDelete: () => _confirmDeletePreset(context, presetsProvider, preset),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

  void _showPresetEditor(
    BuildContext context, 
    AgentPresetsProvider presetsProvider, 
    AuthProvider auth, 
    {AgentPreset? preset}
  ) {
    final isEditing = preset != null;
    final nameController = TextEditingController(text: preset?.name ?? '');
    final promptController = TextEditingController(text: preset?.systemPrompt ?? '');
    String selectedAgent = preset?.agentId ?? auth.selectedAgent ?? 'main';
    ModelType selectedModel = presetsProvider.getPresetModelType(preset ?? AgentPreset(
      id: '', name: '', agentId: '', createdAt: DateTime.now(),
    ));

    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      snapSizes: const [0.6, 0.85, 0.95],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.bgDarkSecondary 
              : AppColors.bgLightSecondary,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  isEditing ? 'Preset bearbeiten' : 'Neues Preset',
                  style: AppTypography.h4,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Name field
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z.B. Code-Experte',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Agent selector
                DropdownButtonFormField<String>(
                  value: selectedAgent,
                  decoration: const InputDecoration(
                    labelText: 'Agent',
                    border: OutlineInputBorder(),
                  ),
                  items: auth.ws.availableAgents.map((agent) => DropdownMenuItem(
                    value: agent,
                    child: Text(agent),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => selectedAgent = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Model selector
                DropdownButtonFormField<ModelType>(
                  value: selectedModel,
                  decoration: const InputDecoration(
                    labelText: 'Modell',
                    border: OutlineInputBorder(),
                  ),
                  items: ModelType.values.map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model.displayName),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => selectedModel = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // System prompt
                TextField(
                  controller: promptController,
                  decoration: const InputDecoration(
                    labelText: 'System Prompt (optional)',
                    hintText: 'Spezielle Anweisungen für diesen Agent...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bitte gib einen Namen ein')),
                        );
                        return;
                      }
                      
                      if (isEditing) {
                        presetsProvider.updatePreset(
                          id: preset!.id,
                          name: nameController.text.trim(),
                          agentId: selectedAgent,
                          systemPrompt: promptController.text.trim().isEmpty 
                              ? null 
                              : promptController.text.trim(),
                          modelType: selectedModel,
                        );
                      } else {
                        presetsProvider.addPreset(
                          name: nameController.text.trim(),
                          agentId: selectedAgent,
                          systemPrompt: promptController.text.trim().isEmpty 
                              ? null 
                              : promptController.text.trim(),
                          modelType: selectedModel,
                        );
                      }
                      Navigator.pop(context);
                      HapticService.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text(
                      isEditing ? 'Speichern' : 'Erstellen',
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeletePreset(BuildContext context, AgentPresetsProvider presetsProvider, AgentPreset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preset löschen?'),
        content: Text('Möchtest du das Preset "${preset.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              presetsProvider.deletePreset(preset.id);
              Navigator.pop(context);
            },
            child: const Text('Löschen', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

class _PresetListItem extends StatelessWidget {
  final AgentPreset preset;
  final ModelType modelType;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresetListItem({
    required this.preset,
    required this.modelType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: const Icon(Iconsax.bookmark, color: Colors.white, size: 20),
        ),
        title: Text(
          preset.name,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agent: ${preset.agentId}'),
            Text(
              'Modell: ${modelType.displayName}',
              style: AppTypography.captionSmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            if (preset.systemPrompt != null && preset.systemPrompt!.isNotEmpty)
              Text(
                preset.systemPrompt!.length > 50 
                    ? '${preset.systemPrompt!.substring(0, 50)}...' 
                    : preset.systemPrompt!,
                style: AppTypography.captionSmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Iconsax.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Iconsax.trash, size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

  void _showImageQualitySelector(BuildContext context, ImageQualityPreset currentPreset) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.4,
      maxChildSize: 0.5,
      minChildSize: 0.3,
      snapSizes: const [0.3, 0.4, 0.5],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bildqualität',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  _ImageQualityOption(
                    preset: ImageQualityPreset.high,
                    isSelected: currentPreset == ImageQualityPreset.high,
                    onTap: () async {
                      await ImageCompressionService.setQualityPreset(ImageQualityPreset.high);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                      setState(() {}); // Refresh to update UI
                    },
                  ),
                  _ImageQualityOption(
                    preset: ImageQualityPreset.medium,
                    isSelected: currentPreset == ImageQualityPreset.medium,
                    onTap: () async {
                      await ImageCompressionService.setQualityPreset(ImageQualityPreset.medium);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  _ImageQualityOption(
                    preset: ImageQualityPreset.low,
                    isSelected: currentPreset == ImageQualityPreset.low,
                    onTap: () async {
                      await ImageCompressionService.setQualityPreset(ImageQualityPreset.low);
                      HapticService.lightImpact();
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageQualityOption extends StatelessWidget {
  final ImageQualityPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImageQualityOption({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String subtitle;
    switch (preset) {
      case ImageQualityPreset.high:
        subtitle = 'Max. ${preset.maxSizeKb ~/ 1024}MB, ${preset.maxDimension}px';
        break;
      case ImageQualityPreset.medium:
        subtitle = 'Max. ${preset.maxSizeKb}KB, ${preset.maxDimension}px';
        break;
      case ImageQualityPreset.low:
        subtitle = 'Max. ${preset.maxSizeKb}KB, ${preset.maxDimension}px';
        break;
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.surfaceDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Icon(
          Iconsax.image,
          color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          size: 20,
        ),
      ),
      title: Text(preset.displayName),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Iconsax.tick_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.label.copyWith(
          letterSpacing: 1,
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
        ),
      ),
    );
  }
}

class _ThemeColorOption extends StatelessWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeColorOption({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Iconsax.tick_square, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTypography.captionSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeOption({
    required this.icon,
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1) 
              : (isDark ? AppColors.bgDarkTertiary : AppColors.bgLightTertiary),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.2) 
                    : (isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Iconsax.tick_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ThemeTypeOption extends StatelessWidget {
  final AppThemeType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTypeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  Color get _backgroundColor {
    switch (type) {
      case AppThemeType.oledBlack:
        return Colors.black;
      case AppThemeType.purple:
        return const Color(0xFF1A1025);
      case AppThemeType.ocean:
        return const Color(0xFF0A1628);
      case AppThemeType.forest:
        return const Color(0xFF0A1A0A);
      case AppThemeType.sunset:
        return const Color(0xFF1A1010);
      default:
        return const Color(0xFF0D0D0D);
    }
  }

  Color get _accentColor {
    switch (type) {
      case AppThemeType.oledBlack:
        return const Color(0xFF10A37F);
      case AppThemeType.purple:
        return const Color(0xFF9333EA);
      case AppThemeType.ocean:
        return const Color(0xFF0EA5E9);
      case AppThemeType.forest:
        return const Color(0xFF22C55E);
      case AppThemeType.sunset:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10A37F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(Iconsax.tick_square, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Iconsax.check_circle, color: _accentColor, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentColorOption extends StatelessWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentColorOption({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Iconsax.tick_square, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTypography.captionSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceSensitivitySheet extends StatefulWidget {
  const _VoiceSensitivitySheet();

  @override
  State<_VoiceSensitivitySheet> createState() => _VoiceSensitivitySheetState();
}

class _VoiceSensitivitySheetState extends State<_VoiceSensitivitySheet> {
  double _sensitivity = 0.7;

  String _getSensitivityLabel(double value) {
    if (value < 0.3) return 'Niedrig';
    if (value < 0.7) return 'Mittel';
    return 'Hoch';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Sprach-Empfindlichkeit',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pausen-Dauer: ${(_sensitivity * 3).toStringAsFixed(1)} Sekunden',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Slider(
            value: _sensitivity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: _getSensitivityLabel(_sensitivity),
            onChanged: (value) {
              setState(() => _sensitivity = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Niedrig', style: AppTypography.caption.copyWith(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
              Text('Mittel', style: AppTypography.caption.copyWith(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
              Text('Hoch', style: AppTypography.caption.copyWith(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.info_circle, color: AppColors.info, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Was wird angepasst:',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• Pausendauer (wann Spracherkennung stoppt)\n• Hörzeit (maximale Aufnahmedauer)\n• Empfindlichkeit für leise Sprache',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sprach-Empfindlichkeit gespeichert'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text('Speichern', style: AppTypography.button.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<bool>(
      future: NotificationSettingsService.getQuietHoursEnabled(),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        
        return FutureBuilder<String>(
          future: NotificationSettingsService.getQuietHoursStatus(),
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data ?? '';
            
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(Iconsax.moon, color: AppColors.warning, size: 20),
              ),
              title: const Text('Stummzeit'),
              subtitle: Text(
                enabled ? status : 'Aus',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: Switch(
                value: enabled,
                onChanged: (value) async {
                  await NotificationSettingsService.setQuietHoursEnabled(value);
                  HapticService.lightImpact();
                  setState(() {}); // Refresh
                },
              ),
              onTap: () => _showQuietHoursEditor(context),
            );
          },
        );
      },
    );
  }

  void _showQuietHoursEditor(BuildContext context) {
    showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.5,
      maxChildSize: 0.65,
      minChildSize: 0.35,
      snapSizes: const [0.35, 0.5, 0.65],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => _QuietHoursEditor(
        scrollController: scrollController,
      ),
    );
  }

  void _sendTestNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test-Benachrichtigung gesendet!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

void _showVoiceSensitivitySettings(BuildContext context) {
  showSmoothBottomSheet(
    context: context,
    initialChildSize: 0.55,
    maxChildSize: 0.7,
    minChildSize: 0.4,
    snapSizes: const [0.4, 0.55, 0.7],
    animationDuration: const Duration(milliseconds: 200),
    builder: (context, scrollController) => const _VoiceSensitivitySheet(),
  );
}