import 'package:flutter/cupertino.dart';

class ProfileModel {
  final String fullname;
  final String firstname;
  final String lastname;
  final String role;
  final String gender;
  final String phone;
  final String whatsapp;
  final String email;
  final String location;
  final String linkedin;
  final String imageUrl;
  final int profileCompletion;

  ProfileModel({
    required this.fullname,
    required this.firstname,
    required this.lastname,
    required this.role,
    required this.gender,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.location,
    required this.linkedin,
    required this.imageUrl,
    required this.profileCompletion,
  });
}





// lib/model/payment_transaction_model.dart
class PaymentTransaction {
  final String transactionId;
  final int netAmount;          // paise me nahi, given string ko int (₹) me parse kiya hai
  final String status;          // Success / Pending / Failed
  final String paymentMode;     // Online/Offline
  final String paymentType;     // Online/Offline
  final DateTime createdOn;

  PaymentTransaction({
    required this.transactionId,
    required this.netAmount,
    required this.status,
    required this.paymentMode,
    required this.paymentType,
    required this.createdOn,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    DateTime _toDate(dynamic v) {
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) {}
      }
      return DateTime.now();
    }

    return PaymentTransaction(
      transactionId: (j['transaction_id'] ?? '').toString(),
      // API me key "net_amout" (typo) hai → handle:
      netAmount: _toInt(j['net_amout']),
      status: (j['transaction_status'] ?? '').toString(),
      paymentMode: (j['payment_mode'] ?? '').toString(),
      paymentType: (j['payment_type'] ?? '').toString(),
      createdOn: _toDate(j['created_on']),
    );
  }
}









class CompanyDetailsResponse {
  final List<CompanyDetail> companyDetails;
  final List<StateItem> states;

  CompanyDetailsResponse({required this.companyDetails, required this.states});

