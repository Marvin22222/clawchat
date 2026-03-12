// Constants
class ApiConstants {
  // Gateway API endpoints
  static const String auth = '/api/auth';
  static const String message = '/api/message';
  static const String agents = '/api/agents';
  static const String sessions = '/api/sessions';
  static const String tasks = '/api/tasks';
  
  // WebSocket
  static const String ws = '/ws';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

// Message types
class MessageTypes {
  static const String text = 'text';
  static const String image = 'image';
  static const String file = 'file';
  static const String system = 'system';
}

// Agent types
class AgentTypes {
  static const String main = 'main';
  static const String coding = 'coding';
  static const String research = 'research';
  static const String writer = 'writer';
  static const String debugger = 'debugger';
}

// Task status
class TaskStatus {
  static const String pending = 'pending';
  static const String running = 'running';
  static const String completed = 'completed';
  static const String failed = 'failed';
}

// Theme constants
class ThemeConstants {
  static const String dark = 'dark';
  static const String light = 'light';
  static const String system = 'system';
}

// Storage keys
class StorageKeys {
  static const String gatewayUrl = 'gateway_url';
  static const String gatewayToken = 'gateway_token';
  static const String themeMode = 'theme_mode';
  static const String useBiometrics = 'use_biometrics';
  static const String onboardingComplete = 'onboarding_complete';
  static const String sessions = 'sessions';
  static const String messages = 'messages';
}

// Error codes
class ErrorCodes {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String connectionFailed = 'CONNECTION_FAILED';
  static const String timeout = 'TIMEOUT';
  static const String serverError = 'SERVER_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';
}
