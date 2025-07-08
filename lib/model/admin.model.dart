import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum AdminRole {
  superAdmin,
  systemAdmin,
  businessManager,
  supportAgent,
}

enum AdminPermission {
  // User Management
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,
  
  // Business Management
  viewBusinesses,
  createBusinesses,
  editBusinesses,
  deleteBusinesses,
  
  // System Administration
  viewSystemStats,
  manageDatabase,
  viewLogs,
  manageBackups,
  systemConfiguration,
  
  // Financial Data
  viewFinancialData,
  exportData,
  manageReports,
  
  // Support
  viewTickets,
  manageTickets,
  accessUserAccounts,
}

class Admin {
  final int? id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final AdminRole role;
  final List<AdminPermission> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? department;

  Admin({
    this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.profileImageUrl,
    this.phoneNumber,
    this.department,
  });

  String get fullName => '$firstName $lastName';

  String get roleDescription {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Administrator';
      case AdminRole.systemAdmin:
        return 'System Administrator';
      case AdminRole.businessManager:
        return 'Business Manager';
      case AdminRole.supportAgent:
        return 'Support Agent';
    }
  }

  Color get roleColor {
    switch (role) {
      case AdminRole.superAdmin:
        return Colors.red;
      case AdminRole.systemAdmin:
        return Colors.purple;
      case AdminRole.businessManager:
        return Colors.blue;
      case AdminRole.supportAgent:
        return Colors.green;
    }
  }

  IconData get roleIcon {
    switch (role) {
      case AdminRole.superAdmin:
        return Symbols.admin_panel_settings;
      case AdminRole.systemAdmin:
        return Symbols.settings;
      case AdminRole.businessManager:
        return Symbols.business;
      case AdminRole.supportAgent:
        return Symbols.support_agent;
    }
  }

  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  bool canManageUsers() {
    return hasPermission(AdminPermission.viewUsers) ||
           hasPermission(AdminPermission.createUsers) ||
           hasPermission(AdminPermission.editUsers) ||
           hasPermission(AdminPermission.deleteUsers);
  }

  bool canManageBusinesses() {
    return hasPermission(AdminPermission.viewBusinesses) ||
           hasPermission(AdminPermission.createBusinesses) ||
           hasPermission(AdminPermission.editBusinesses) ||
           hasPermission(AdminPermission.deleteBusinesses);
  }

  bool canAccessSystemAdmin() {
    return hasPermission(AdminPermission.viewSystemStats) ||
           hasPermission(AdminPermission.manageDatabase) ||
           hasPermission(AdminPermission.viewLogs) ||
           hasPermission(AdminPermission.manageBackups) ||
           hasPermission(AdminPermission.systemConfiguration);
  }

  static List<AdminPermission> getDefaultPermissions(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values; // All permissions
      
      case AdminRole.systemAdmin:
        return [
          AdminPermission.viewUsers,
          AdminPermission.editUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.viewSystemStats,
          AdminPermission.manageDatabase,
          AdminPermission.viewLogs,
          AdminPermission.manageBackups,
          AdminPermission.systemConfiguration,
          AdminPermission.viewFinancialData,
          AdminPermission.exportData,
          AdminPermission.manageReports,
        ];
      
      case AdminRole.businessManager:
        return [
          AdminPermission.viewUsers,
          AdminPermission.createUsers,
          AdminPermission.editUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.createBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.viewFinancialData,
          AdminPermission.exportData,
          AdminPermission.manageReports,
        ];
      
      case AdminRole.supportAgent:
        return [
          AdminPermission.viewUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.viewTickets,
          AdminPermission.manageTickets,
          AdminPermission.accessUserAccounts,
        ];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.index,
      'permissions': permissions.map((p) => p.index).toList(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'profile_image_url': profileImageUrl,
      'phone_number': phoneNumber,
      'department': department,
    };
  }

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: AdminRole.values[json['role']],
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((p) => AdminPermission.values[p as int])
          .toList() ?? [],
      isActive: json['is_active'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.parse(json['last_login_at'])
          : null,
      profileImageUrl: json['profile_image_url'],
      phoneNumber: json['phone_number'],
      department: json['department'],
    );
  }

  Admin copyWith({
    int? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    AdminRole? role,
    List<AdminPermission>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    String? phoneNumber,
    String? department,
  }) {
    return Admin(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
    );
  }
}

class AdminSession {
  final Admin admin;
  final String token;
  final DateTime expiresAt;
  final String ipAddress;
  final String userAgent;

  AdminSession({
    required this.admin,
    required this.token,
    required this.expiresAt,
    required this.ipAddress,
    required this.userAgent,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && admin.isActive;

  Map<String, dynamic> toJson() {
    return {
      'admin': admin.toJson(),
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      admin: Admin.fromJson(json['admin']),
      token: json['token'],
      expiresAt: DateTime.parse(json['expires_at']),
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
    );
  }
}
