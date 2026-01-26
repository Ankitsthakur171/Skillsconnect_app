// lib/services/company_info_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 👉 apne actual paths lagao
import '../HR/model/service_api_model.dart';
import '../utils/company_info_manager.dart';        // CompanyInfoManager (notify + cache-bust)
import '../Constant/constants.dart';               // BASE_URL

/// Centralized service: company name/logo ko refresh kare from API,
/// SharedPreferences me store kare, aur (by default) UI ko notify bhi kare.
class CompanyInfoService {
  /// API hit karke latest company info laata hai.
  /// - [notify] true ho to CompanyInfoManager ko bhi update karta hai (UI refresh).
  /// - Return: CompanyDetail? (null agar fetch/parse fail)
  static Future<CompanyDetail?> refresh({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      // user logged-out ya token missing
      return null;
    }

    final resp = await http.post(
      Uri.parse('${BASE_URL}profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': 'company_detail'}),
    );

    if (resp.statusCode != 200) {
      // 401/403 ke case me yahan token clear/redirect ka logic bhi daal sakte ho
      return null;
    }

    final root = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = (root['data']?['companyDetails'] as List?) ?? [];

    if (list.isEmpty) return null;

    final detail = CompanyDetail.fromJson(
      Map<String, dynamic>.from(list.first),
    );

    // Persist to prefs (single source of truth)
    await prefs.setString('company_name', detail.companyName ?? '');
    await prefs.setString('company_logo', detail.companyLogo ?? '');

    // UI refresh (cache-bust + notifyListeners()) — manager ke through
    if (notify) {
      await CompanyInfoManager().setCompanyData(
        detail.companyName ?? '',
        detail.companyLogo ?? '',
      );
    }

    return detail;
  }

  /// Convenience: sirf prefs update kare, UI notify NA kare (background refresh).
  static Future<CompanyDetail?> refreshSilently() =>
      refresh(notify: false);
}
