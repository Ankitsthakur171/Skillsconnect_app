import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class BoardApi {
  static Future<List<Map<String, dynamic>>> fetchBoards({
    String? authToken,
    String? connectSid,
    int limit = 50,
  }) async {
    try {
      if ((authToken == null || authToken.isEmpty) || (connectSid == null || connectSid.isEmpty)) {
        final prefs = await SharedPreferences.getInstance();
        authToken = (authToken == null || authToken.isEmpty) ? (prefs.getString('authToken') ?? '') : authToken;
        connectSid = (connectSid == null || connectSid.isEmpty) ? (prefs.getString('connectSid') ?? '') : connectSid;
      }

      final List<Map<String, dynamic>> out = [];
      int offset = 0;

      while (true) {
        final uri = Uri.parse('${ApiConstantsStu.subUrl}master/boards/list');
        final headers = <String, String>{'Content-Type': 'application/json'};
        final cookieParts = <String>[];
        if (authToken != null && authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
        if (connectSid != null && connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
        if (cookieParts.isNotEmpty) headers['Cookie'] = cookieParts.join('; ');

        final body = jsonEncode({'board_name': '', 'limit': limit, 'offset': offset});

        final resp = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 12));

        // 🔸 Scan for session issues (401 logout)
        await SessionGuard.scan(statusCode: resp.statusCode);

        if (resp.statusCode != 200) break;
        final decoded = jsonDecode(resp.body);
        if (decoded is! Map) break;
        if (decoded['status'] != true) break;
        final data = decoded['data'];
        if (data is! List) break;

        for (final item in data) {
          out.add({
            'id': item['id'],
            'board_name': (item['board_name'] ?? '').toString(),
            'raw': item,
          });
        }

        if (data.length < limit) break;
        offset += limit;
      }

      return out;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
