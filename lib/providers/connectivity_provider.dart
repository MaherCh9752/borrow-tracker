import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Provider that exposes device connectivity status to the widget tree.
/// Wraps [ConnectivityService] and notifies listeners on status changes.
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Starts monitoring connectivity.
  void initialize() {
    _service.initialize();
    _service.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
