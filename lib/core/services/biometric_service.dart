import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric type enumeration for UI display
enum BiometricType {
  fingerprint,
  faceId,
  iris,
  none,
}

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
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.map((bio) {
        switch (bio) {
          case BiometricType.fingerprint:
          case BiometricType.strong:
            return BiometricType.fingerprint;
          case BiometricType.face:
            return BiometricType.faceId;
          case BiometricType.iris:
            return BiometricType.iris;
          default:
            return BiometricType.none;
        }
      }).toList();
    } on PlatformException {
      return [];
    }
  }

  /// Get a human-readable name for the available biometric type
  static Future<String> getBiometricTypeName() async {
    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint) ||
        availableBiometrics.contains(BiometricType.strong)) {
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
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  /// Check if user has saved credentials and can use biometric login
  static Future<bool> hasStoredCredentials() async {
    // This would check if we have stored gateway URL and token
    // Implementation depends on your secure storage setup
    return false;
  }
}
