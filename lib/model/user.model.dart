enum UserType {
  admin,
  largeScaleBusiness,
  personal,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.admin:
        return 'Admin';
      case UserType.largeScaleBusiness:
        return 'Large Scale Business';
      case UserType.personal:
        return 'Personal';
    }
  }

  String get value {
    switch (this) {
      case UserType.admin:
        return 'admin';
      case UserType.largeScaleBusiness:
        return 'large_scale_business';
      case UserType.personal:
        return 'personal';
    }
  }

  static UserType fromString(String value) {
    switch (value) {
      case 'admin':
        return UserType.admin;
      case 'large_scale_business':
        return UserType.largeScaleBusiness;
      case 'personal':
      default:
        return UserType.personal;
    }
  }
}

class User {
  int? id;
  String email;
  String username;
  String passwordHash;
  String? securityQuestion;
  String? securityAnswerHash;
  String? twoFactorSecret;
  bool twoFactorEnabled;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;
  UserType userType;
  String? businessName; // For large scale business users
  String? businessRegistrationNumber; // For large scale business users

  User({
    this.id,
    required this.email,
    required this.username,
    required this.passwordHash,
    this.securityQuestion,
    this.securityAnswerHash,
    this.twoFactorSecret,
    this.twoFactorEnabled = false,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.userType = UserType.personal,
    this.businessName,
    this.businessRegistrationNumber,
  });

  factory User.fromJson(Map<String, dynamic> data) => User(
        id: data["id"],
        email: data["email"],
        username: data["username"],
        passwordHash: data["password_hash"],
        securityQuestion: data["security_question"],
        securityAnswerHash: data["security_answer_hash"],
        twoFactorSecret: data["two_factor_secret"],
        twoFactorEnabled: data["two_factor_enabled"] == 1,
        createdAt: DateTime.parse(data["created_at"]),
        updatedAt: DateTime.parse(data["updated_at"]),
        isActive: data["is_active"] == 1,
        userType: UserTypeExtension.fromString(data["user_type"] ?? "personal"),
        businessName: data["business_name"],
        businessRegistrationNumber: data["business_registration_number"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "username": username,
        "password_hash": passwordHash,
        "security_question": securityQuestion,
        "security_answer_hash": securityAnswerHash,
        "two_factor_secret": twoFactorSecret,
        "two_factor_enabled": twoFactorEnabled ? 1 : 0,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "is_active": isActive ? 1 : 0,
        "user_type": userType.value,
        "business_name": businessName,
        "business_registration_number": businessRegistrationNumber,
      };

  // Create a copy of user without sensitive data for UI
  User copyWithoutPassword() => User(
        id: id,
        email: email,
        username: username,
        passwordHash: '', // Empty password hash for security
        securityQuestion: securityQuestion,
        securityAnswerHash: '', // Empty security answer hash for security
        twoFactorSecret: '', // Empty 2FA secret for security
        twoFactorEnabled: twoFactorEnabled,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isActive: isActive,
      );
}
