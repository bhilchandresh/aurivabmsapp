class TenantModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? website;
  final String? address;
  final String status;
  final String subscriptionPlan;
  final DateTime? subscriptionEnd;
  final bool gstEnabled;
  final String? gstNumber;
  final String templatePreference;
  final String quotationTemplate;

  TenantModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.website,
    this.address,
    required this.status,
    required this.subscriptionPlan,
    this.subscriptionEnd,
    required this.gstEnabled,
    this.gstNumber,
    this.templatePreference = 'standard',
    this.quotationTemplate = 'standard',
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
      status: json['status'] ?? 'active',
      subscriptionPlan: json['subscriptionPlan'] ?? 'basic',
      subscriptionEnd: json['subscriptionEnd'] != null
          ? DateTime.tryParse(json['subscriptionEnd'])
          : null,
      gstEnabled: json['gstEnabled'] ?? false,
      gstNumber: json['gstNumber'],
      templatePreference: json['templatePreference'] ?? 'standard',
      quotationTemplate: json['quotationTemplate'] ?? 'standard',
    );
  }

  int get daysLeft {
    if (subscriptionEnd == null) return 0;
    final diff = subscriptionEnd!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  bool get isExpired {
    return daysLeft <= 0;
  }
}
