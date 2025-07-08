import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:expense_sage/model/admin.model.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:sqflite/sqflite.dart';

class AdminAuthService {
  static AdminSession? _currentSession;
  static const int _sessionDurationHours = 8;
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMinutes = 30;

  // Get current admin session
  static AdminSession? get currentSession => _currentSession;
  static Admin? get currentAdmin => _currentSession?.admin;
  static bool get isAuthenticated => _currentSession?.isValid ?? false;

  // Admin login
  static Future<AdminSession?> login(
    String email,
    String password, {
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final db = await getDBInstance();

      // Check for account lockout
      if (await _isAccountLocked(email)) {
        throw Exception(
            'Account is temporarily locked due to too many failed attempts');
      }

      // Find admin by email
      final adminResult = await db.rawQuery(
        'SELECT * FROM admins WHERE email = ? AND is_active = 1',
        [email],
      );

      if (adminResult.isEmpty) {
        await _recordFailedAttempt(email, ipAddress);
        throw Exception('Invalid credentials');
      }

      final adminData = adminResult.first;
      final storedPasswordHash = adminData['password_hash'] as String;

      // Verify password
      if (!_verifyPassword(password, storedPasswordHash)) {
        await _recordFailedAttempt(email, ipAddress);
        throw Exception('Invalid credentials');
      }

      // Clear failed attempts on successful login
      await _clearFailedAttempts(email);

      // Create admin object
      final admin = Admin.fromJson(adminData);

      // Generate session token
      final token = _generateSessionToken();
      final expiresAt =
          DateTime.now().add(const Duration(hours: _sessionDurationHours));

      // Create session
      final session = AdminSession(
        admin: admin,
        token: token,
        expiresAt: expiresAt,
        ipAddress: ipAddress ?? 'unknown',
        userAgent: userAgent ?? 'unknown',
      );

      // Store session in database
      await _storeSession(session);

      // Update last login time
      await db.update(
        'admins',
        {'last_login_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [admin.id],
      );

      _currentSession = session;
      return session;
    } catch (e) {
      rethrow;
    }
  }

  // Admin logout
  static Future<void> logout() async {
    if (_currentSession != null) {
      await _removeSession(_currentSession!.token);
      _currentSession = null;
    }
  }

  // Validate session token
  static Future<bool> validateSession(String token) async {
    try {
      final db = await getDBInstance();

      final sessionResult = await db.rawQuery(
        'SELECT * FROM admin_sessions WHERE token = ? AND expires_at > ?',
        [token, DateTime.now().toIso8601String()],
      );

      if (sessionResult.isEmpty) {
        return false;
      }

      final sessionData = sessionResult.first;
      final adminId = sessionData['admin_id'];

      // Get admin data
      final adminResult = await db.rawQuery(
        'SELECT * FROM admins WHERE id = ? AND is_active = 1',
        [adminId],
      );

      if (adminResult.isEmpty) {
        await _removeSession(token);
        return false;
      }

      // Recreate session
      final admin = Admin.fromJson(adminResult.first);
      _currentSession = AdminSession(
        admin: admin,
        token: token,
        expiresAt: DateTime.parse(sessionData['expires_at'] as String),
        ipAddress: sessionData['ip_address'] as String,
        userAgent: sessionData['user_agent'] as String,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Create new admin (only super admin can do this)
  static Future<Admin> createAdmin({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required AdminRole role,
    List<AdminPermission>? customPermissions,
    String? phoneNumber,
    String? department,
  }) async {
    if (!_hasPermission(AdminPermission.createUsers)) {
      throw Exception('Insufficient permissions to create admin');
    }

    final db = await getDBInstance();

    // Check if email already exists
    final existingAdmin = await db.rawQuery(
      'SELECT id FROM admins WHERE email = ?',
      [email],
    );

    if (existingAdmin.isNotEmpty) {
      throw Exception('Admin with this email already exists');
    }

    // Hash password
    final passwordHash = _hashPassword(password);

    // Get permissions
    final permissions = customPermissions ?? Admin.getDefaultPermissions(role);

    // Create admin
    final admin = Admin(
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      role: role,
      permissions: permissions,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      phoneNumber: phoneNumber,
      department: department,
    );

    // Insert into database
    final adminData = admin.toJson();
    adminData['password_hash'] = passwordHash;
    adminData.remove('id');

    final id = await db.insert('admins', adminData);

    return admin.copyWith(id: id);
  }

  // Update admin
  static Future<Admin> updateAdmin(
    int adminId, {
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    AdminRole? role,
    List<AdminPermission>? permissions,
    bool? isActive,
    String? phoneNumber,
    String? department,
  }) async {
    if (!_hasPermission(AdminPermission.editUsers)) {
      throw Exception('Insufficient permissions to update admin');
    }

    final db = await getDBInstance();

    // Get current admin
    final adminResult = await db.rawQuery(
      'SELECT * FROM admins WHERE id = ?',
      [adminId],
    );

    if (adminResult.isEmpty) {
      throw Exception('Admin not found');
    }

    final currentAdmin = Admin.fromJson(adminResult.first);

    // Update admin
    final updatedAdmin = currentAdmin.copyWith(
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      role: role,
      permissions: permissions,
      isActive: isActive,
      phoneNumber: phoneNumber,
      department: department,
      updatedAt: DateTime.now(),
    );

    // Update in database
    final updateData = updatedAdmin.toJson();
    updateData.remove('password_hash'); // Don't update password here

    await db.update(
      'admins',
      updateData,
      where: 'id = ?',
      whereArgs: [adminId],
    );

    return updatedAdmin;
  }

  // Change admin password
  static Future<void> changePassword(int adminId, String newPassword) async {
    if (!_hasPermission(AdminPermission.editUsers) &&
        currentAdmin?.id != adminId) {
      throw Exception('Insufficient permissions to change password');
    }

    final db = await getDBInstance();
    final passwordHash = _hashPassword(newPassword);

    await db.update(
      'admins',
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [adminId],
    );

    // Invalidate all sessions for this admin
    await db.delete(
      'admin_sessions',
      where: 'admin_id = ?',
      whereArgs: [adminId],
    );
  }

  // Get all admins
  static Future<List<Admin>> getAllAdmins() async {
    if (!_hasPermission(AdminPermission.viewUsers)) {
      throw Exception('Insufficient permissions to view admins');
    }

    final db = await getDBInstance();
    final result = await db.rawQuery(
      'SELECT * FROM admins ORDER BY created_at DESC',
    );

    return result.map((data) => Admin.fromJson(data)).toList();
  }

  // Delete admin
  static Future<void> deleteAdmin(int adminId) async {
    if (!_hasPermission(AdminPermission.deleteUsers)) {
      throw Exception('Insufficient permissions to delete admin');
    }

    if (currentAdmin?.id == adminId) {
      throw Exception('Cannot delete your own account');
    }

    final db = await getDBInstance();

    // Delete admin sessions first
    await db.delete(
      'admin_sessions',
      where: 'admin_id = ?',
      whereArgs: [adminId],
    );

    // Delete admin
    await db.delete(
      'admins',
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  // Helper methods
  static bool _hasPermission(AdminPermission permission) {
    return currentAdmin?.hasPermission(permission) ?? false;
  }

  static String _hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  static bool _verifyPassword(String password, String hash) {
    final parts = hash.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final storedHash = parts[1];

    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);

    return digest.toString() == storedHash;
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static Future<void> _storeSession(AdminSession session) async {
    final db = await getDBInstance();

    await db.insert('admin_sessions', {
      'admin_id': session.admin.id,
      'token': session.token,
      'expires_at': session.expiresAt.toIso8601String(),
      'ip_address': session.ipAddress,
      'user_agent': session.userAgent,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _removeSession(String token) async {
    final db = await getDBInstance();
    await db.delete(
      'admin_sessions',
      where: 'token = ?',
      whereArgs: [token],
    );
  }

  static Future<bool> _isAccountLocked(String email) async {
    final db = await getDBInstance();

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM admin_login_attempts 
      WHERE email = ? AND created_at > ? AND success = 0
    ''', [
      email,
      DateTime.now()
          .subtract(const Duration(minutes: _lockoutDurationMinutes))
          .toIso8601String(),
    ]);

    final failedAttempts = result.first['count'] as int;
    return failedAttempts >= _maxFailedAttempts;
  }

  static Future<void> _recordFailedAttempt(
      String email, String? ipAddress) async {
    final db = await getDBInstance();

    await db.insert('admin_login_attempts', {
      'email': email,
      'ip_address': ipAddress ?? 'unknown',
      'success': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _clearFailedAttempts(String email) async {
    final db = await getDBInstance();

    await db.delete(
      'admin_login_attempts',
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
