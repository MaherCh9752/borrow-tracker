import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Result of a biometric availability check.
class BiometricAvailability {
  final bool isAvailable;
  final bool hasHardware;
  final bool hasEnrolled;
  final List<BiometricType> availableTypes;
  final String? errorMessage;

  const BiometricAvailability({
    required this.isAvailable,
    required this.hasHardware,
    required this.hasEnrolled,
    required this.availableTypes,
    this.errorMessage,
  });

  /// Device has biometric hardware but no credentials enrolled.
  bool get hardwareButNotEnrolled => hasHardware && !hasEnrolled;

  /// Human-readable summary of available biometric types.
  String get typeNames {
    if (availableTypes.isEmpty) return 'None';
    return availableTypes.map((t) {
      switch (t) {
        case BiometricType.face:
          return 'Face';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong biometric';
        case BiometricType.weak:
          return 'Weak biometric';
      }
    }).join(', ');
  }
}

/// Wraps the `local_auth` plugin to provide biometric authentication.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks whether the device supports biometrics and whether credentials are enrolled.
  Future<BiometricAvailability> checkAvailability() async {
    bool hasHardware = false;
    bool hasEnrolled = false;
    List<BiometricType> types = [];

    try {
      hasHardware = await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      return BiometricAvailability(
        isAvailable: false,
        hasHardware: false,
        hasEnrolled: false,
        availableTypes: const [],
        errorMessage: 'Failed to check biometric hardware: ${e.message}',
      );
    }

    if (hasHardware) {
      try {
        types = await _auth.getAvailableBiometrics();
        hasEnrolled = types.isNotEmpty;
      } on PlatformException catch (e) {
        return BiometricAvailability(
          isAvailable: false,
          hasHardware: true,
          hasEnrolled: false,
          availableTypes: const [],
          errorMessage: 'Failed to get available biometrics: ${e.message}',
        );
      }
    }

    return BiometricAvailability(
      isAvailable: hasHardware && hasEnrolled,
      hasHardware: hasHardware,
      hasEnrolled: hasEnrolled,
      availableTypes: types,
    );
  }

  /// Prompts the user for biometric authentication.
  /// Returns `true` if authentication succeeded, `false` otherwise.
  Future<bool> authenticate({String? reason}) async {
    try {
      final result = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to unlock Borrow Tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      debugPrint('[BiometricService] authenticate result: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException: code=${e.code}, message=${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return false;
    }
  }

  /// Returns available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: ${e.message}');
      return [];
    }
  }
}
