class AppLogger {
  static void debug(String message, {String? tag}) {
    _log('DEBUG', message, tag);
  }

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag);
  }

  static void warning(String message, {String? tag}) {
    _log('WARNING', message, tag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag);
    if (error != null) {
      _log('ERROR', 'Error: $error', tag);
    }
    if (stackTrace != null) {
      _log('ERROR', 'StackTrace: $stackTrace', tag);
    }
  }

  static void _log(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = tag != null ? '[$tag] ' : '';
    // In a real app, this would use a logging service
    print('$timestamp [$level] $prefix$message');
  }

  // WebSocket events
  static void wsConnected(String url) => info('WebSocket connected: $url', tag: 'WS');
  static void wsDisconnected() => info('WebSocket disconnected', tag: 'WS');
  static void wsMessage(dynamic message) => debug('WS Message: $message', tag: 'WS');
  static void wsError(dynamic error) => error('WS Error: $error', tag: 'WS');

  // Auth events
  static void loginSuccess(String gateway) => info('Login success: $gateway', tag: 'AUTH');
  static void loginFailed(String error) => warning('Login failed: $error', tag: 'AUTH');
  static void logout() => info('User logged out', tag: 'AUTH');

  // Chat events
  static void messageSent(String content) => debug('Message sent: ${content.substring(0, content.length > 50 ? 50 : content.length)}...', tag: 'CHAT');
  static void messageReceived(String content) => debug('Message received', tag: 'CHAT');
  static void agentSwitched(String agent) => info('Agent switched: $agent', tag: 'CHAT');

  // Error events
  static void networkError(String message) => error('Network error: $message', tag: 'NET');
  static void apiError(String endpoint, String message) => error('API error ($endpoint): $message', tag: 'API');
}
