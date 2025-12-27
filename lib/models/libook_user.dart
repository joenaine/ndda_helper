class LibookUser {
  final String id;
  final String name;
  final String email;
  final List<LibookGroup> groups;

  LibookUser({
    required this.id,
    required this.name,
    required this.email,
    required this.groups,
  });

  factory LibookUser.fromJson(Map<String, dynamic> json) {
    return LibookUser(
      id: json['sub'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      groups:
          (json['groups'] as List?)
              ?.map((g) => LibookGroup.fromJson(g))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': id,
      'name': name,
      'email': email,
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }

  bool get hasActiveSubscription {
    return groups.any((g) => g.isActive);
  }

  DateTime? get subscriptionExpiryDate {
    final activeSubs = groups.where((g) => g.isActive).toList();
    if (activeSubs.isEmpty) return null;
    activeSubs.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
    return activeSubs.first.expiryDate;
  }

  String get accessLevel {
    final activeSub = groups.firstWhere(
      (g) => g.isActive,
      orElse: () => LibookGroup.empty(),
    );
    return activeSub.accessLevel;
  }
}

class LibookGroup {
  final int resellerId;
  final String database;
  final String accessLevel;
  final DateTime registryDate;
  final DateTime expiryDate;
  final bool isActive;

  LibookGroup({
    required this.resellerId,
    required this.database,
    required this.accessLevel,
    required this.registryDate,
    required this.expiryDate,
    required this.isActive,
  });

  factory LibookGroup.fromJson(Map<String, dynamic> json) {
    return LibookGroup(
      resellerId: json['reseller_id'] ?? 0,
      database: json['database'] ?? '',
      accessLevel: json['accesslevel'] ?? '',
      registryDate: DateTime.parse(json['registery_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      isActive: json['is_active'] ?? false,
    );
  }

  factory LibookGroup.empty() {
    return LibookGroup(
      resellerId: 0,
      database: '',
      accessLevel: '',
      registryDate: DateTime.now(),
      expiryDate: DateTime.now(),
      isActive: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reseller_id': resellerId,
      'database': database,
      'accesslevel': accessLevel,
      'registery_date': registryDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpiringSoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }
}
