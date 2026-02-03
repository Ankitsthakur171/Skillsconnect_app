import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../Constant/constants.dart';
import '../HR/model/company_profile_model.dart';
import '../HR/model/service_api_model.dart';


class HrProfile {

  // Fetch Profile Data
  static Future<Map<String, dynamic>> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }
    final url = Uri.parse('${BASE_URL}profile');
    final body = jsonEncode({'action': 'my_profile'});

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Send token
      },
      body: jsonEncode({'action': 'my_profile'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception("Failed to load profile");
    }
  }


  // Update data from api

  Future<bool> hrupdateProfile({
    required String firstname,
    required String lastname,
    required String email,
    required String mobile,
    required String whatsappno,
    required String linkedin,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Get token from shared preferences

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }
    
    final url = Uri.parse("${BASE_URL}profile/submit-hr-profile");

    final body = {
      "first_name": firstname,
      "last_name": lastname,
      "email": email,
      "mobile": mobile,
      "whatsappnumber": whatsappno,
      "linkedin": linkedin,
      if (gender != null) "gender": gender,
    };


    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(url, headers: headers, body: json.encode(body));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["status"] == true;
    } else {
      throw Exception("Failed to update profile");
    }
  }

 
  static Future<List<PaymentTransaction>> fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final url = Uri.parse('${BASE_URL}profile');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': 'my_transaction'}),
    );

    if (response.statusCode == 200) {
      final root = jsonDecode(response.body);
      if (root['status'] == true) {
        final data = (root['data'] as Map?) ?? {};
        // API spelling: "paymenyData" (typo), handle safely
        final list = (data['paymenyData'] as List?) ?? [];
        return list
            .map((e) => PaymentTransaction.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      } else {
        throw Exception(root['msg']?.toString() ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed with status ${response.statusCode}');
    }
  }








  // 🔵 Fetch company_detail + states
  static Future<CompanyDetailsResponse> fetchCompanyDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final url = Uri.parse('${BASE_URL}profile');
    final bodyData = {'action': 'company_detail'};

    // 🟢 Debug: Request info
    debugPrint("📤 API REQUEST: $url");
    debugPrint("🔑 Token: $token");
    debugPrint("📦 Body: ${jsonEncode(bodyData)}");

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    debugPrint("📥 STATUS CODE: ${resp.statusCode}");

    if (resp.statusCode != 200) {
      throw Exception('Failed with status ${resp.statusCode}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['status'] != true) {
      throw Exception(json['msg']?.toString() ?? 'Unknown error');
    }

    debugPrint("📦 FULL JSON RESPONSE:");
    debugPrint(const JsonEncoder.withIndent('  ').convert(json));

    // 🟡 Debug: show only companyDetails array
    final companyDetails = json['companyDetails'];
    if (companyDetails != null) {
      debugPrint("🏢 COMPANY DETAILS ARRAY:");
      debugPrint(const JsonEncoder.withIndent('  ').convert(companyDetails)); // formatted print
    } else {
      debugPrint("⚠️ companyDetails not found in response");
    }

    debugPrint("✅ API Success: Company details fetched successfully");

    return CompanyDetailsResponse.fromRootJson(json);
  }
  // static Future<CompanyDetailsResponse> fetchCompanyDetail() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('auth_token');
  //   if (token == null || token.isEmpty) {
  //     throw Exception('Token not found');
  //   }
  //
  //   final url = Uri.parse('${BASE_URL}profile');
  //   final resp = await http.post(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //     body: jsonEncode({'action': 'company_detail'}),
  //   );
  //
  //   // Debug raw
  //   print("🔵 Raw Response: ${resp.body}");
  //
  //   if (resp.statusCode != 200) {
  //     throw Exception('Failed with status ${resp.statusCode}');
  //   }
  //
  //   final json = jsonDecode(resp.body) as Map<String, dynamic>;
  //   if (json['status'] != true) {
  //     throw Exception(json['msg']?.toString() ?? 'Unknown error');
  //   }
  //
  //   return CompanyDetailsResponse.fromRootJson(json);
  // }




  // 🟢 Submit company profile (update/create)
  static Future<SubmitResult> submitCompanyProfile({
    required String companyProfile,
    required String companyName,
    required String executiveName,
    required String website,
    required String size,
    required String companyAddress,
    required String stateId,     // must be id as string
    required String cityId,      // must be id as string
    required String pincode,
    required String executiveEmail,
    required String executiveMobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return SubmitResult(false, 'Token not found');
    }

    final url = Uri.parse('${BASE_URL}profile/submit-company-profile');

    final body = {
      "action": "company-details",
      "company_profile": companyProfile,
      "company_name": companyName,
      "executive_name": executiveName,
      "website": website,
      "size": size,
      "company_address": companyAddress,
      "state_id": stateId,
      "city_id": cityId,
      "pincode": pincode,
      "executive_email": executiveEmail,
      "executive_mobile": executiveMobile,
    };

    try {
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final success = (m['success'] == true) || (m['status'] == true);
      final msg = (m['msg'] ?? m['message'] ?? '').toString();

      // Example when already present:
      // { "success": false, "msg": "Company already present!" }
      return SubmitResult(success, msg.isNotEmpty ? msg : (success ? 'Updated' : 'Failed'));
    } catch (e) {
      return SubmitResult(false, e.toString());
    }
  }







  // 🔵 Fetch current package features (action: "package")
  static Future<List<PackageFeature>> fetchCurrentPackageFeatures() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Token not found');
    }

    final url = Uri.parse('${BASE_URL}profile');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': 'package'}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed with status ${resp.statusCode}');
    }

    final root = jsonDecode(resp.body) as Map<String, dynamic>;
    if (root['status'] != true) {
      throw Exception((root['msg'] ?? 'Unknown error').toString());
    }

    final data = (root['data'] as Map?) ?? {};
    final list = (data['CurrentPackage'] as List?) ?? [];

    return list
        .map((e) => PackageFeature.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }











  static const _deleteUrl =
      '${BASE_URL}profile/delete';

  /// STEP 1: trigger OTP (send ONLY step=1)
  static Future<SubmitResult> deleteAccountStep1() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return SubmitResult(false, 'Token not found');
    }

    try {
      final resp = await http.post(
        Uri.parse(_deleteUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"step": 1}), // only step=1
      );

      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final ok = m['status'] == true;
      final msg = (m['msg'] ?? '').toString();
      return SubmitResult(ok, msg.isNotEmpty ? msg : (ok ? 'OTP sent' : 'Failed'));
    } catch (e) {
      return SubmitResult(false, e.toString());
    }
  }

  /// STEP 2: submit reason + otp (send step=2 + reason + otp)
  static Future<SubmitResult> deleteAccountStep2({
    required String reason,
    required String otp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      return SubmitResult(false, 'Token not found');
    }

    try {
      final resp = await http.post(
        Uri.parse(_deleteUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "reason": reason,
          "otp": otp,
          "step": 2,
        }),
      );

      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final ok = m['status'] == true;
      final msg = (m['msg'] ?? '').toString();
      return SubmitResult(ok, msg.isNotEmpty ? msg : (ok ? 'Account deleted successfully' : 'Failed'));
    } catch (e) {
      return SubmitResult(false, e.toString());
    }
  }

}


class SubmitResult {
  final bool ok;
  final String message;
  SubmitResult(this.ok, this.message);
}