import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/services/biometric_service.dart';
import 'package:expense_sage/helpers/currency.helper.dart';

/// Service to preload essential app resources in the background
class PreloaderService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Initialize essential services in the background
  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Initialize services that don't block UI
      await Future.wait([
        _initializeDatabase(),
        _initializeBiometrics(),
        _initializeCurrencies(),
      ], eagerError: false);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Preloader initialization error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Check if preloader has finished initialization
  static bool get isInitialized => _isInitialized;

  /// Initialize database connection
  static Future<void> _initializeDatabase() async {
    try {
      await getDBInstance();
      debugPrint('Database preloaded successfully');
    } catch (e) {
      debugPrint('Database preload error: $e');
    }
  }

  /// Initialize biometric services
  static Future<void> _initializeBiometrics() async {
    try {
      await BiometricService.isBiometricAvailable();
      debugPrint('Biometric services preloaded successfully');
    } catch (e) {
      debugPrint('Biometric preload error: $e');
    }
  }

  /// Initialize currency data
  static Future<void> _initializeCurrencies() async {
    try {
      await CurrencyHelper.loadCurrencies();
      debugPrint('Currency data preloaded successfully');
    } catch (e) {
      debugPrint('Currency preload error: $e');
    }
  }

  /// Warm up critical app components
  static Future<void> warmUp() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
