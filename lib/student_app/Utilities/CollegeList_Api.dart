import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class ApiService {
  static Future<List<Map<String, String>>> fetchCollegeList({int page = 1, String? query}) async {
    final url = ApiConstantsStu.college_list;
    final headers = {'Content-Type': 'application/json'};
    final body = {
      "college_id": "",
      "state_id": "",
      "city_id": "",
      "course_id": "",
      "specialization_id": "",
      "search": query ?? "",
      "page": page,
    };

    try {
      final resp = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body)).timeout(Duration(seconds: 15));

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: resp.statusCode);

      if (resp.statusCode != 200) {
        debugPrint('[ApiService] fetchCollegeList status=${resp.statusCode}');
        return [];
      }
      final data = json.decode(resp.body);
      final options = (data['data']?['collegeListMaster'] is List)
          ? data['data']['collegeListMaster'] as List
          : [];

      // optional: totalCount for better hasMore detection
      // final total = data['data']?['totalCount'] ?? null;
      final List<Map<String, String>> out = options.map<Map<String, String>>((item) {
        final id = (item['id'] ?? '').toString();
        final text = (item['college_name'] ?? '').toString();
        return {'id': id, 'text': text};
      }).where((m) => (m['text'] ?? '').isNotEmpty).toList();


      debugPrint('[ApiService] fetchCollegeList page=$page query="${query ?? ''}" returned ${out.length} items');
      return out;
    } catch (e, st) {
      debugPrint('[ApiService] fetchCollegeList ERROR: $e\n$st');
      return [];
    }
  }
}

