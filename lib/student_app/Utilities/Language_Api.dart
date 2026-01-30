
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/LanguageMaster_Model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class LanguageListApi {
  static const String _cacheKey = 'cached_languages';

  static Future<List<LanguageMasterModel>> fetchLanguages({int page = 1}) async {
    print("🔍 [LanguageListApi.fetchLanguages] START - page=$page");
    
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    
    print("🔍 [LanguageListApi] authToken: ${authToken.isNotEmpty ? 'Present (${authToken.length} chars)' : 'MISSING'}");
    print("🔍 [LanguageListApi] connectSid: ${connectSid.isNotEmpty ? 'Present (${connectSid.length} chars)' : 'MISSING'}");

    List<LanguageMasterModel> allLanguages = [];

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    final url = Uri.parse(ApiConstantsStu.languageApi);
    print("🌐 [LanguageListApi] Fetching from API: $url");
    print("🔍 [LanguageListApi] Request body: ${jsonEncode({'page': page})}");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'page': page}),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print("📥 [LanguageListApi] Response code: ${response.statusCode}");
      print("📥 [LanguageListApi] Response body length: ${response.body.length} chars");
      print("📥 [LanguageListApi] Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("🔍 [LanguageListApi] Parsing response JSON...");
        final data = jsonDecode(response.body);
        print("🔍 [LanguageListApi] Response structure keys: ${data.keys.toList()}");

        final languageData = data['data'] ?? data['languageList'];
        print("🔍 [LanguageListApi] Language data type: ${languageData.runtimeType}");
        
        if (languageData is List) {
          print("🔍 [LanguageListApi] Found ${languageData.length} languages in response");
          
          allLanguages = languageData.map((e) {
            print("🔍 [LanguageListApi] Parsing language: $e");
            return LanguageMasterModel.fromJson(e);
          }).toList();

          print("🔍 [LanguageListApi] Successfully parsed ${allLanguages.length} languages");

          if (allLanguages.isNotEmpty) {
            print("🔍 [LanguageListApi] Sample languages: ${allLanguages.take(3).map((l) => l.languageName).join(', ')}");
          }
          
          // Check for pagination info
          if (data.containsKey('pagination')) {
            print("🔍 [LanguageListApi] Pagination info: ${data['pagination']}");
          }
        } else {
          print("⚠️ [LanguageListApi] Unexpected structure - languageData is not a List");
          print("⚠️ [LanguageListApi] Full data: $data");
        }
      } else {
        print("❌ [LanguageListApi] API call failed with status: ${response.statusCode}");
        print("❌ [LanguageListApi] Error body: ${response.body}");
      }
    } catch (e, st) {
      print("🚨 [LanguageListApi] Exception occurred: $e");
      print("🚨 [LanguageListApi] Stack trace: $st");
    }

    print("🔍 [LanguageListApi.fetchLanguages] END - Returning ${allLanguages.length} languages");
    return allLanguages;
  }

  static Future<void> clearCachedLanguages() async {
    print("🧹 [LanguageListApi.clearCachedLanguages] START");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    print("✅ [LanguageListApi.clearCachedLanguages] Cleared cached languages");
  }
}
