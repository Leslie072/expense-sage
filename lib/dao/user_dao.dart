import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:flutter/material.dart';

class UserDao {
  // Hash password using SHA-256
  String _hashPassword(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random salt
  String _generateSalt() {
    var random = Random.secure();
    var saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // Create new user (registration) - Personal users only
  Future<User?> register(String email, String username, String password) async {
    final db = await getDBInstance();
    debugPrint("UserDao: Starting registration for email: $email");

    try {
      // Check if email already exists
      var existingUser = await findByEmail(email);
      if (existingUser != null) {
        debugPrint("UserDao: Email already exists: $email");
        throw Exception('Email already exists');
      }

      // Generate salt and hash password
      String salt = _generateSalt();
      String passwordHash = _hashPassword(password, salt);
      String saltedHash = '$salt:$passwordHash'; // Store salt with hash

      DateTime now = DateTime.now();

      User user = User(
        email: email.toLowerCase().trim(),
        username: username.trim(),
        passwordHash: saltedHash,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint("UserDao: Inserting user into database");
      int userId = await db.insert("users", user.toJson());
      user.id = userId;

      debugPrint(
          "UserDao: User registered successfully with ID: $userId, email: ${user.email}");
      return user;
    } catch (e) {
      debugPrint("UserDao: Registration error: $e");
      rethrow;
    }
  }

  // Login user
  Future<User?> login(String email, String password) async {
    debugPrint("UserDao: Starting login for email: $email");
    try {
      User? user = await findByEmail(email);
      if (user == null) {
        debugPrint("UserDao: User not found for email: $email");
        return null;
      }

      // Extract salt and hash from stored password
      List<String> parts = user.passwordHash.split(':');
      if (parts.length != 2) {
        debugPrint("Invalid password hash format");
        return null;
      }

      String salt = parts[0];
      String storedHash = parts[1];
      String inputHash = _hashPassword(password, salt);

      if (inputHash == storedHash && user.isActive) {
        // Set current user in database helper
        setCurrentUser(user.id!);
        return user.copyWithoutPassword();
      }

      return null;
    } catch (e) {
      debugPrint("Login error: $e");
      return null;
    }
  }

  // Find user by email
  Future<User?> findByEmail(String email) async {
    final db = await getDBInstance();
    debugPrint("UserDao: Finding user by email: $email");

    try {
      List<Map<String, Object?>> rows = await db.query(
        "users",
        where: "email = ? AND is_active = 1",
        whereArgs: [email.toLowerCase().trim()],
        limit: 1,
      );

      debugPrint("UserDao: Query returned ${rows.length} rows");

      if (rows.isNotEmpty) {
        return User.fromJson(rows.first);
      }
      return null;
    } catch (e) {
      debugPrint("Find user by email error: $e");
      return null;
    }
  }

  // Find user by ID
  Future<User?> findById(int id) async {
    final db = await getDBInstance();

    try {
      List<Map<String, Object?>> rows = await db.query(
        "users",
        where: "id = ? AND is_active = 1",
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return User.fromJson(rows.first);
      }
      return null;
    } catch (e) {
      debugPrint("Find user by ID error: $e");
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile(int userId, String username) async {
    final db = await getDBInstance();

    try {
      int result = await db.update(
        "users",
        {
          "username": username.trim(),
          "updated_at": DateTime.now().toIso8601String(),
        },
        where: "id = ?",
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      debugPrint("Update profile error: $e");
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(
      int userId, String oldPassword, String newPassword) async {
    final db = await getDBInstance();

    try {
      User? user = await findById(userId);
      if (user == null) return false;

      // Verify old password
      List<String> parts = user.passwordHash.split(':');
      if (parts.length != 2) return false;

      String salt = parts[0];
      String storedHash = parts[1];
      String oldHash = _hashPassword(oldPassword, salt);

      if (oldHash != storedHash) return false;

      // Generate new salt and hash for new password
      String newSalt = _generateSalt();
      String newPasswordHash = _hashPassword(newPassword, newSalt);
      String newSaltedHash = '$newSalt:$newPasswordHash';

      int result = await db.update(
        "users",
        {
          "password_hash": newSaltedHash,
          "updated_at": DateTime.now().toIso8601String(),
        },
        where: "id = ?",
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      debugPrint("Change password error: $e");
      return false;
    }
  }

  // Deactivate user account
  Future<bool> deactivateAccount(int userId) async {
    final db = await getDBInstance();

    try {
      int result = await db.update(
        "users",
        {
          "is_active": 0,
          "updated_at": DateTime.now().toIso8601String(),
        },
        where: "id = ?",
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      debugPrint("Deactivate account error: $e");
      return false;
    }
  }

  // Get all active users (admin function)
  Future<List<User>> getAllUsers() async {
    final db = await getDBInstance();

    try {
      List<Map<String, Object?>> rows = await db.query(
        "users",
        where: "is_active = 1",
        orderBy: "created_at DESC",
      );

      return rows
          .map((row) => User.fromJson(row).copyWithoutPassword())
          .toList();
    } catch (e) {
      debugPrint("Get all users error: $e");
      return [];
    }
  }

  // Verify security answer for password reset
  Future<bool> verifySecurityAnswer(String email, String answer) async {
    try {
      User? user = await findByEmail(email);
      if (user == null || user.securityAnswerHash == null) {
        return false;
      }

      // Extract salt and hash from stored security answer
      List<String> parts = user.securityAnswerHash!.split(':');
      if (parts.length != 2) {
        return false;
      }

      String salt = parts[0];
      String storedHash = parts[1];
      String inputHash = _hashPassword(answer.toLowerCase().trim(), salt);

      return inputHash == storedHash;
    } catch (e) {
      debugPrint("Verify security answer error: $e");
      return false;
    }
  }

  // Reset password using email
  Future<bool> resetPassword(String email, String newPassword) async {
    final db = await getDBInstance();

    try {
      User? user = await findByEmail(email);
      if (user == null) return false;

      // Generate new salt and hash for new password
      String newSalt = _generateSalt();
      String newPasswordHash = _hashPassword(newPassword, newSalt);
      String newSaltedHash = '$newSalt:$newPasswordHash';

      int result = await db.update(
        "users",
        {
          "password_hash": newSaltedHash,
          "updated_at": DateTime.now().toIso8601String(),
        },
        where: "email = ?",
        whereArgs: [email.toLowerCase().trim()],
      );

      return result > 0;
    } catch (e) {
      debugPrint("Reset password error: $e");
      return false;
    }
  }

  // Set security question and answer
  Future<bool> setSecurityQuestion(
      int userId, String question, String answer) async {
    final db = await getDBInstance();

    try {
      // Generate salt and hash for security answer
      String salt = _generateSalt();
      String answerHash = _hashPassword(answer.toLowerCase().trim(), salt);
      String saltedHash = '$salt:$answerHash';

      int result = await db.update(
        "users",
        {
          "security_question": question,
          "security_answer_hash": saltedHash,
          "updated_at": DateTime.now().toIso8601String(),
        },
        where: "id = ?",
        whereArgs: [userId],
      );

      return result > 0;
    } catch (e) {
      debugPrint("Set security question error: $e");
      return false;
    }
  }

  // Admin method to create large scale business user
  Future<User?> createLargeScaleBusinessUser({
    required String email,
    required String username,
    required String password,
    required String businessName,
    required String businessRegistrationNumber,
    required int adminUserId,
  }) async {
    final db = await getDBInstance();
    debugPrint("UserDao: Admin creating large scale business user: $email");

    try {
      // Verify the requesting user is an admin
      User? admin = await findById(adminUserId);
      if (admin == null || admin.userType != UserType.admin) {
        throw Exception('Only admins can create large scale business users');
      }

      // Check if email already exists
      var existingUser = await findByEmail(email);
      if (existingUser != null) {
        throw Exception('Email already exists');
      }

      // Generate salt and hash password
      String salt = _generateSalt();
      String passwordHash = _hashPassword(password, salt);
      String saltedHash = '$salt:$passwordHash';

      DateTime now = DateTime.now();

      User user = User(
        email: email.toLowerCase().trim(),
        username: username.trim(),
        passwordHash: saltedHash,
        createdAt: now,
        updatedAt: now,
        userType: UserType.largeScaleBusiness,
        businessName: businessName,
        businessRegistrationNumber: businessRegistrationNumber,
      );

      debugPrint("UserDao: Inserting large scale business user into database");
      int userId = await db.insert("users", user.toJson());
      user.id = userId;

      debugPrint(
          "UserDao: Large scale business user created successfully with ID: $userId");
      return user;
    } catch (e) {
      debugPrint("UserDao: Large scale business user creation error: $e");
      rethrow;
    }
  }

  // Get all large scale business users (admin only)
  Future<List<User>> getLargeScaleBusinessUsers(int adminUserId) async {
    final db = await getDBInstance();

    try {
      // Verify the requesting user is an admin
      User? admin = await findById(adminUserId);
      if (admin == null || admin.userType != UserType.admin) {
        throw Exception('Only admins can view large scale business users');
      }

      List<Map<String, Object?>> rows = await db.query(
        "users",
        where: "user_type = ? AND is_active = 1",
        whereArgs: ["large_scale_business"],
        orderBy: "created_at DESC",
      );

      return rows.map((row) => User.fromJson(row)).toList();
    } catch (e) {
      debugPrint("Get large scale business users error: $e");
      return [];
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(int userId) async {
    try {
      User? user = await findById(userId);
      return user?.userType == UserType.admin;
    } catch (e) {
      debugPrint("Check admin error: $e");
      return false;
    }
  }

  // Debug method to create admin user manually
  Future<void> createAdminUser() async {
    final db = await getDBInstance();

    try {
      // Delete existing admin user if it exists
      await db.delete(
        "users",
        where: "user_type = ? AND email = ?",
        whereArgs: ["admin", "admin@expensesage.com"],
      );
      debugPrint("UserDao: Deleted existing admin user");

      // Create admin user with proper password hashing
      String salt = _generateSalt();
      String passwordHash = _hashPassword("admin123", salt);
      String saltedHash = '$salt:$passwordHash';

      await db.insert("users", {
        "email": "admin@expensesage.com",
        "username": "Admin",
        "password_hash": saltedHash,
        "user_type": "admin",
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
        "is_active": 1,
        "two_factor_enabled": 0,
      });
      debugPrint("UserDao: Created admin user successfully");
    } catch (e) {
      debugPrint("UserDao: Error creating admin user: $e");
      rethrow;
    }
  }

  // Logout user
  void logout() {
    clearCurrentUser();
  }
}
