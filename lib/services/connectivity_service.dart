import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service that monitors device connectivity status.
/// Wraps [Connectivity] and exposes a reactive [isOnline] stream.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Current online status.
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes. Emits `true` when online, `false` when offline.
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Starts listening to connectivity changes.
  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (_isOnline != online) {
        _isOnline = online;
        _controller.add(online);
        debugPrint('[ConnectivityService] Status: ${online ? "online" : "offline"}');
      }
    });

    // Check initial status.
    _checkInitialStatus();
  }

  /// Checks the current connectivity and emits the initial value.
  Future<void> _checkInitialStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      _isOnline = online;
      _controller.add(online);
    } catch (e) {
      debugPrint('[ConnectivityService] Initial check failed: $e');
      _isOnline = true; // Assume online on error
      _controller.add(true);
    }
  }

  /// Disposes the stream and subscription.
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
