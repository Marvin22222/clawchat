import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/haptic_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/agent_presets_provider.dart';
import '../../widgets/animations/app_transitions.dart';
import '../../widgets/animations/smooth_bottom_sheet.dart';
import '../../widgets/animations/skeleton_loaders.dart';
import '../agents/agents_screen.dart';
import 'chat_export_screen.dart';

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
              style: TextStyle(
                color: auth.isConnected ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
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
            trailing: Consumer<NotificationService>(
              builder: (context, notif, _) => Switch(
                value: notif.isEnabled,
                onChanged: (value) {
                  notif.setEnabled(value);
                  HapticService.lightImpact();
                },
              ),
            ),
          ),

          const Divider(),

          // Appearance Section
          _SectionHeader(title: 'Darstellung'),
          
          // Dark Mode
          SwitchListTile(
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(
                theme.isDarkMode ? Iconsax.moon : Iconsax.sun_1,
                color: AppColors.info,
                size: 20,
              ),
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              theme.isDarkMode ? 'Dunkles Theme aktiviert' : 'Helles Theme aktiviert',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            value: theme.isDarkMode,
            onChanged: (value) => theme.setDarkMode(value),
          ),

          // Theme Selection
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
            title: const Text('Theme Farbe'),
            subtitle: Text(
              _getThemeName(theme.accentColor),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Iconsax.chevron_right),
            onTap: () => _showThemeSelector(context, theme),
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
            subtitle: const Text('App nach 5 Min. Inaktivität sperren'),
            value: auth.useAutoLock ?? false,
            onChanged: (value) => auth.setUseAutoLock(value),
          ),

          const Divider();

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
                style: TextStyle(
                  fontSize: 12,
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
                style: TextStyle(
                  fontSize: 12,
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
                style: TextStyle(
                  fontSize: 12,
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
                style: TextStyle(
                  fontSize: 12,
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
                style: TextStyle(
                  fontSize: 12,
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
              style: TextStyle(
                fontSize: 12,
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
              style: TextStyle(
                fontSize: 12,
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
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ),
              trailing: const Icon(Iconsax.chevron_right),
              onTap: () => _showPresetsManager(context, presetsProvider, auth),
            ),
          ),

          const Divider(),

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
    if (color == AppColors.primary) return 'Indigo (Standard)';
    if (color == Colors.blue) return 'Blau';
    if (color == Colors.purple) return 'Lila';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.red) return 'Rot';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.teal) return 'Teal';
    return 'Indigo';
  }

  void _showGatewayUrlDialog(BuildContext context, AuthProvider auth) {
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
              style: TextStyle(
                fontSize: 12,
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
            const Text(
              'Theme Farbe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
            const Text(
              'Standard Agent wählen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                const Text(
                  'Agent Presets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                      style: const TextStyle(color: Colors.white),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agent: ${preset.agentId}'),
            Text(
              'Modell: ${modelType.displayName}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            if (preset.systemPrompt != null && preset.systemPrompt!.isNotEmpty)
              Text(
                preset.systemPrompt!.length > 50 
                    ? '${preset.systemPrompt!.substring(0, 50)}...' 
                    : preset.systemPrompt!,
                style: TextStyle(
                  fontSize: 11,
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
          letterSpacing: 1,
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
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Pausen-Dauer: ${(_sensitivity * 3).toStringAsFixed(1)} Sekunden',
            style: TextStyle(
              fontSize: 14,
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
              Text('Niedrig', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 12)),
              Text('Mittel', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 12)),
              Text('Hoch', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary, fontSize: 12)),
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
                      style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 12,
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
              child: const Text('Speichern', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
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
