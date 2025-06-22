import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> init() async {
    try {
      // Get initial connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
      _connectivityController.add(_isConnected);

      debugPrint(
          'Initial connectivity: ${_isConnected ? 'Connected' : 'Disconnected'}');

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final wasConnected = _isConnected;
        _isConnected = results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);

        debugPrint(
            'Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}');

        // Only emit if status actually changed
        if (wasConnected != _isConnected) {
          _connectivityController.add(_isConnected);
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize connectivity service: $e');
      // Assume connected by default
      _isConnected = true;
      _connectivityController.add(true);
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}
