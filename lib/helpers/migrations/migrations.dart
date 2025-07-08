import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

double safeDouble(dynamic value) {
  try {
    return double.parse(value);
  } catch (err) {
    return 0;
  }
}

// Helper functions for password hashing (same as UserDao)
String _hashPassword(String password, String salt) {
  var bytes = utf8.encode(password + salt);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

String _generateSalt() {
  var random = Random.secure();
  var saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
  return base64.encode(saltBytes);
}

void v1(Database database) async {
  debugPrint("Migration v1: Running first migration....");

  // Create users table first
  debugPrint("Migration v1: Creating users table");
  await database.execute("CREATE TABLE users ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "email TEXT UNIQUE NOT NULL,"
      "username TEXT NOT NULL,"
      "password_hash TEXT NOT NULL,"
      "security_question TEXT NULL,"
      "security_answer_hash TEXT NULL,"
      "two_factor_secret TEXT NULL,"
      "two_factor_enabled INTEGER DEFAULT 0,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "is_active INTEGER DEFAULT 1"
      ")");

  await database.execute("CREATE TABLE payments ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "title TEXT NULL, "
      "description TEXT NULL, "
      "account INTEGER,"
      "category INTEGER,"
      "amount REAL,"
      "type TEXT,"
      "datetime DATETIME,"
      "user_id INTEGER,"
      "FOREIGN KEY (user_id) REFERENCES users (id)"
      ")");

  await database.execute("CREATE TABLE categories ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT,"
      "icon INTEGER,"
      "color INTEGER,"
      "budget REAL NULL, "
      "type TEXT,"
      "user_id INTEGER,"
      "FOREIGN KEY (user_id) REFERENCES users (id)"
      ")");

  await database.execute("CREATE TABLE accounts ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT,"
      "holderName TEXT NULL, "
      "accountNumber TEXT NULL, "
      "icon INTEGER,"
      "color INTEGER,"
      "isDefault INTEGER,"
      "user_id INTEGER,"
      "FOREIGN KEY (user_id) REFERENCES users (id)"
      ")");

  // Create indexes for better performance
  debugPrint("Migration v1: Creating indexes");
  await database
      .execute("CREATE INDEX idx_payments_user_id ON payments(user_id)");
  await database
      .execute("CREATE INDEX idx_categories_user_id ON categories(user_id)");
  await database
      .execute("CREATE INDEX idx_accounts_user_id ON accounts(user_id)");
  await database.execute("CREATE INDEX idx_users_email ON users(email)");

  debugPrint("Migration v1: Completed successfully");
}

// Migration for existing databases to add authentication
void v2(Database database) async {
  debugPrint("Running authentication migration....");

  // Check if users table exists (for existing databases)
  var result = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");

  if (result.isEmpty) {
    // Create users table if it doesn't exist
    await database.execute("CREATE TABLE users ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "email TEXT UNIQUE NOT NULL,"
        "username TEXT NOT NULL,"
        "password_hash TEXT NOT NULL,"
        "security_question TEXT NULL,"
        "security_answer_hash TEXT NULL,"
        "two_factor_secret TEXT NULL,"
        "two_factor_enabled INTEGER DEFAULT 0,"
        "created_at TEXT NOT NULL,"
        "updated_at TEXT NOT NULL,"
        "is_active INTEGER DEFAULT 1"
        ")");

    await database.execute("CREATE INDEX idx_users_email ON users(email)");
  }

  // Add user_id column to existing tables if they don't have it
  try {
    await database.execute("ALTER TABLE payments ADD COLUMN user_id INTEGER");
    await database
        .execute("CREATE INDEX idx_payments_user_id ON payments(user_id)");
  } catch (e) {
    debugPrint("payments.user_id column already exists or error: $e");
  }

  try {
    await database.execute("ALTER TABLE categories ADD COLUMN user_id INTEGER");
    await database
        .execute("CREATE INDEX idx_categories_user_id ON categories(user_id)");
  } catch (e) {
    debugPrint("categories.user_id column already exists or error: $e");
  }

  try {
    await database.execute("ALTER TABLE accounts ADD COLUMN user_id INTEGER");
    await database
        .execute("CREATE INDEX idx_accounts_user_id ON accounts(user_id)");
  } catch (e) {
    debugPrint("accounts.user_id column already exists or error: $e");
  }

  // Add 2FA columns to existing users table
  try {
    await database
        .execute("ALTER TABLE users ADD COLUMN two_factor_secret TEXT NULL");
  } catch (e) {
    debugPrint("users.two_factor_secret column already exists or error: $e");
  }

  try {
    await database.execute(
        "ALTER TABLE users ADD COLUMN two_factor_enabled INTEGER DEFAULT 0");
  } catch (e) {
    debugPrint("users.two_factor_enabled column already exists or error: $e");
  }
}

// Migration for advanced features
void v3(Database database) async {
  debugPrint("Running advanced features migration....");

  // Create recurring transactions table
  await database.execute("CREATE TABLE IF NOT EXISTS recurring_transactions ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "title TEXT NOT NULL,"
      "description TEXT NULL,"
      "account INTEGER NOT NULL,"
      "category INTEGER NOT NULL,"
      "amount REAL NOT NULL,"
      "type TEXT NOT NULL,"
      "recurrence_type INTEGER NOT NULL,"
      "status INTEGER DEFAULT 0,"
      "start_date TEXT NOT NULL,"
      "end_date TEXT NULL,"
      "last_executed TEXT NULL,"
      "next_due TEXT NULL,"
      "max_occurrences INTEGER NULL,"
      "executed_count INTEGER DEFAULT 0,"
      "is_auto_execute INTEGER DEFAULT 0,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "user_id INTEGER NOT NULL,"
      "FOREIGN KEY (user_id) REFERENCES users (id),"
      "FOREIGN KEY (account) REFERENCES accounts (id),"
      "FOREIGN KEY (category) REFERENCES categories (id)"
      ")");

  // Create savings goals table
  await database.execute("CREATE TABLE IF NOT EXISTS savings_goals ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT NOT NULL,"
      "description TEXT NULL,"
      "target_amount REAL NOT NULL,"
      "current_amount REAL DEFAULT 0,"
      "target_date TEXT NOT NULL,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "status INTEGER DEFAULT 0,"
      "priority INTEGER DEFAULT 1,"
      "icon INTEGER DEFAULT 0,"
      "color INTEGER DEFAULT 0,"
      "is_auto_save INTEGER DEFAULT 0,"
      "auto_save_amount REAL DEFAULT 0,"
      "auto_save_frequency TEXT DEFAULT 'monthly',"
      "last_auto_save TEXT NULL,"
      "user_id INTEGER NOT NULL,"
      "FOREIGN KEY (user_id) REFERENCES users (id)"
      ")");

  // Create receipts table
  await database.execute("CREATE TABLE IF NOT EXISTS receipts ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "merchant_name TEXT NOT NULL,"
      "merchant_address TEXT NULL,"
      "transaction_date TEXT NOT NULL,"
      "total_amount REAL NOT NULL,"
      "tax_amount REAL DEFAULT 0,"
      "subtotal_amount REAL DEFAULT 0,"
      "currency TEXT DEFAULT 'USD',"
      "receipt_number TEXT NULL,"
      "image_path TEXT NOT NULL,"
      "ocr_text TEXT NULL,"
      "items TEXT NULL,"
      "status INTEGER DEFAULT 0,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "payment_id INTEGER NULL,"
      "metadata TEXT NULL,"
      "user_id INTEGER NOT NULL,"
      "FOREIGN KEY (user_id) REFERENCES users (id),"
      "FOREIGN KEY (payment_id) REFERENCES payments (id)"
      ")");

  // Create investments table
  await database.execute("CREATE TABLE IF NOT EXISTS investments ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "symbol TEXT NOT NULL,"
      "name TEXT NOT NULL,"
      "type INTEGER NOT NULL,"
      "quantity REAL NOT NULL,"
      "purchase_price REAL NOT NULL,"
      "current_price REAL DEFAULT 0,"
      "purchase_date TEXT NOT NULL,"
      "sale_date TEXT NULL,"
      "sale_price REAL NULL,"
      "status INTEGER DEFAULT 0,"
      "currency TEXT DEFAULT 'USD',"
      "exchange TEXT NULL,"
      "sector TEXT NULL,"
      "description TEXT NULL,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "last_price_update TEXT NULL,"
      "user_id INTEGER NOT NULL,"
      "FOREIGN KEY (user_id) REFERENCES users (id)"
      ")");

  // Create admin tables
  await database.execute("CREATE TABLE IF NOT EXISTS admins ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "email TEXT UNIQUE NOT NULL,"
      "username TEXT UNIQUE NOT NULL,"
      "password_hash TEXT NOT NULL,"
      "first_name TEXT NOT NULL,"
      "last_name TEXT NOT NULL,"
      "role INTEGER NOT NULL,"
      "permissions TEXT NOT NULL,"
      "is_active INTEGER DEFAULT 1,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "last_login_at TEXT NULL,"
      "profile_image_url TEXT NULL,"
      "phone_number TEXT NULL,"
      "department TEXT NULL"
      ")");

  await database.execute("CREATE TABLE IF NOT EXISTS admin_sessions ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "admin_id INTEGER NOT NULL,"
      "token TEXT UNIQUE NOT NULL,"
      "expires_at TEXT NOT NULL,"
      "ip_address TEXT NOT NULL,"
      "user_agent TEXT NOT NULL,"
      "created_at TEXT NOT NULL,"
      "FOREIGN KEY (admin_id) REFERENCES admins (id)"
      ")");

  await database.execute("CREATE TABLE IF NOT EXISTS admin_login_attempts ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "email TEXT NOT NULL,"
      "ip_address TEXT NOT NULL,"
      "success INTEGER NOT NULL,"
      "created_at TEXT NOT NULL"
      ")");

  await database.execute("CREATE TABLE IF NOT EXISTS businesses ("
      "id INTEGER PRIMARY KEY AUTOINCREMENT,"
      "name TEXT NOT NULL,"
      "legal_name TEXT NOT NULL,"
      "type INTEGER NOT NULL,"
      "status INTEGER NOT NULL,"
      "tier INTEGER NOT NULL,"
      "tax_id TEXT NULL,"
      "registration_number TEXT NULL,"
      "email TEXT NOT NULL,"
      "phone TEXT NULL,"
      "website TEXT NULL,"
      "address TEXT NULL,"
      "primary_contact TEXT NULL,"
      "settings TEXT NOT NULL,"
      "limits TEXT NOT NULL,"
      "created_at TEXT NOT NULL,"
      "updated_at TEXT NOT NULL,"
      "trial_ends_at TEXT NULL,"
      "subscription_ends_at TEXT NULL,"
      "employee_count INTEGER DEFAULT 0,"
      "monthly_revenue REAL DEFAULT 0,"
      "industry TEXT NULL,"
      "description TEXT NULL,"
      "logo_url TEXT NULL"
      ")");

  // Create indexes for better performance
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_recurring_transactions_user_id ON recurring_transactions(user_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_recurring_transactions_next_due ON recurring_transactions(next_due)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals(user_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_receipts_user_id ON receipts(user_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_receipts_payment_id ON receipts(payment_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_investments_user_id ON investments(user_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_investments_symbol ON investments(symbol)");
  await database
      .execute("CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(email)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON admin_sessions(token)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_id ON admin_sessions(admin_id)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_businesses_status ON businesses(status)");
  await database.execute(
      "CREATE INDEX IF NOT EXISTS idx_businesses_tier ON businesses(tier)");

  // Create default super admin (password: admin123)
  await database.execute("""
    INSERT OR IGNORE INTO admins (
      email, username, password_hash, first_name, last_name, role, permissions,
      created_at, updated_at
    ) VALUES (
      'admin@expensesage.com',
      'superadmin',
      'YWRtaW4xMjM=:5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8',
      'Super',
      'Admin',
      0,
      '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]',
      datetime('now'),
      datetime('now')
    )
  """);
}

// Migration for admin system and user types
void v4(Database database) async {
  debugPrint("Migration v4: Adding admin system and user types....");

  try {
    // Add user_type column to users table
    await database.execute(
        "ALTER TABLE users ADD COLUMN user_type TEXT DEFAULT 'personal'");
    debugPrint("Migration v4: Added user_type column");
  } catch (e) {
    debugPrint("Migration v4: user_type column already exists or error: $e");
  }

  try {
    // Add business_name column for large scale business users
    await database
        .execute("ALTER TABLE users ADD COLUMN business_name TEXT NULL");
    debugPrint("Migration v4: Added business_name column");
  } catch (e) {
    debugPrint(
        "Migration v4: business_name column already exists or error: $e");
  }

  try {
    // Add business_registration_number column for large scale business users
    await database.execute(
        "ALTER TABLE users ADD COLUMN business_registration_number TEXT NULL");
    debugPrint("Migration v4: Added business_registration_number column");
  } catch (e) {
    debugPrint(
        "Migration v4: business_registration_number column already exists or error: $e");
  }

  // Create default admin user if it doesn't exist
  try {
    var existingAdmin = await database.query(
      "users",
      where: "user_type = ? AND email = ?",
      whereArgs: ["admin", "admin@expensesage.com"],
    );

    if (existingAdmin.isEmpty) {
      // Create default admin user with proper password hashing
      String salt = _generateSalt();
      String passwordHash = _hashPassword("admin123", salt);
      String saltedHash = '$salt:$passwordHash';

      await database.insert("users", {
        "email": "admin@expensesage.com",
        "username": "Admin",
        "password_hash": saltedHash,
        "user_type": "admin",
        "created_at": DateTime.now().toIso8601String(),
        "updated_at": DateTime.now().toIso8601String(),
        "is_active": 1,
        "two_factor_enabled": 0,
      });
      debugPrint(
          "Migration v4: Created default admin user with email: admin@expensesage.com");
    }
  } catch (e) {
    debugPrint("Migration v4: Error creating admin user: $e");
  }

  debugPrint("Migration v4: Completed successfully");
}

// Migration to fix admin user password hash
void v5(Database database) async {
  debugPrint("Migration v5: Fixing admin user password hash....");

  try {
    // Delete existing admin user if it exists
    await database.delete(
      "users",
      where: "user_type = ? AND email = ?",
      whereArgs: ["admin", "admin@expensesage.com"],
    );
    debugPrint("Migration v5: Deleted existing admin user");

    // Create admin user with proper password hashing
    String salt = _generateSalt();
    String passwordHash = _hashPassword("admin123", salt);
    String saltedHash = '$salt:$passwordHash';

    await database.insert("users", {
      "email": "admin@expensesage.com",
      "username": "Admin",
      "password_hash": saltedHash,
      "user_type": "admin",
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
      "is_active": 1,
      "two_factor_enabled": 0,
    });
    debugPrint("Migration v5: Created admin user with correct password hash");
  } catch (e) {
    debugPrint("Migration v5: Error fixing admin user: $e");
  }

  debugPrint("Migration v5: Completed successfully");
}
