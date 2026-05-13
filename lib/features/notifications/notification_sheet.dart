import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/typography.dart';
import '../../core/services/notification_settings_service.dart';
import '../../widgets/animations/smooth_bottom_sheet.dart';

/// NotificationQuickSheet - Bottom sheet for quick notification settings
/// 
/// Provides a convenient way to toggle notification settings without
/// navigating to the full settings screen.
class NotificationQuickSheet extends StatefulWidget {
  const NotificationQuickSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showSmoothBottomSheet(
      context: context,
      initialChildSize: 0.55,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      snapSizes: const [0.4, 0.55, 0.8],
      animationDuration: const Duration(milliseconds: 200),
      builder: (context, scrollController) => const NotificationQuickSheet(),
    );
  }

  @override
  State<NotificationQuickSheet> createState() => _NotificationQuickSheetState();
}

class _NotificationQuickSheetState extends State<NotificationQuickSheet> {
  // Settings state
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _agentOnly = false;
  bool _quietHoursEnabled = false;
  int _quietHoursStart = 22;
  int _quietHoursEnd = 8;

  bool _isInQuietHours = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifEnabled = await NotificationSettingsService.getNotificationsEnabled();
    final soundEnabled = await NotificationSettingsService.getSoundEnabled();
    final vibrationEnabled = await NotificationSettingsService.getVibrationEnabled();
    final agentOnly = await NotificationSettingsService.getAgentOnly();
    final quietEnabled = await NotificationSettingsService.getQuietHoursEnabled();
    final quietStart = await NotificationSettingsService.getQuietHoursStart();
    final quietEnd = await NotificationSettingsService.getQuietHoursEnd();
    final inQuiet = await NotificationSettingsService.isInQuietHours();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifEnabled;
        _soundEnabled = soundEnabled;
        _vibrationEnabled = vibrationEnabled;
        _agentOnly = agentOnly;
        _quietHoursEnabled = quietEnabled;
        _quietHoursStart = quietStart;
        _quietHoursEnd = quietEnd;
        _isInQuietHours = inQuiet;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationsEnabled(bool value) async {
    await NotificationSettingsService.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _updateSoundEnabled(bool value) async {
    await NotificationSettingsService.setSoundEnabled(value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _updateVibrationEnabled(bool value) async {
    await NotificationSettingsService.setVibrationEnabled(value);
    setState(() => _vibrationEnabled = value);
  }

  Future<void> _updateAgentOnly(bool value) async {
    await NotificationSettingsService.setAgentOnly(value);
    setState(() => _agentOnly = value);
  }

  Future<void> _updateQuietHoursEnabled(bool value) async {
    await NotificationSettingsService.setQuietHoursEnabled(value);
    setState(() => _quietHoursEnabled = value);
    _checkQuietHours();
  }

  Future<void> _checkQuietHours() async {
    final inQuiet = await NotificationSettingsService.isInQuietHours();
    if (mounted) {
      setState(() => _isInQuietHours = inQuiet);
    }
  }

  void _showTimePicker({required bool isStartTime}) async {
    final initialHour = isStartTime ? _quietHoursStart : _quietHoursEnd;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.bgDarkSecondary
                  : AppColors.bgLightSecondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isStartTime) {
        await NotificationSettingsService.setQuietHoursStart(picked.hour);
        setState(() => _quietHoursStart = picked.hour);
      } else {
        await NotificationSettingsService.setQuietHoursEnd(picked.hour);
        setState(() => _quietHoursEnd = picked.hour);
      }
      _checkQuietHours();
    }
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Iconsax.notification, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benachrichtigungen',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      if (_isInQuietHours)
                        Text(
                          'Stummzeit aktiv',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        )
                      else if (!_notificationsEnabled)
                        Text(
                          'Deaktiviert',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
                // Quick toggle
                Switch(
                  value: _notificationsEnabled,
                  onChanged: _updateNotificationsEnabled,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    // Sound toggle
                    _buildToggleRow(
                      icon: Iconsax.speaker,
                      title: 'Ton',
                      subtitle: _soundEnabled ? 'An' : 'Aus',
                      iconColor: AppColors.primary,
                      value: _soundEnabled,
                      onChanged: _updateSoundEnabled,
                      enabled: _notificationsEnabled,
                      isDark: isDark,
                    ),
                    
                    // Vibration toggle
                    _buildToggleRow(
                      icon: Iconsax.mobile,
                      title: 'Vibration',
                      subtitle: _vibrationEnabled ? 'An' : 'Aus',
                      iconColor: AppColors.secondary,
                      value: _vibrationEnabled,
                      onChanged: _updateVibrationEnabled,
                      enabled: _notificationsEnabled,
                      isDark: isDark,
                    ),

                    const Divider(height: 32, indent: 56),

                    // Agent only toggle
                    _buildToggleRow(
                      icon: Iconsax.robot,
                      title: 'Nur Agent-Nachrichten',
                      subtitle: _agentOnly ? 'Agent meldet nur eigene Nachrichten' : 'Alle Benachrichtigungen',
                      iconColor: AppColors.info,
                      value: _agentOnly,
                      onChanged: _updateAgentOnly,
                      enabled: _notificationsEnabled,
                      isDark: isDark,
                    ),

                    const Divider(height: 32, indent: 56),

                    // Quiet hours section
                    _buildToggleRow(
                      icon: Iconsax.moon,
                      title: 'Stummzeit',
                      subtitle: _quietHoursEnabled
                          ? '${_formatHour(_quietHoursStart)} – ${_formatHour(_quietHoursEnd)}'
                          : 'Aus',
                      iconColor: AppColors.warning,
                      value: _quietHoursEnabled,
                      onChanged: _updateQuietHoursEnabled,
                      enabled: _notificationsEnabled,
                      isDark: isDark,
                    ),

                    // Quiet hours time pickers
                    if (_quietHoursEnabled && _notificationsEnabled)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 56,
                          right: AppSpacing.md,
                          top: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimePickerButton(
                                label: 'Start',
                                time: _formatHour(_quietHoursStart),
                                onTap: () => _showTimePicker(isStartTime: true),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildTimePickerButton(
                                label: 'Ende',
                                time: _formatHour(_quietHoursEnd),
                                onTap: () => _showTimePicker(isStartTime: false),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpacing.md),

                    // Test notification button
                    if (_notificationsEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showTestNotification,
                            icon: const Icon(Iconsax.notification_circle, size: 20),
                            label: const Text('Test-Benachrichtigung'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                                horizontal: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool enabled,
    required bool isDark,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerButton({
    required String label,
    required String time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isDark ? AppColors.borderLight : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            Row(
              children: [
                Text(
                  time,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Iconsax.edit_2,
                  size: 14,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test-Benachrichtigung gesendet!'),
        duration: Duration(seconds: 2),
      ),
    );
    // In a real app, this would trigger a test notification via NotificationService
  }
}