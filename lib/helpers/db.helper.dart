import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:path/path.dart";
import "package:expense_sage/helpers/migrations/migrations.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Database? database;
int? currentUserId; // Store current authenticated user ID
Future<Database>? _databaseFuture; // Cache the database initialization future

Future<Database> getDBInstance() async {
  // Return cached future if already initializing
  if (_databaseFuture != null) {
    return _databaseFuture!;
  }

  if (database == null) {
    _databaseFuture = _initializeDatabase();
    database = await _databaseFuture!;
    return database!;
  } else {
    return database!;
  }
}

Future<Database> _initializeDatabase() async {
  Database db;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop platforms
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    db = await databaseFactory.openDatabase("database.db",
        options: OpenDatabaseOptions(
            version: 4, // Updated version for admin features
            onCreate: onCreate,
            onUpgrade: onUpgrade));
  } else {
    // Mobile platforms (Android/iOS)
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'database.db');
    db = await openDatabase(dbPath,
        version: 4, onCreate: onCreate, onUpgrade: onUpgrade);
  }
  return db;
}

// Set current user for database operations
void setCurrentUser(int userId) {
  currentUserId = userId;
}

// Get current user ID
int? getCurrentUserId() {
  return currentUserId;
}

// Clear current user (logout)
void clearCurrentUser() {
  currentUserId = null;
}

typedef MigrationCallback = Function(Database database);
List<MigrationCallback> migrations = [v1, v2, v3, v4, v5];
void onCreate(Database database, int version) async {
  for (MigrationCallback callback in migrations) {
    await callback(database);
  }
}

void onUpgrade(Database database, int oldVersion, int version) async {
  for (int index = oldVersion; index < version; index++) {
    MigrationCallback callback = migrations[index];
    await callback(database);
  }
}

Future<void> resetDatabase() async {
  Database database = await getDBInstance();
  int? userId = getCurrentUserId();
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  database.delete("payments", where: "user_id = ?", whereArgs: [userId]);
  database.delete("accounts", where: "user_id = ?", whereArgs: [userId]);
  database.delete("categories", where: "user_id = ?", whereArgs: [userId]);

  await database.insert("accounts", {
    "name": "Cash",
    "icon": Icons.wallet.codePoint,
    "color": Colors.teal.value,
    "isDefault": 1,
    "user_id": userId
  });

  //prefill all categories
  List<Map<String, dynamic>> categories = [
    {"name": "Housing", "icon": Icons.house.codePoint},
    {"name": "Transportation", "icon": Icons.emoji_transportation.codePoint},
    {"name": "Food", "icon": Icons.restaurant.codePoint},
    {"name": "Utilities", "icon": Icons.category.codePoint},
    {"name": "Insurance", "icon": Icons.health_and_safety.codePoint},
    {
      "name": "Medical & Healthcare",
      "icon": Icons.medical_information.codePoint
    },
    {
      "name": "Saving, Investing, & Debt Payments",
      "icon": Icons.attach_money.codePoint
    },
    {"name": "Personal Spending", "icon": Icons.house.codePoint},
    {"name": "Recreation & Entertainment", "icon": Icons.tv.codePoint},
    {"name": "Miscellaneous", "icon": Icons.library_books_sharp.codePoint},
  ];

  int index = 0;
  for (Map<String, dynamic> category in categories) {
    await database.insert("categories", {
      "name": category["name"],
      "icon": category["icon"],
      "color": Colors.primaries[index].value,
      "user_id": userId
    });
    index++;
  }
}

// Initialize default data for new users
Future<void> initializeUserData(int userId) async {
  Database database = await getDBInstance();

  // Set current user
  setCurrentUser(userId);

  // Create default cash account
  await database.insert("accounts", {
    "name": "Cash",
    "icon": Icons.wallet.codePoint,
    "color": Colors.teal.value,
    "isDefault": 1,
    "user_id": userId
  });

  // Create default categories
  List<Map<String, dynamic>> categories = [
    {"name": "Housing", "icon": Icons.house.codePoint},
    {"name": "Transportation", "icon": Icons.emoji_transportation.codePoint},
    {"name": "Food", "icon": Icons.restaurant.codePoint},
    {"name": "Utilities", "icon": Icons.category.codePoint},
    {"name": "Insurance", "icon": Icons.health_and_safety.codePoint},
    {
      "name": "Medical & Healthcare",
      "icon": Icons.medical_information.codePoint
    },
    {
      "name": "Saving, Investing, & Debt Payments",
      "icon": Icons.attach_money.codePoint
    },
    {"name": "Personal Spending", "icon": Icons.house.codePoint},
    {"name": "Recreation & Entertainment", "icon": Icons.tv.codePoint},
    {"name": "Miscellaneous", "icon": Icons.library_books_sharp.codePoint},
  ];

  int index = 0;
  for (Map<String, dynamic> category in categories) {
    await database.insert("categories", {
      "name": category["name"],
      "icon": category["icon"],
      "color": Colors.primaries[index].value,
      "user_id": userId
    });
    index++;
  }
}

Future<String> getExternalDocumentPath() async {
  // To check whether permission is given for this app or not.
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    // If not we will ask for permission first
    await Permission.storage.request();
  }
  Directory directory = Directory("");
  if (Platform.isAndroid) {
    // Redirects it to download folder in android
    directory = Directory("/storage/emulated/0/Download");
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  final exPath = directory.path;
  await Directory(exPath).create(recursive: true);
  return exPath;
}

Future<dynamic> export() async {
  List<dynamic> accounts = await database!.query(
    "accounts",
  );
  List<dynamic> categories = await database!.query(
    "categories",
  );
  List<dynamic> payments = await database!.query(
    "payments",
  );
  Map<String, dynamic> data = {};
  data["accounts"] = accounts;
  data["categories"] = categories;
  data["payments"] = payments;

  final path = await getExternalDocumentPath();
  String name =
      "fintracker-backup-${DateTime.now().millisecondsSinceEpoch}.json";
  File file = File('$path/$name');
  await file.writeAsString(jsonEncode(data));
  return file.path;
}

Future<void> import(String path) async {
  File file = File(path);
  Map<int, int> accountsMap = {};
  Map<int, int> categoriesMap = {};

  try {
    Map<String, dynamic> data = await jsonDecode(file.readAsStringSync());
    await database!.transaction((transaction) async {
      await transaction.delete("categories", where: "id!=0");
      await transaction.delete("accounts", where: "id!=0");
      await transaction.delete("payments", where: "id!=0");

      List<dynamic> categories = data["categories"];
      List<dynamic> accounts = data["accounts"];
      List<dynamic> payments = data["payments"];

      for (Map<String, dynamic> category in categories) {
        int id0 = category["id"];
        category.remove("id");
        int id = await transaction.insert("categories", category);
        categoriesMap[id0] = id;
      }

      for (Map<String, dynamic> account in accounts) {
        int id0 = account["id"];
        account.remove("id");
        int id = await transaction.insert("accounts", account);
        accountsMap[id0] = id;
      }

      for (Map<String, dynamic> payment in payments) {
        payment.remove("id");
        payment["account"] = accountsMap[payment["account"]];
        payment["category"] = categoriesMap[payment["category"]];
        await transaction.insert("payments", payment);
      }
      return transaction;
    });
  } catch (err) {
    rethrow;
  }
}
