import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Generate a simple hash of a string
  static String hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a short ID based on hash
  static String generateShortId(String input) {
    final hashValue = hash(input);
    return hashValue.substring(0, 8);
  }

  /// Validate if a string is a valid token format
  static bool isValidTokenFormat(String token) {
    // Basic validation - tokens usually start with a prefix
    return token.length >= 10 && token.length <= 200;
  }

  /// Mask a token for display (show only first and last 4 chars)
  static String maskToken(String token) {
    if (token.length <= 8) return token;
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  /// Generate a random session ID
  static String generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return generateShortId('session_$timestamp');
  }

  /// Generate a unique message ID
  static String generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecond.toString();
    return generateShortId('msg_${timestamp}_$random');
  }
}

class UrlUtils {
  /// Parse and validate a gateway URL
  static String parseGatewayUrl(String url) {
    // Remove trailing slashes
    var parsed = url.trim();
    while (parsed.endsWith('/')) {
      parsed = parsed.substring(0, parsed.length - 1);
    }
    
    // Add protocol if missing
    if (!parsed.startsWith('http://') && !parsed.startsWith('https://') && !parsed.startsWith('ws://') && !parsed.startsWith('wss://')) {
      parsed = 'http://$parsed';
    }
    
    return parsed;
  }

  /// Check if URL is local (localhost or IP)
  static bool isLocalUrl(String url) {
    return url.contains('localhost') || 
           url.contains('127.0.0.1') || 
           url.contains('192.168.') ||
           url.contains('10.') ||
           url.contains('.local');
  }

  /// Check if URL uses secure protocol
  static bool isSecureUrl(String url) {
    return url.startsWith('https://') || url.startsWith('wss://');
  }

  /// Get WebSocket URL from HTTP URL
  static String toWebSocketUrl(String httpUrl) {
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    } else if (httpUrl.startsWith('http://')) {
      return httpUrl.replaceFirst('http://', 'ws://');
    }
    return httpUrl;
  }
}
