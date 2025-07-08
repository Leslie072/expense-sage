import 'dart:math';
import 'dart:typed_data';
import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:base32/base32.dart';

class TwoFactorService {
  static const String _secretKey = '2fa_secret';
  static const String _enabledKey = '2fa_enabled';
  static const String _backupCodesKey = '2fa_backup_codes';

  // Generate a random secret for TOTP
  static String generateSecret() {
    final random = Random.secure();
    final bytes =
        Uint8List.fromList(List<int>.generate(20, (i) => random.nextInt(256)));
    return base32.encode(bytes);
  }

  // Generate TOTP code
  static String generateTOTP(String secret) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return OTP.generateTOTPCodeString(
      secret,
      currentTime,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
    );
  }

  // Verify TOTP code
  static bool verifyTOTP(String secret, String code) {
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Check current time window and previous/next windows for clock drift
    for (int i = -1; i <= 1; i++) {
      final int timeWindow = currentTime + (i * 30);
      final String expectedCode = OTP.generateTOTPCodeString(
        secret,
        timeWindow,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
      );

      if (expectedCode == code) {
        return true;
      }
    }

    return false;
  }

  // Generate QR code data for authenticator apps
  static String generateQRCodeData(
      String secret, String accountName, String issuer) {
    return 'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer';
  }

  // Save 2FA secret
  static Future<void> saveSecret(String secret) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secretKey, secret);
  }

  // Get saved 2FA secret
  static Future<String?> getSecret() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretKey);
  }

  // Enable/disable 2FA
  static Future<void> setTwoFactorEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  // Check if 2FA is enabled
  static Future<bool> isTwoFactorEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  // Generate backup codes
  static List<String> generateBackupCodes() {
    final random = Random.secure();
    final List<String> codes = [];

    for (int i = 0; i < 10; i++) {
      final code = List.generate(8, (index) => random.nextInt(10)).join();
      codes.add('${code.substring(0, 4)}-${code.substring(4)}');
    }

    return codes;
  }

  // Save backup codes
  static Future<void> saveBackupCodes(List<String> codes) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_backupCodesKey, codes);
  }

  // Get backup codes
  static Future<List<String>> getBackupCodes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_backupCodesKey) ?? [];
  }

  // Use backup code (remove it from the list)
  static Future<bool> useBackupCode(String code) async {
    final List<String> codes = await getBackupCodes();
    final String normalizedCode = code.replaceAll('-', '').replaceAll(' ', '');

    for (int i = 0; i < codes.length; i++) {
      final String normalizedStoredCode =
          codes[i].replaceAll('-', '').replaceAll(' ', '');
      if (normalizedStoredCode == normalizedCode) {
        codes.removeAt(i);
        await saveBackupCodes(codes);
        return true;
      }
    }

    return false;
  }

  // Setup 2FA (generate secret and backup codes)
  static Future<Map<String, dynamic>> setup2FA(String userEmail) async {
    final String secret = generateSecret();
    final List<String> backupCodes = generateBackupCodes();

    await saveSecret(secret);
    await saveBackupCodes(backupCodes);

    final String qrCodeData = generateQRCodeData(
      secret,
      userEmail,
      'Expense Sage',
    );

    return {
      'secret': secret,
      'qrCodeData': qrCodeData,
      'backupCodes': backupCodes,
    };
  }

  // Verify 2FA code (TOTP or backup code)
  static Future<bool> verify2FACode(String code) async {
    final String? secret = await getSecret();
    if (secret == null) return false;

    // First try TOTP verification
    if (verifyTOTP(secret, code)) {
      return true;
    }

    // If TOTP fails, try backup code
    return await useBackupCode(code);
  }

  // Disable 2FA (clear all data)
  static Future<void> disable2FA() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_secretKey);
    await prefs.remove(_enabledKey);
    await prefs.remove(_backupCodesKey);
  }

  // Get remaining backup codes count
  static Future<int> getRemainingBackupCodesCount() async {
    final List<String> codes = await getBackupCodes();
    return codes.length;
  }

  // Regenerate backup codes
  static Future<List<String>> regenerateBackupCodes() async {
    final List<String> newCodes = generateBackupCodes();
    await saveBackupCodes(newCodes);
    return newCodes;
  }

  // Format secret for display (groups of 4 characters)
  static String formatSecretForDisplay(String secret) {
    final RegExp regex = RegExp(r'.{1,4}');
    return regex.allMatches(secret).map((match) => match.group(0)).join(' ');
  }

  // Validate TOTP code format
  static bool isValidTOTPFormat(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  // Validate backup code format
  static bool isValidBackupCodeFormat(String code) {
    final String normalizedCode = code.replaceAll('-', '').replaceAll(' ', '');
    return RegExp(r'^\d{8}$').hasMatch(normalizedCode);
  }

  // Check if code is valid format (TOTP or backup)
  static bool isValidCodeFormat(String code) {
    return isValidTOTPFormat(code) || isValidBackupCodeFormat(code);
  }

  // Get time remaining for current TOTP code
  static int getTimeRemaining() {
    final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 30 - (currentTime % 30);
  }

  // Check if 2FA setup is complete
  static Future<bool> isSetupComplete() async {
    final String? secret = await getSecret();
    final bool isEnabled = await isTwoFactorEnabled();
    return secret != null && isEnabled;
  }
}
