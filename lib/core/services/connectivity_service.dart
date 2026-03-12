import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Check connection
  Future<bool> checkConnection() async {
    // In a real app, use connectivity_plus package
    // For now, assume connected
    return true;
  }

  // Start monitoring
  void startMonitoring() {
    // Check every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final connected = await checkConnection();
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectionStatusController.add(connected);
      }
    });
  }

  // Stop monitoring
  void stopMonitoring() {
    _connectionStatusController.close();
  }
}

// Usage:
// final connectivity = ConnectivityService();
// connectivity.connectionStatus.listen((isConnected) {
//   print('Connection: $isConnected');
// });
