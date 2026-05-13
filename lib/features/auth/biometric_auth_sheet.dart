import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/biometric_service.dart';

enum BiometricAuthState {
  idle,
  authenticating,
  success,
  failed,
}

class BiometricAuthSheet extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onCancel;

  const BiometricAuthSheet({
    super.key,
    required this.onAuthenticated,
    required this.onCancel,
  });

  @override
  State<BiometricAuthSheet> createState() => _BiometricAuthSheetState();
}

class _BiometricAuthSheetState extends State<BiometricAuthSheet>
    with SingleTickerProviderStateMixin {
  BiometricAuthState _state = BiometricAuthState.idle;
  String _biometricTypeName = 'Biometrie';
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometricType();
    _setupAnimations();
    // Auto-start authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
  }

  Future<void> _checkBiometricType() async {
    final typeName = await BiometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricTypeName = typeName;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _state = BiometricAuthState.authenticating;
      _errorMessage = null;
    });

    final authenticated = await BiometricService.authenticateWithBiometric(
      reason: 'Authentifiziere dich für ClawChat',
    );

    if (!mounted) return;

    setState(() {
      if (authenticated) {
        _state = BiometricAuthState.success;
        _animationController.forward();
        // Wait for animation then callback
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onAuthenticated();
          }
        });
      } else {
        _state = BiometricAuthState.failed;
        _errorMessage = 'Authentifizierung fehlgeschlagen';
      }
    });
  }

  Future<void> _retry() async {
    setState(() {
      _state = BiometricAuthState.idle;
      _errorMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 100));
    _authenticate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getBiometricIcon() {
    if (_biometricTypeName == 'Face ID') {
      return Icons.face;
    } else if (_biometricTypeName == 'Touch ID') {
      return Icons.fingerprint;
    }
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textDarkSecondary.withOpacity(0.3)
                    : AppColors.textLightSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Biometric icon with animation
            _buildBiometricIcon(),

            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              _getSubtitle(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            // Buttons
            if (_state == BiometricAuthState.failed) ...[
              // Retry button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onCancel,
                child: const Text('Abbrechen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_state == BiometricAuthState.success) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 60,
                ),
              ),
            ),
          );
        },
      );
    }

    if (_state == BiometricAuthState.failed) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cancel,
          color: AppColors.error,
          size: 60,
        ),
      );
    }

    if (_state == BiometricAuthState.authenticating) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Idle state - pulsing icon
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBiometricIcon(),
              color: AppColors.primary,
              size: 50,
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (_state) {
      case BiometricAuthState.idle:
      case BiometricAuthState.authenticating:
        return 'Authentifizierung';
      case BiometricAuthState.success:
        return 'Erfolgreich!';
      case BiometricAuthState.failed:
        return 'Fehlgeschlagen';
    }
  }

  String _getSubtitle() {
    switch (_state) {
      case BiometricAuthState.idle:
      case BiometricAuthState.authenticating:
        return 'Authentifiziere dich mit $_biometricTypeName';
      case BiometricAuthState.success:
        return 'Zugriff gewährt';
      case BiometricAuthState.failed:
        return 'Bitte versuche es erneut';
    }
  }
}

/// Show the biometric auth as a bottom sheet
Future<bool> showBiometricAuthSheet(BuildContext context) async {
  bool authenticated = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => BiometricAuthSheet(
      onAuthenticated: () {
        authenticated = true;
        Navigator.pop(context);
      },
      onCancel: () {
        authenticated = false;
        Navigator.pop(context);
      },
    ),
  );

  return authenticated;
}