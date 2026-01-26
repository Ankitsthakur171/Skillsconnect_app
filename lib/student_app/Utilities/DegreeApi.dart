import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class DegreeApi {
  static Future<List<Map<String, dynamic>>> fetchDegrees({
    String? authToken,
    String? connectSid,
    int limit = 100,
  }) async {
    try {
      if ((authToken == null || authToken.isEmpty) || (connectSid == null || connectSid.isEmpty)) {
        final prefs = await SharedPreferences.getInstance();
        authToken = (authToken == null || authToken.isEmpty) ? (prefs.getString('authToken') ?? '') : authToken;
        connectSid = (connectSid == null || connectSid.isEmpty) ? (prefs.getString('connectSid') ?? '') : connectSid;
      }

      final uri = Uri.parse(ApiConstantsStu.degreeTypeApi);

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken.isNotEmpty || (connectSid != null && connectSid.isNotEmpty)) {
        final cookieParts = <String>[];
        if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
        if (connectSid != null && connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
        headers['Cookie'] = cookieParts.join('; ');
      }
      final body = jsonEncode({"limit": limit});
      final resp = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 12));

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: resp.statusCode);

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['status'] == true && decoded['data'] is List) {
          final List data = decoded['data'] as List;
          final out = data.map<Map<String, dynamic>>((e) {
            return {
              'id': e['id'],
              'degree_name': e['degree_name']?.toString() ?? '',
              'raw': e,
            };
          }).where((m) => (m['degree_name'] as String).isNotEmpty).toList();
          return out;
        }
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
