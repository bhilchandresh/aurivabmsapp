class CompanySession {
  final String companyId;
  final String companyName;
  final String logo;
  final String branchId;
  final String branchName;
  final String fiscalYear;
  final String subscriptionPlan;
  final String currency;
  final String timezone;
  final String language;

  CompanySession({
    required this.companyId,
    required this.companyName,
    required this.logo,
    required this.branchId,
    required this.branchName,
    required this.fiscalYear,
    required this.subscriptionPlan,
    required this.currency,
    required this.timezone,
    required this.language,
  });

  factory CompanySession.fromJson(Map<String, dynamic> json) {
    return CompanySession(
      companyId: json['_id'] ?? json['id'] ?? json['companyId'] ?? '',
      companyName: json['name'] ?? json['companyName'] ?? '',
      logo: json['logo'] ?? json['logoImage'] ?? '',
      branchId: json['branchId'] ?? '',
      branchName: json['branchName'] ?? '',
      fiscalYear: json['fiscalYear'] ?? '',
      subscriptionPlan: json['subscriptionPlan'] ?? 'free',
      currency: json['currency'] ?? 'INR',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'logo': logo,
      'branchId': branchId,
      'branchName': branchName,
      'fiscalYear': fiscalYear,
      'subscriptionPlan': subscriptionPlan,
      'currency': currency,
      'timezone': timezone,
      'language': language,
    };
  }
}
