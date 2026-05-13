import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';

/// A reusable error state widget that can be used throughout the app.
/// Shows an error icon, message, optional details, and a retry button.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool isDark;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Iconsax.close_circle,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Error message
            Text(
              message,
              style: AppTypography.h5.copyWith(
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                details!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              // Retry button
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                icon: const Icon(Iconsax.refresh, size: 20),
                label: Text(
                  'Erneut versuchen',
                  style: AppTypography.button,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact error state widget for inline errors (like in cards or list items)
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isDark;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.warning_2,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(
                Iconsax.refresh,
                color: AppColors.error,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              tooltip: 'Erneut versuchen',
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(
                Iconsax.close_circle,
                color: AppColors.error,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              tooltip: 'Schließen',
            ),
        ],
      ),
    );
  }
}

/// A wrapper that shows an error state when data fails to load
class ErrorStateWrapper<T> extends StatelessWidget {
  final T? data;
  final bool isLoading;
  final Object? error;
  final Widget Function(BuildContext context, T data) onData;
  final Widget Function(BuildContext context, Object error, VoidCallback? onRetry)? onError;
  final VoidCallback? onRetry;

  const ErrorStateWrapper({
    super.key,
    required this.data,
    required this.isLoading,
    this.error,
    required this.onData,
    this.onError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (error != null) {
      if (onError != null) {
        return onError!(context, error as Object, onRetry);
      }
      return ErrorStateWidget(
        message: 'Ein Fehler ist aufgetreten',
        details: error.toString(),
        onRetry: onRetry,
      );
    }

    if (data == null) {
      return const ErrorStateWidget(
        message: 'Keine Daten verfügbar',
        icon: Iconsax.info_circle,
      );
    }

    return onData(context, data as T);
  }
}