  factory CompanyDetailsResponse.fromRootJson(Map<String, dynamic> root) {
    // Some APIs: { status:true, data:{ companyDetails:[], states:[] } }
    // Others:    { status:true, companyDetails:[], states:[] }
    final Map<String, dynamic> data =
    (root['data'] is Map<String, dynamic>) ? root['data'] as Map<String, dynamic> : root;

    // Convert only real List to List; anything else (bool/null/string) → []
    List<dynamic> _asList(dynamic v) => (v is List) ? v : const [];

    // Try common keys & aliases
    final cdRaw = _asList(
        data['companyDetails'] ??
            data['company_details'] ??
            data['company'] ??
            data['details']
    );

    final stRaw = _asList(
        data['states'] ??
            data['state'] ??
            data['state_list'] ??
            data['stateList']
    );

    final companies = cdRaw
        .whereType<Map>()
        .map((e) => CompanyDetail.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final states = stRaw
        .whereType<Map>()
        .map((e) => StateItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (companies.isEmpty) {
      debugPrint('! companyDetails not found in response or not a list');
    }
    if (states.isEmpty) {
      debugPrint('! states not found in response or not a list');
    }

    return CompanyDetailsResponse(companyDetails: companies, states: states);
  }
}

// class CompanyDetailsResponse {
//   final List<CompanyDetail> companyDetails;
//   final List<StateItem> states;
//
//   CompanyDetailsResponse({required this.companyDetails, required this.states});
//
//   factory CompanyDetailsResponse.fromRootJson(Map<String, dynamic> root) {
//     final data = (root['data'] as Map?) ?? {};
//     final cd = (data['companyDetails'] as List?) ?? [];
//     final st = (data['state'] as List?) ?? [];
//     return CompanyDetailsResponse(
//       companyDetails: cd.map((e) => CompanyDetail.fromJson(Map<String, dynamic>.from(e))).toList(),
//       states: st.map((e) => StateItem.fromJson(Map<String, dynamic>.from(e))).toList(),
//     );
//   }
// }

class CompanyDetail {
  final int? id;
  final String? companyName;
  final String? slug;
  final String? companyProfile; // description
  final String? executiveName;
  final String? website;
  final String? companySize;
  final String? email;
  final String? mobile;
  final String? address;
  final String? companyLogo;
  final String? bannerType;
  final String? banner;
  final String? founder;
  final String? establishedIn;
  final String? headquarter;
  final String? industryType;
  final String? keyPeople;
  final String? financialRevenue;
  final int? countryId;
  final int? stateId;
  final int? cityId;
  final String? pincode;

  CompanyDetail({
    this.id,
    this.companyName,
    this.slug,
    this.companyProfile,
    this.executiveName,
    this.website,
    this.companySize,
    this.email,
    this.mobile,
    this.address,
    this.companyLogo,
    this.bannerType,
    this.banner,
    this.founder,
    this.establishedIn,
    this.headquarter,
    this.industryType,
    this.keyPeople,
    this.financialRevenue,
    this.countryId,
    this.stateId,
    this.cityId,
    this.pincode,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    return CompanyDetail(
      id: json['id'] as int?,
      companyName: json['company_name']?.toString(),
      slug: json['slug']?.toString(),
      companyProfile: json['company_profile']?.toString() ?? '',
      executiveName: json['executive_name']?.toString(),
      website: json['website']?.toString(),
      companySize: json['company_size']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      address: json['company_address']?.toString(),
      companyLogo: json['company_logo']?.toString(),
      bannerType: json['banner_type']?.toString(),
      banner: json['banner']?.toString(),
      founder: json['founder']?.toString(),
      establishedIn: json['established_in']?.toString(),
      headquarter: json['headquarter']?.toString(),
      industryType: json['industry_type']?.toString(),
      keyPeople: json['key_people']?.toString(),
      financialRevenue: json['financial_revenue']?.toString(),
      countryId: json['country_id'] is int ? json['country_id'] : int.tryParse('${json['country_id'] ?? ''}'),
      stateId: json['state_id'] is int ? json['state_id'] : int.tryParse('${json['state_id'] ?? ''}'),
      cityId: json['city_id'] is int ? json['city_id'] : int.tryParse('${json['city_id'] ?? ''}'),
      pincode: json['pincode']?.toString(),
    );
  }
}

class StateItem {
  final int id;
  final String name;

  StateItem({required this.id, required this.name});

  factory StateItem.fromJson(Map<String, dynamic> json) {
    return StateItem(
      id: (json['id'] is int) ? json['id'] : int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}




class PackageFeature {
  final int id;
  final String moduleName;               // e.g. "College Invitation"
  final String packageName;             // e.g. "MSME / Mid Corporates"
  final String featureSlug;             // e.g. "invitation-per-job"
  final int totalNumber;                // package_features_total_number
  final int usedNumber;                 // package_features_used_number
  final int remainingNumber;            // package_features_remaining_number
  final DateTime? startDate;
  final DateTime? endDate;

  const PackageFeature({
    required this.id,
    required this.moduleName,
    required this.packageName,
    required this.featureSlug,
    required this.totalNumber,
    required this.usedNumber,
    required this.remainingNumber,
    this.startDate,
    this.endDate,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try { return DateTime.parse(v); } catch (_) {}
    }
    return null;
  }

  factory PackageFeature.fromJson(Map<String, dynamic> j) {
    return PackageFeature(
      id: _toInt(j['id']),
      moduleName: (j['module_name'] ?? '').toString(),
      packageName: (j['package_name'] ?? '').toString(),
      featureSlug: (j['package_feature_slug'] ?? '').toString(),
      totalNumber: _toInt(j['package_features_total_number']),
      usedNumber: _toInt(j['package_features_used_number']),
      remainingNumber: _toInt(j['package_features_remaining_number']),
      startDate: _toDate(j['start_date']),
      endDate: _toDate(j['end_date']),
    );
  }

  /// In your screenshot, some features show ✓ instead of numbers.
  /// We’ll treat `totalNumber == 0` as an “included”/boolean feature.
  bool get isIncludedFeature => totalNumber == 0;
}
