import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          // Connection
          _SectionHeader(title: 'Verbindung'),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Gateway URL'),
            subtitle: Text(auth.gatewayUrl ?? 'Nicht verbunden'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Face ID / Touch ID'),
            subtitle: const Text('Schneller Login'),
            value: auth.useBiometrics,
            onChanged: (value) => auth.setUseBiometrics(value),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Abmelden', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),

          const Divider(),

          // Appearance
          _SectionHeader(title: 'Darstellung'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: theme.isDarkMode,
            onChanged: (value) => theme.setDarkMode(value),
          ),

          const Divider(),

          // About
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
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
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
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
