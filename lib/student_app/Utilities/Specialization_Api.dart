// SpecializationListApi.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ApiConstants.dart';

class SpecializationListApi {
  /// Returns list of maps with id and text for each specialization.
  /// Example: [{'id':'614','text':'Fashion Design & Management'}, ...]
  static Future<List<Map<String,String>>> fetchSpecializationsWithIds({
    required String specializationName,
    required String courseId,
    required String authToken,
    required String connectSid,
  }) async {
    try {
      final url = Uri.parse(ApiConstantsStu.specializationListUrl);
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final body = jsonEncode({
        "specilization_name": specializationName,
        "course_id": courseId,
        "status": ""
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      final resBody = response.body;
      print("🔍 Specialization API response for courseId '$courseId': $resBody");

      if (response.statusCode != 200) {
        print("❌ Specialization API failed: ${response.statusCode} - ${response.reasonPhrase}");
        return [];
      }

      final data = json.decode(resBody);
      if (data is Map && data['status'] == true && data['data'] is List) {
        final options = data['data'] as List;
        final mapped = options.map<Map<String,String>>((item) {
          // Defensive: plugin different naming conventions
          final id = (item['id'] ?? item['specialization_id'] ?? item['specilization_id'] ?? '').toString();
          final text = (item['specilization_name'] ?? item['specialization_name'] ?? item['name'] ?? '').toString();
          return {'id': id, 'text': text};
        }).where((m) => (m['text'] ?? '').isNotEmpty).toList();

        return mapped;
      } else {
        print("⚠️ Unexpected specialization response format. Response: $resBody");
        return [];
      }
    } catch (e, st) {
      print("❌ Error fetching specializations for courseId '$courseId': $e\n$st");
      return [];
    }
  }
}
