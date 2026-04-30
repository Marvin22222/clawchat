import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';

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
              child: const Icon(Icons.link, color: AppColors.primary, size: 20),
            ),
            title: const Text('Gateway URL'),
            subtitle: Text(
              auth.gatewayUrl ?? 'Nicht verbunden',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18),
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
              child: const Icon(Icons.key, color: AppColors.secondary, size: 20),
            ),
            title: const Text('Access Token'),
            subtitle: Text(
              _showToken 
                  ? (auth.token?.isNotEmpty == true ? auth.token! : 'Nicht gesetzt')
                  : '••••••••••••••••',
              style: TextStyle(
                fontSize: 12,
                fontFamily: _showToken ? null : 'monospace',
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: IconButton(
              icon: Icon(_showToken ? Icons.visibility_off : Icons.visibility, size: 20),
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
                auth.isConnected ? Icons.cloud_done : Icons.cloud_off,
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
              child: const Icon(Icons.notifications, color: AppColors.primary, size: 20),
            ),
            title: const Text('Push-Benachrichtigungen'),
            subtitle: const Text('Neue Nachrichten melden'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
                debugPrint('Notification toggle: $value');
              },
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
                theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
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
              child: const Icon(Icons.palette, color: AppColors.warning, size: 20),
            ),
            title: const Text('Theme Farbe'),
            subtitle: Text(
              _getThemeName(theme.accentColor),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
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
              child: const Icon(Icons.fingerprint, color: AppColors.success, size: 20),
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
              child: const Icon(Icons.lock, color: AppColors.error, size: 20),
            ),
            title: const Text('Auto-Sperre'),
            subtitle: const Text('App nach 5 Min. Inaktivität sperren'),
            value: auth.useAutoLock ?? false,
            onChanged: (value) => auth.setUseAutoLock(value),
          },,

          const Divider(),

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
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            title: const Text('Standard Agent'),
            subtitle: Text(
              auth.selectedAgent ?? 'main',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
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
              child: const Icon(Icons.psychology, color: AppColors.info, size: 20),
            ),
            title: const Text('Verfügbare Agents'),
            subtitle: Text(
              '${auth.ws.availableAgents.length} Agents verfügbar',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to agents screen
              Navigator.pushNamed(context, '/agents');
            },
          ),

          const Divider(),

          // About Section
          _SectionHeader(title: 'Über'),
          
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          
          const ListTile(
            leading: Icon(Icons.code),
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
              child: const Icon(Icons.logout, color: AppColors.error, size: 20),
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
        content: TextField(
          controller: _gatewayUrlController,
          decoration: const InputDecoration(
            labelText: 'Gateway URL',
            hintText: 'https://gateway.example.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
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
                const SnackBar(content: Text('Gateway URL aktualisiert')),
              );
            },
            child: const Text('Speichern'),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ThemeColorOption(
                  color: AppColors.primary,
                  name: 'Indigo',
                  isSelected: theme.accentColor == AppColors.primary,
                  onTap: () {
                    theme.setAccentColor(AppColors.primary);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.blue,
                  name: 'Blau',
                  isSelected: theme.accentColor == Colors.blue,
                  onTap: () {
                    theme.setAccentColor(Colors.blue);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.purple,
                  name: 'Lila',
                  isSelected: theme.accentColor == Colors.purple,
                  onTap: () {
                    theme.setAccentColor(Colors.purple);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.pink,
                  name: 'Pink',
                  isSelected: theme.accentColor == Colors.pink,
                  onTap: () {
                    theme.setAccentColor(Colors.pink);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.red,
                  name: 'Rot',
                  isSelected: theme.accentColor == Colors.red,
                  onTap: () {
                    theme.setAccentColor(Colors.red);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.orange,
                  name: 'Orange',
                  isSelected: theme.accentColor == Colors.orange,
                  onTap: () {
                    theme.setAccentColor(Colors.orange);
                    Navigator.pop(context);
                  },
                ),
                _ThemeColorOption(
                  color: Colors.teal,
                  name: 'Teal',
                  isSelected: theme.accentColor == Colors.teal,
                  onTap: () {
                    theme.setAccentColor(Colors.teal);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showAgentSelector(BuildContext context, AuthProvider auth) {
    final agents = auth.ws.availableAgents;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
            if (agents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text('Keine Agents verfügbar'),
                ),
              )
            else
              ...agents.map((agent) => ListTile(
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
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                onTap: () {
                  auth.setSelectedAgent(agent);
                  Navigator.pop(context);
                },
              )),
            const SizedBox(height: AppSpacing.md),
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
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
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
}
