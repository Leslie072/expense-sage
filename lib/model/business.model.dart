import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum BusinessType {
  corporation,
  llc,
  partnership,
  soleProprietorship,
  nonprofit,
  government,
}

enum BusinessStatus {
  active,
  inactive,
  suspended,
  trial,
  pending,
}

enum BusinessTier {
  starter,
  professional,
  enterprise,
  custom,
}

class Business {
  final int? id;
  final String name;
  final String legalName;
  final BusinessType type;
  final BusinessStatus status;
  final BusinessTier tier;
  final String? taxId;
  final String? registrationNumber;
  final String email;
  final String? phone;
  final String? website;
  final BusinessAddress? address;
  final BusinessContact? primaryContact;
  final BusinessSettings settings;
  final BusinessLimits limits;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final int employeeCount;
  final double monthlyRevenue;
  final String? industry;
  final String? description;
  final String? logoUrl;

  Business({
    this.id,
    required this.name,
    required this.legalName,
    required this.type,
    required this.status,
    required this.tier,
    this.taxId,
    this.registrationNumber,
    required this.email,
    this.phone,
    this.website,
    this.address,
    this.primaryContact,
    required this.settings,
    required this.limits,
    required this.createdAt,
    required this.updatedAt,
    this.trialEndsAt,
    this.subscriptionEndsAt,
    this.employeeCount = 0,
    this.monthlyRevenue = 0.0,
    this.industry,
    this.description,
    this.logoUrl,
  });

  String get typeDescription {
    switch (type) {
      case BusinessType.corporation:
        return 'Corporation';
      case BusinessType.llc:
        return 'LLC';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.soleProprietorship:
        return 'Sole Proprietorship';
      case BusinessType.nonprofit:
        return 'Non-Profit';
      case BusinessType.government:
        return 'Government';
    }
  }

  String get statusDescription {
    switch (status) {
      case BusinessStatus.active:
        return 'Active';
      case BusinessStatus.inactive:
        return 'Inactive';
      case BusinessStatus.suspended:
        return 'Suspended';
      case BusinessStatus.trial:
        return 'Trial';
      case BusinessStatus.pending:
        return 'Pending';
    }
  }

  String get tierDescription {
    switch (tier) {
      case BusinessTier.starter:
        return 'Starter';
      case BusinessTier.professional:
        return 'Professional';
      case BusinessTier.enterprise:
        return 'Enterprise';
      case BusinessTier.custom:
        return 'Custom';
    }
  }

  Color get statusColor {
    switch (status) {
      case BusinessStatus.active:
        return Colors.green;
      case BusinessStatus.inactive:
        return Colors.grey;
      case BusinessStatus.suspended:
        return Colors.red;
      case BusinessStatus.trial:
        return Colors.orange;
      case BusinessStatus.pending:
        return Colors.blue;
    }
  }

  Color get tierColor {
    switch (tier) {
      case BusinessTier.starter:
        return Colors.blue;
      case BusinessTier.professional:
        return Colors.purple;
      case BusinessTier.enterprise:
        return Colors.amber;
      case BusinessTier.custom:
        return Colors.black;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case BusinessType.corporation:
        return Symbols.corporate_fare;
      case BusinessType.llc:
        return Symbols.business;
      case BusinessType.partnership:
        return Symbols.handshake;
      case BusinessType.soleProprietorship:
        return Symbols.person;
      case BusinessType.nonprofit:
        return Symbols.volunteer_activism;
      case BusinessType.government:
        return Symbols.account_balance;
    }
  }

  bool get isTrialExpired {
    return trialEndsAt != null && DateTime.now().isAfter(trialEndsAt!);
  }

  bool get isSubscriptionExpired {
    return subscriptionEndsAt != null &&
        DateTime.now().isAfter(subscriptionEndsAt!);
  }

  bool get isActive => status == BusinessStatus.active;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'type': type.index,
      'status': status.index,
      'tier': tier.index,
      'tax_id': taxId,
      'registration_number': registrationNumber,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address?.toJson(),
      'primary_contact': primaryContact?.toJson(),
      'settings': settings.toJson(),
      'limits': limits.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'trial_ends_at': trialEndsAt?.toIso8601String(),
      'subscription_ends_at': subscriptionEndsAt?.toIso8601String(),
      'employee_count': employeeCount,
      'monthly_revenue': monthlyRevenue,
      'industry': industry,
      'description': description,
      'logo_url': logoUrl,
    };
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      name: json['name'],
      legalName: json['legal_name'],
      type: BusinessType.values[json['type']],
      status: BusinessStatus.values[json['status']],
      tier: BusinessTier.values[json['tier']],
      taxId: json['tax_id'],
      registrationNumber: json['registration_number'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      address: json['address'] != null
          ? BusinessAddress.fromJson(json['address'])
          : null,
      primaryContact: json['primary_contact'] != null
          ? BusinessContact.fromJson(json['primary_contact'])
          : null,
      settings: BusinessSettings.fromJson(json['settings']),
      limits: BusinessLimits.fromJson(json['limits']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'])
          : null,
      subscriptionEndsAt: json['subscription_ends_at'] != null
          ? DateTime.parse(json['subscription_ends_at'])
          : null,
      employeeCount: json['employee_count'] ?? 0,
      monthlyRevenue: (json['monthly_revenue'] ?? 0.0).toDouble(),
      industry: json['industry'],
      description: json['description'],
      logoUrl: json['logo_url'],
    );
  }
}

class BusinessAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  BusinessAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
  });

  String get fullAddress => '$street, $city, $state $zipCode, $country';

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
    };
  }

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
    );
  }
}

class BusinessContact {
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? title;
  final String? department;

  BusinessContact({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.title,
    this.department,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'title': title,
      'department': department,
    };
  }

  factory BusinessContact.fromJson(Map<String, dynamic> json) {
    return BusinessContact(
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      title: json['title'],
      department: json['department'],
    );
  }
}

class BusinessSettings {
  final String currency;
  final String timezone;
  final String dateFormat;
  final bool multiCurrencyEnabled;
  final bool advancedReportsEnabled;
  final bool apiAccessEnabled;
  final bool ssoEnabled;
  final List<String> allowedDomains;

  BusinessSettings({
    this.currency = 'USD',
    this.timezone = 'UTC',
    this.dateFormat = 'MM/dd/yyyy',
    this.multiCurrencyEnabled = false,
    this.advancedReportsEnabled = false,
    this.apiAccessEnabled = false,
    this.ssoEnabled = false,
    this.allowedDomains = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'timezone': timezone,
      'date_format': dateFormat,
      'multi_currency_enabled': multiCurrencyEnabled,
      'advanced_reports_enabled': advancedReportsEnabled,
      'api_access_enabled': apiAccessEnabled,
      'sso_enabled': ssoEnabled,
      'allowed_domains': allowedDomains,
    };
  }

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      currency: json['currency'] ?? 'USD',
      timezone: json['timezone'] ?? 'UTC',
      dateFormat: json['date_format'] ?? 'MM/dd/yyyy',
      multiCurrencyEnabled: json['multi_currency_enabled'] ?? false,
      advancedReportsEnabled: json['advanced_reports_enabled'] ?? false,
      apiAccessEnabled: json['api_access_enabled'] ?? false,
      ssoEnabled: json['sso_enabled'] ?? false,
      allowedDomains: List<String>.from(json['allowed_domains'] ?? []),
    );
  }
}

class BusinessLimits {
  final int maxUsers;
  final int maxTransactions;
  final int maxAccounts;
  final int maxCategories;
  final double storageLimit; // in GB
  final bool unlimitedReports;

  BusinessLimits({
    this.maxUsers = 10,
    this.maxTransactions = 1000,
    this.maxAccounts = 5,
    this.maxCategories = 50,
    this.storageLimit = 1.0,
    this.unlimitedReports = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'max_users': maxUsers,
      'max_transactions': maxTransactions,
      'max_accounts': maxAccounts,
      'max_categories': maxCategories,
      'storage_limit': storageLimit,
      'unlimited_reports': unlimitedReports,
    };
  }

  factory BusinessLimits.fromJson(Map<String, dynamic> json) {
    return BusinessLimits(
      maxUsers: json['max_users'] ?? 10,
      maxTransactions: json['max_transactions'] ?? 1000,
      maxAccounts: json['max_accounts'] ?? 5,
      maxCategories: json['max_categories'] ?? 50,
      storageLimit: (json['storage_limit'] ?? 1.0).toDouble(),
      unlimitedReports: json['unlimited_reports'] ?? false,
    );
  }

  static BusinessLimits getDefaultLimits(BusinessTier tier) {
    switch (tier) {
      case BusinessTier.starter:
        return BusinessLimits(
          maxUsers: 5,
          maxTransactions: 500,
          maxAccounts: 3,
          maxCategories: 25,
          storageLimit: 0.5,
          unlimitedReports: false,
        );
      case BusinessTier.professional:
        return BusinessLimits(
          maxUsers: 25,
          maxTransactions: 5000,
          maxAccounts: 10,
          maxCategories: 100,
          storageLimit: 5.0,
          unlimitedReports: true,
        );
      case BusinessTier.enterprise:
        return BusinessLimits(
          maxUsers: 100,
          maxTransactions: 50000,
          maxAccounts: 50,
          maxCategories: 500,
          storageLimit: 50.0,
          unlimitedReports: true,
        );
      case BusinessTier.custom:
        return BusinessLimits(
          maxUsers: -1, // Unlimited
          maxTransactions: -1,
          maxAccounts: -1,
          maxCategories: -1,
          storageLimit: -1,
          unlimitedReports: true,
        );
    }
  }
}
