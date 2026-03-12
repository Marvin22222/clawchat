import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.openclaw.clawchat/biometric');

  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate({String reason = 'Bitte authentifizieren'}) async {
    try {
      final result = await _channel.invokeMethod<bool>('authenticate', {
        'reason': reason,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}

class BiometricService {
  static Future<bool> isBiometricAvailable() async {
    return await PlatformChannelService.isAvailable();
  }

  static Future<bool> authenticateWithBiometric({String? reason}) async {
    return await PlatformChannelService.authenticate(
      reason: reason ?? 'Authentifiziere dich für ClawChat',
    );
  }
}
