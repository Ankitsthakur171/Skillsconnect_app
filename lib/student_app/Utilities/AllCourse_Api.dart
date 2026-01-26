import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class CourseListApi {
  static Future<List<Map<String, String>>> fetchCoursesWithIds({
    int page = 1,
    String? query,
    String? degreeId,
    required String authToken,
    required String connectSid,
    int limit = 11,
  }) async {
    try {
      final url = Uri.parse(ApiConstantsStu.all_courses);
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final offset = (page - 1) * limit;

      final bodyMap = <String, dynamic>{
        'course_name': query ?? '',
        'limit': limit,
        'offset': offset,
      };

      if (degreeId != null && degreeId.isNotEmpty) {
        bodyMap['degree_id'] = degreeId;
      }

      final body = jsonEncode(bodyMap);

      final response = await http.post(url, headers: headers, body: body).timeout(
        const Duration(seconds: 10),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      final resBody = response.body;
      print('🔍 AllCourse_Api response: $resBody');

      if (response.statusCode != 200) {
        print('❌ Course API failed: ${response.statusCode} - ${response.reasonPhrase}');
        return [];
      }

      final data = json.decode(resBody);
      if (data is! Map || data['status'] != true || data['data'] is! List) {
        print('⚠️ Unexpected course response structure. Response: $resBody');
        return [];
      }

      final options = data['data'] as List;
      final mapped = options.map<Map<String, String>>((item) {
        final id = (item['id'] ?? '').toString();
        final text = (item['course_name'] ?? '').toString();
        return {'id': id, 'text': text};
      }).where((m) => (m['text'] ?? '').isNotEmpty).toList();

      return mapped;
    } catch (e, st) {
      print('❌ Error fetching courses: $e\n$st');
      return [];
    }
  }
}
