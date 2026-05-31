import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/biometric_service.dart';
import '../utils/constants.dart';

/// Manages app lock state and biometric authentication.
class SecurityProvider extends ChangeNotifier {
  final BiometricService _biometricService = BiometricService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _appLockEnabled = false;
  bool _isLocked = true;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  bool _pendingLock = false;
  BiometricAvailability? _availability;

  bool get appLockEnabled => _appLockEnabled;
  bool get isLocked => _isLocked;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  BiometricAvailability? get availability => _availability;

  /// Initializes security state from secure storage and checks biometric availability.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Load saved preference.
    final savedValue = await _secureStorage.read(
      key: AppConstants.secureStorageAppLockKey,
    );
    _appLockEnabled = savedValue == 'true';

    // Check biometric availability.
    _availability = await _biometricService.checkAvailability();

    // If app lock is enabled but biometrics unavailable, disable it.
    if (_appLockEnabled && !(_availability?.isAvailable ?? false)) {
      _appLockEnabled = false;
      await _secureStorage.delete(key: AppConstants.secureStorageAppLockKey);
      debugPrint('[Security] App lock auto-disabled: biometrics unavailable');
    }

    // On first load, show lock screen if app lock is enabled.
    _isLocked = _appLockEnabled;

    _isLoading = false;
    notifyListeners();
  }

  /// Enables app lock after successful biometric authentication.
  Future<bool> enableLock() async {
    debugPrint('[Security] enableLock called. Availability: isAvailable=${_availability?.isAvailable}, hasHardware=${_availability?.hasHardware}, hasEnrolled=${_availability?.hasEnrolled}');

    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to enable app lock',
    );

    debugPrint('[Security] enableLock authenticate result: $authenticated');
    if (!authenticated) return false;

    _appLockEnabled = true;
    _isLocked = false; // Already just authenticated
    await _secureStorage.write(
      key: AppConstants.secureStorageAppLockKey,
      value: 'true',
    );
    notifyListeners();
    return true;
  }

  /// Disables app lock after successful biometric authentication.
  Future<bool> disableLock() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Authenticate to disable app lock',
    );

    if (!authenticated) return false;

    _appLockEnabled = false;
    _isLocked = false;
    await _secureStorage.delete(key: AppConstants.secureStorageAppLockKey);
    notifyListeners();
    return true;
  }

  /// Attempts to unlock the app with biometrics.
  Future<bool> unlock() async {
    _isAuthenticating = true;
    try {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        _isLocked = false;
        notifyListeners();
      }
      return authenticated;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Called when the app is about to go to background.
  /// Sets a flag so we lock on next resume.
  void onAppPaused() {
    if (_appLockEnabled && !_isAuthenticating) {
      _pendingLock = true;
    }
  }

  /// Called when the app returns from background.
  /// Locks only if a pause was recorded (real background, not biometric dialog).
  void onAppResumed() {
    if (_pendingLock) {
      _pendingLock = false;
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Re-checks biometric availability (e.g. user may have added/removed biometrics).
  Future<void> refreshAvailability() async {
    _availability = await _biometricService.checkAvailability();

    // Auto-disable if biometrics became unavailable.
    if (_appLockEnabled && !(_availability?.isAvailable ?? false)) {
      _appLockEnabled = false;
      _isLocked = false;
      await _secureStorage.delete(key: AppConstants.secureStorageAppLockKey);
      debugPrint('[Security] App lock auto-disabled: biometrics changed');
    }

    notifyListeners();
  }
}
