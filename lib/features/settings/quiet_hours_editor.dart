/// _QuietHoursEditor - Bottom sheet for editing quiet hours settings
class _QuietHoursEditor extends StatefulWidget {
  final ScrollController scrollController;

  const _QuietHoursEditor({required this.scrollController});

  @override
  State<_QuietHoursEditor> createState() => _QuietHoursEditorState();
}

class _QuietHoursEditorState extends State<_QuietHoursEditor> {
  bool _enabled = false;
  int _startHour = 22;
  int _endHour = 8;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NotificationSettingsService.getQuietHoursEnabled();
    final start = await NotificationSettingsService.getQuietHoursStart();
    final end = await NotificationSettingsService.getQuietHoursEnd();
    
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _startHour = start;
        _endHour = end;
        _isLoading = false;
      });
    }
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  void _showTimePicker({required bool isStartTime}) async {
    final initialHour = isStartTime ? _startHour : _endHour;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
    );

    if (picked != null) {
      if (isStartTime) {
        await NotificationSettingsService.setQuietHoursStart(picked.hour);
        setState(() => _startHour = picked.hour);
      } else {
        await NotificationSettingsService.setQuietHoursEnd(picked.hour);
        setState(() => _endHour = picked.hour);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: const Icon(Iconsax.moon, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Stummzeit',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enable toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Stummzeit aktivieren',
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                      subtitle: Text(
                        'In dieser Zeit keine Benachrichtigungen',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      value: _enabled,
                      onChanged: (value) async {
                        await NotificationSettingsService.setQuietHoursEnabled(value);
                        setState(() => _enabled = value);
                      },
                    ),

                    if (_enabled) ...[
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Time pickers
                      Text(
                        'Zeitfenster',
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeCard(
                              label: 'Start',
                              time: _formatHour(_startHour),
                              onTap: () => _showTimePicker(isStartTime: true),
                              isDark: isDark,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            child: Icon(
                              Iconsax.arrow_right_1,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                          Expanded(
                            child: _buildTimeCard(
                              label: 'Ende',
                              time: _formatHour(_endHour),
                              onTap: () => _showTimePicker(isStartTime: false),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Info
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Benachrichtigungen werden nur innerhalb des Zeitfensters unterdrückt.',
                                style: AppTypography.caption.copyWith(
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeCard({
    required String label,
    required String time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: isDark ? AppColors.borderLight : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Icon(
              Iconsax.edit_2,
              size: 16,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ],
        ),
      ),
    );
  }
}