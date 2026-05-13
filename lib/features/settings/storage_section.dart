// ==================== Storage Methods ====================

Future<Map<String, int>> _getStorageBreakdown() async {
  return await AppDataManager.getStorageBreakdown();
}

void _showStorageDetails(BuildContext context, int cache, int messages, int attachments) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showSmoothBottomSheet(
    context: context,
    initialChildSize: 0.5,
    maxChildSize: 0.6,
    minChildSize: 0.35,
    snapSizes: const [0.35, 0.5, 0.6],
    animationDuration: const Duration(milliseconds: 200),
    builder: (context, scrollController) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speicherplatz',
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StorageDetailRow(
            icon: Iconsax.chat,
            label: 'Chats',
            size: messages,
          ),
          const SizedBox(height: AppSpacing.md),
          _StorageDetailRow(
            icon: Iconsax.attach_square,
            label: 'Anhänge',
            size: attachments,
          ),
          const SizedBox(height: AppSpacing.md),
          _StorageDetailRow(
            icon: Iconsax.cache,
            label: 'Cache',
            size: cache,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gesamt',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                StorageInfoService.formatBytes(cache + messages + attachments),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StorageDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int size;

  const _StorageDetailRow({
    required this.icon,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: AppTypography.body),
        ),
        Text(
          StorageInfoService.formatBytes(size),
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }
}

class _StorageUsageBar extends StatelessWidget {
  final int cacheSize;
  final int messagesSize;
  final int attachmentsSize;

  const _StorageUsageBar({
    required this.cacheSize,
    required this.messagesSize,
    required this.attachmentsSize,
  });

  @override
  Widget build(BuildContext context) {
    final total = cacheSize + messagesSize + attachmentsSize;
    if (total == 0) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (messagesSize > 0)
                    Expanded(
                      flex: messagesSize,
                      child: Container(color: AppColors.primary),
                    ),
                  if (attachmentsSize > 0)
                    Expanded(
                      flex: attachmentsSize,
                      child: Container(color: AppColors.secondary),
                    ),
                  if (cacheSize > 0)
                    Expanded(
                      flex: cacheSize,
                      child: Container(color: AppColors.info),
                    ),
                  // Empty space
                  if (total > 0 && messagesSize + attachmentsSize + cacheSize < total)
                    Expanded(
                      flex: total - messagesSize - attachmentsSize - cacheSize,
                      child: Container(color: Colors.grey.withOpacity(0.3)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(color: AppColors.primary, label: 'Chats'),
              _LegendItem(color: AppColors.secondary, label: 'Anhänge'),
              _LegendItem(color: AppColors.info, label: 'Cache'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
        ),
      ],
    );
  }
}

void _showClearCacheDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      title: Text(
        'Cache leeren?',
        style: TextStyle(color: isDark ? AppColors.textDark : AppColors.textLight),
      ),
      content: Text(
        'Dies entfernt temporäre Dateien. Ihre Chats und Anhänge bleiben erhalten.',
        style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () async {
            await StorageInfoService.clearCache();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache geleert')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
          child: const Text('Leeren', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showDeleteAllDataDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
      title: Row(
        children: [
          Icon(Iconsax.warning, color: AppColors.error, size: 24),
          const SizedBox(width: 8),
          Text(
            'Alle Daten löschen',
            style: TextStyle(color: AppColors.error),
          ),
        ],
      ),
      content: Text(
        'Dies löscht alle Chats, Anhänge und den Cache. Diese Aktion kann nicht rückgängig gemacht werden!',
        style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () async {
            await StorageInfoService.clearAll();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alle Daten gelöscht')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Löschen', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Future<void> _exportData(BuildContext context) async {
  final result = await AppDataManager.exportAllData();
  if (result != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exportiert')),
      );
    }
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export fehlgeschlagen')),
      );
    }
  }
}

Widget _buildAutoCleanupTile(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: const Icon(Iconsax.timer_1, color: AppColors.warning, size: 20),
    ),
    title: const Text('Automatisch leeren'),
    subtitle: const Text('Nach 30 Tagen'),
    trailing: const Icon(Iconsax.chevron_right),
    onTap: () => _showAutoCleanupSettings(context),
  );
}

void _showAutoCleanupSettings(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  String selectedPeriod = '30days';
  
  showSmoothBottomSheet(
    context: context,
    initialChildSize: 0.45,
    maxChildSize: 0.55,
    minChildSize: 0.35,
    snapSizes: const [0.35, 0.45, 0.55],
    animationDuration: const Duration(milliseconds: 200),
    builder: (context, scrollController) => StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: isDark ? AppColors.bgDarkSecondary : AppColors.bgLightSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automatisch leeren',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Daten automatisch nach diesem Zeitraum löschen:',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AutoCleanupOption(
              title: 'Nach 30 Tagen',
              subtitle: 'Alte Daten werden monatlich bereinigt',
              value: '30days',
              groupValue: selectedPeriod,
              onChanged: (v) => setSheetState(() => selectedPeriod = v),
            ),
            _AutoCleanupOption(
              title: 'Nach 90 Tagen',
              subtitle: 'Wöchentliche Bereinigung',
              value: '90days',
              groupValue: selectedPeriod,
              onChanged: (v) => setSheetState(() => selectedPeriod = v),
            ),
            _AutoCleanupOption(
              title: 'Nach 1 Jahr',
              subtitle: 'Monatliche Bereinigung',
              value: '1year',
              groupValue: selectedPeriod,
              onChanged: (v) => setSheetState(() => selectedPeriod = v),
            ),
            _AutoCleanupOption(
              title: 'Nie',
              subtitle: 'Daten manuell löschen',
              value: 'never',
              groupValue: selectedPeriod,
              onChanged: (v) => setSheetState(() => selectedPeriod = v),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auto-Cleanup Einstellung gespeichert')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Speichern', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AutoCleanupOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _AutoCleanupOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            Icon(
              isSelected ? Iconsax.check_circle : Iconsax.circle,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
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
          ],
        ),
      ),
    );
  }
}