import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Utilities/ApiConstants.dart';

class JobFilterCourseApi {
  static Future<Map<String, dynamic>> fetchCourses({
    required String authToken,
    required String connectSid,
    int page = 1,
    int limit = 20,
    String query = "",
  }) async {
    try {
      final url = Uri.parse(ApiConstantsStu.all_courses);
      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final offset = (page - 1) * limit;

      final body = jsonEncode({
        "course_name": query,
        "limit": limit,
        "offset": offset
      });

      final response = await http.post(url, headers: headers, body: body);

      final res = jsonDecode(response.body);

      return {
        "items": (res["data"] as List)
            .map((e) => {
          "id": e["id"].toString(),
          "text": e["course_name"].toString(),
        })
            .toList(),
        "total": res["pagination"]["total"],
      };
    } catch (e) {
      print("❌ Error: $e");
      return {"items": [], "total": 0};
    }
  }
}
