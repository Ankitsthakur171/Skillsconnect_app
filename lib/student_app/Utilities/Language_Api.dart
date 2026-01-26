
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/LanguageMaster_Model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class LanguageListApi {
  static const String _cacheKey = 'cached_languages';

  static Future<List<LanguageMasterModel>> fetchLanguages({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    List<LanguageMasterModel> allLanguages = [];

    // Check cache
    final cachedList = prefs.getStringList(_cacheKey);
    if (cachedList != null && cachedList.isNotEmpty) {
      try {
        allLanguages = cachedList
            .map((item) => LanguageMasterModel.fromJson(jsonDecode(item)))
            .toList();

        if (allLanguages.every((lang) => lang.languageId != 0)) {
          print("✅ Returning ${allLanguages.length} cached languages.");
          return allLanguages;
        } else {
          print("❌ Invalid cache, clearing.");
          await prefs.remove(_cacheKey);
        }
      } catch (e) {
        print("❌ Cache decode error: $e");
        await prefs.remove(_cacheKey);
      }
    }

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    final url = Uri.parse(ApiConstantsStu.languageApi);
    print("🌐 Fetching languages from: $url (page=$page)");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'page': page}),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print("📥 API response code: ${response.statusCode}");
      print("📥 API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final languageData = data['data'] ?? data['languageList'];
        if (languageData is List) {
          allLanguages =
              languageData.map((e) => LanguageMasterModel.fromJson(e)).toList();

          // cache valid results
          final encodedList =
          allLanguages.map((e) => jsonEncode(e.toJson())).toList();
          await prefs.setStringList(_cacheKey, encodedList);

          print("✅ Cached ${allLanguages.length} languages.");
        } else {
          print("⚠️ Unexpected structure: $data");
        }
      } else {
        print("❌ API call failed: ${response.statusCode}");
      }
    } catch (e, st) {
      print("🚨 Exception fetching languages: $e\n$st");
    }

    return allLanguages;
  }

  static Future<void> clearCachedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    print("🧹 Cleared cached languages");
  }
}
