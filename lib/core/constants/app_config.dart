class AppConfig {
  // Default values
  static const String appName = 'ClawChat';
  static const String appVersion = '1.0.0';
  
  // Default Gateway URL (can be changed in settings)
  static const String defaultGatewayUrl = 'localhost:18789';
  
  // WebSocket paths
  static const String wsPath = '/ws';
  
  // Storage keys
  static const String keyGatewayUrl = 'gateway_url';
  static const String keyGatewayToken = 'gateway_token';
  static const String keyUseBiometrics = 'use_biometrics';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingComplete = 'onboarding_complete';
  
  // Timeouts
  static const int connectionTimeoutSeconds = 10;
  static const int messageTimeoutSeconds = 30;
  
  // UI Constants
  static const int maxMessageLength = 10000;
  static const int messagePageSize = 50;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Auto-logout after 5 minutes of inactivity
  static const Duration autoLogoutDuration = Duration(minutes: 5);
}
