import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';
import '../constants/typography.dart';

/// Service for centralized error handling across the app.
/// Provides snackbars, dialogs, and retry functionality.
class ErrorHandlerService {
  ErrorHandlerService._();

  /// Show a simple error snackbar
  static void showError(
    BuildContext context,
    String message, {
    String? details,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String actionLabel = 'OK',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTypography.body.copyWith(color: Colors.white),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        duration: duration,
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }

  /// Show a network-specific error
  static void showNetworkError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      customMessage ?? 'Netzwerkfehler',
      details: 'Bitte überprüfe deine Internetverbindung',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show an authentication error
  static void showAuthError(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onLogin,
  }) {
    showError(
      context,
      customMessage ?? 'Authentifizierung fehlgeschlagen',
      details: 'Bitte melde dich erneut an',
      actionLabel: onLogin != null ? 'Anmelden' : 'OK',
      onAction: onLogin,
    );
  }

  /// Show a timeout error
  static void showTimeoutError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'Zeitüberschreitung',
      details: 'Der Server hat nicht rechtzeitig geantwortet',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show a generic server error
  static void showServerError(
    BuildContext context, {
    int? statusCode,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'Server-Fehler',
      details: statusCode != null
          ? 'Fehler $statusCode - Bitte versuche es später erneut'
          : 'Bitte versuche es später erneut',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show a message-specific error (e.g., for chat messages)
  static void showMessageError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'Nachricht konnte nicht gesendet werden',
      details: 'Tippe auf "Erneut versuchen" um es nochmal zu versuchen',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show an agent connection error
  static void showAgentError(
    BuildContext context, {
    String? agentName,
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      agentName != null
          ? 'Agent "$agentName" Fehler'
          : 'Agent-Verbindung fehlgeschlagen',
      details: 'Verbindung zum Agenten konnte nicht hergestellt werden',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show a settings loading error
  static void showSettingsError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    showError(
      context,
      'Einstellungen konnten nicht geladen werden',
      details: 'Fehler beim Laden der App-Einstellungen',
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }

  /// Show a retry dialog for critical errors
  /// Returns true if user chose to retry
  static Future<bool> showRetryDialog(
    BuildContext context,
    String message, {
    String? details,
    String title = 'Fehler',
    String retryLabel = 'Erneut versuchen',
    String cancelLabel = 'Abbrechen',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDarkSecondary
            : AppColors.bgLightSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.h5.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDark
                    : AppColors.textLight,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                details,
                style: AppTypography.captionSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDarkSecondary
                      : AppColors.textLightSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelLabel,
              style: AppTypography.button.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
            child: Text(
              retryLabel,
              style: AppTypography.button,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Parse error to determine appropriate message
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Ein unbekannter Fehler ist aufgetreten';
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Zeitüberschreitung - Server antwortet nicht';
    } else if (errorStr.contains('unauthorized') ||
               errorStr.contains('401') ||
               errorStr.contains('token')) {
      return 'Authentifizierung fehlgeschlagen';
    } else if (errorStr.contains('network') ||
               errorStr.contains('socket') ||
               errorStr.contains('connection')) {
      return 'Netzwerkfehler - Bitte Internetverbindung prüfen';
    } else if (errorStr.contains('500') || errorStr.contains('server error')) {
      return 'Server-Fehler - Bitte später erneut versuchen';
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Ressource nicht gefunden';
    } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Zugriff verweigert';
    } else if (errorStr.contains('cancel') || errorStr.contains('aborted')) {
      return 'Vorgang abgebrochen';
    }
    
    return 'Ein Fehler ist aufgetreten';
  }

  /// Show error based on parsed error type
  static void showParsedError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final message = getErrorMessage(error);
    
    // Check if it's a network error
    final errorStr = error?.toString().toLowerCase() ?? '';
    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection')) {
      showNetworkError(context, onRetry: onRetry);
      return;
    }
    
    // Show generic error with parsed message
    showError(
      context,
      message,
      actionLabel: onRetry != null ? 'Erneut versuchen' : 'OK',
      onAction: onRetry,
    );
  }
}