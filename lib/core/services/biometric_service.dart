import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/logger.dart';

/// Service for handling biometric authentication (Face ID / Touch ID)
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Get the available biometric types on the device
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Get a human-readable name for the available biometric type
  static Future<String> getBiometricTypeName() async {
    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    
    return 'Biometrie';
  }

  /// Authenticate user with biometrics
  /// Returns true if authentication was successful
  static Future<bool> authenticateWithBiometric({
    String? reason,
    bool biometricOnly = false,
  }) async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authentifiziere dich für ClawChat',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      AppLogger.error('Biometric authentication error: ${e.message}', tag: 'BIOMETRIC');
      return false;
    }
  }

  /// Check if user has saved credentials and can use biometric login
  static Future<bool> hasStoredCredentials() async {
    return false;
  }
}
