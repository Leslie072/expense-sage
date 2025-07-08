import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate using biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your account',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow fallback to device credentials
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected biometric authentication error: $e');
      return false;
    }
  }

  // Check if biometric authentication is enabled for the app
  static Future<bool> isBiometricEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Enable/disable biometric authentication for the app
  static Future<void> setBiometricEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  // Get biometric type name for display
  static String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (types.contains(BiometricType.weak)) {
      return 'Biometric';
    } else {
      return 'Biometric';
    }
  }

  // Check if user should be prompted for biometric setup
  static Future<bool> shouldPromptBiometricSetup() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasPrompted = prefs.getBool('biometric_setup_prompted') ?? false;
    final bool isEnabled = await isBiometricEnabled();
    final bool isAvailable = await isBiometricAvailable();

    return !hasPrompted && !isEnabled && isAvailable;
  }

  // Mark that user has been prompted for biometric setup
  static Future<void> markBiometricSetupPrompted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_setup_prompted', true);
  }

  // Authenticate for sensitive operations
  static Future<bool> authenticateForSensitiveOperation({
    String reason = 'Please authenticate to continue',
  }) async {
    final bool isBiometricEnabledForApp = await isBiometricEnabled();

    if (isBiometricEnabledForApp) {
      return await authenticateWithBiometrics(reason: reason);
    }

    // If biometric is not enabled, return true (no additional auth required)
    return true;
  }

  // Get user-friendly description of available biometrics
  static Future<String> getBiometricDescription() async {
    final List<BiometricType> availableBiometrics =
        await getAvailableBiometrics();

    if (availableBiometrics.isEmpty) {
      return 'No biometric authentication available';
    }

    List<String> types = [];
    if (availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Fingerprint');
    }
    if (availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }

    if (types.isEmpty) {
      return 'Biometric authentication';
    } else if (types.length == 1) {
      return types.first;
    } else {
      return types.join(' or ');
    }
  }
}
