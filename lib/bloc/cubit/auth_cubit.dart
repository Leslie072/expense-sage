import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_sage/dao/user_dao.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/services/biometric_service.dart';
import 'package:expense_sage/services/two_factor_service.dart';
import 'package:expense_sage/services/preloader_service.dart';

// Authentication States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthRequires2FA extends AuthState {
  final User user;
  AuthRequires2FA(this.user);
}

// Authentication Cubit
class AuthCubit extends Cubit<AuthState> {
  final UserDao _userDao = UserDao();
  User? _currentUser;

  AuthCubit() : super(AuthInitial());

  User? get currentUser => _currentUser;

  // Check if user is already logged in (on app start)
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      if (userId != null) {
        // Defer database operations until after UI is shown
        _deferredAuthCheck(userId);
        return;
      }

      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint("Check auth status error: $e");
      emit(AuthUnauthenticated());
    }
  }

  // Perform heavy authentication checks after UI is loaded
  Future<void> _deferredAuthCheck(int userId) async {
    try {
      // Wait for preloader to finish or timeout after 2 seconds
      int attempts = 0;
      while (!PreloaderService.isInitialized && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      // Ensure database is ready
      await getDBInstance();

      User? user = await _userDao.findById(userId);
      if (user != null) {
        _currentUser = user;
        setCurrentUser(userId); // Set in database helper

        // Check biometric authentication in background (skip for admin)
        if (user.userType != UserType.admin) {
          _checkBiometricAuth(user);
        } else {
          emit(AuthAuthenticated(user));
        }
      } else {
        // User not found, clear stored data
        await _clearStoredAuth();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint("Deferred auth check error: $e");
      emit(AuthUnauthenticated());
    }
  }

  // Check biometric authentication asynchronously
  Future<void> _checkBiometricAuth(User user) async {
    try {
      final bool isBiometricEnabled =
          await BiometricService.isBiometricEnabled();

      if (isBiometricEnabled) {
        // Show authenticated state first, then check biometrics
        emit(AuthAuthenticated(user));

        final bool biometricSuccess =
            await BiometricService.authenticateWithBiometrics(
          reason: 'Please authenticate to access your account',
        );

        if (!biometricSuccess) {
          // Biometric authentication failed, logout
          await logout();
          emit(AuthError('Biometric authentication failed'));
        }
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      debugPrint("Biometric auth error: $e");
      emit(AuthAuthenticated(user)); // Fallback to authenticated state
    }
  }

  // Login user
  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    try {
      User? user = await _userDao.login(email, password);

      if (user != null) {
        _currentUser = user;

        // Check if 2FA is enabled for this user
        if (user.twoFactorEnabled) {
          // Don't store auth data yet, require 2FA verification first
          emit(AuthRequires2FA(user));
        } else {
          await _storeAuthData(user);
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(AuthError('Invalid email or password'));
      }
    } catch (e) {
      debugPrint("Login error: $e");
      emit(AuthError('Login failed. Please try again.'));
    }
  }

  // Register new user
  Future<void> register(String email, String username, String password) async {
    emit(AuthLoading());

    try {
      User? user = await _userDao.register(email, username, password);

      if (user != null) {
        _currentUser = user;
        await _storeAuthData(user);

        // Initialize default data for new user
        await initializeUserData(user.id!);

        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Registration failed'));
      }
    } catch (e) {
      debugPrint("Registration error: $e");
      String errorMessage = 'Registration failed. Please try again.';

      if (e.toString().contains('Email already exists')) {
        errorMessage = 'Email already exists. Please use a different email.';
      }

      emit(AuthError(errorMessage));
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _userDao.logout();
      _currentUser = null;
      await _clearStoredAuth();
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint("Logout error: $e");
      // Even if there's an error, we should still log out locally
      _currentUser = null;
      await _clearStoredAuth();
      emit(AuthUnauthenticated());
    }
  }

  // Update user profile
  Future<void> updateProfile(String username) async {
    if (_currentUser == null) return;

    try {
      bool success = await _userDao.updateProfile(_currentUser!.id!, username);

      if (success) {
        // Update local user data
        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          username: username,
          passwordHash: '', // Keep empty for security
          createdAt: _currentUser!.createdAt,
          updatedAt: DateTime.now(),
          isActive: _currentUser!.isActive,
        );

        await _storeAuthData(_currentUser!);
        emit(AuthAuthenticated(_currentUser!));
      }
    } catch (e) {
      debugPrint("Update profile error: $e");
      // Don't emit error state, just log it
    }
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;

    try {
      return await _userDao.changePassword(
          _currentUser!.id!, oldPassword, newPassword);
    } catch (e) {
      debugPrint("Change password error: $e");
      return false;
    }
  }

  // Store authentication data locally
  Future<void> _storeAuthData(User user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_username', user.username);
  }

  // Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_username');
    clearCurrentUser(); // Clear from database helper
  }

  // Reset error state
  void clearError() {
    if (state is AuthError) {
      emit(AuthUnauthenticated());
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  // Get current user from state
  User? getUserFromState() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return null;
  }

  // Enable/disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Test biometric authentication before enabling
        final bool canAuthenticate =
            await BiometricService.isBiometricAvailable();
        if (!canAuthenticate) {
          return false;
        }

        final bool authSuccess =
            await BiometricService.authenticateWithBiometrics(
          reason: 'Please authenticate to enable biometric login',
        );

        if (!authSuccess) {
          return false;
        }
      }

      await BiometricService.setBiometricEnabled(enabled);
      return true;
    } catch (e) {
      debugPrint("Set biometric enabled error: $e");
      return false;
    }
  }

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await BiometricService.isBiometricAvailable();
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await BiometricService.isBiometricEnabled();
  }

  // Get biometric description for UI
  Future<String> getBiometricDescription() async {
    return await BiometricService.getBiometricDescription();
  }

  // Authenticate for sensitive operations
  Future<bool> authenticateForSensitiveOperation({String? reason}) async {
    return await BiometricService.authenticateForSensitiveOperation(
      reason: reason ?? 'Please authenticate to continue',
    );
  }

  // Verify 2FA code and complete login
  Future<void> verify2FACode(String code) async {
    if (state is! AuthRequires2FA) return;

    emit(AuthLoading());

    try {
      final bool isValid = await TwoFactorService.verify2FACode(code);

      if (isValid && _currentUser != null) {
        await _storeAuthData(_currentUser!);
        emit(AuthAuthenticated(_currentUser!));
      } else {
        // Return to 2FA required state with error
        emit(AuthError('Invalid verification code'));
        // After a short delay, return to 2FA required state
        await Future.delayed(const Duration(seconds: 1));
        emit(AuthRequires2FA(_currentUser!));
      }
    } catch (e) {
      debugPrint("2FA verification error: $e");
      emit(AuthError('Verification failed. Please try again.'));
      await Future.delayed(const Duration(seconds: 1));
      if (_currentUser != null) {
        emit(AuthRequires2FA(_currentUser!));
      }
    }
  }

  // Check if 2FA is enabled for current user
  Future<bool> is2FAEnabled() async {
    return await TwoFactorService.isTwoFactorEnabled();
  }
}
