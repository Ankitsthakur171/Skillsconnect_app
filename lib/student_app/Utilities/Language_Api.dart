
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/LanguageMaster_Model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class LanguageListApi {
  static Future<List<LanguageMasterModel>> fetchLanguages({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    List<LanguageMasterModel> allLanguages = [];

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    final url = Uri.parse(ApiConstantsStu.languageApi);
    final offset = (page - 1) * limit;

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'page': page,
          'limit': limit,
          'offset': offset,
          if (search != null && search.trim().isNotEmpty) ...{
            'search': search.trim(),
            'language_name': search.trim(),
          },
        }),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final languageData = data['data'] ?? data['languageList'];
        
        if (languageData is List) {
          allLanguages = languageData.map((e) {
            return LanguageMasterModel.fromJson(e);
          }).toList();
        }
      }
    } catch (_) {
    }
    return allLanguages;
  }

}
