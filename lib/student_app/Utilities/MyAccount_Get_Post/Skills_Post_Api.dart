import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ApiConstants.dart';

class SkillsPostApi {
  static Future<bool> updateSkills({
    required String authToken,
    required String connectSid,
    required List<String> skills,
  }) async {
    try {
      final uri = Uri.parse(ApiConstantsStu.updateSkills);

      final headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final body = jsonEncode({
        "skills": skills.join(", "),
      });

      print("📤 Sending POST request to update skills...");
      print("👉 URL: $uri");
      print("👉 Headers: $headers");
      print("👉 Body: $body");

      final request = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = body;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📩 Received response (${response.statusCode}): $responseBody");

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        final status = decoded is Map && decoded['status'] == true;
        print("✅ Skills update status: $status");
        return status;
      } else {
        print('❌ Skills POST failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Skills POST error: $e');
      return false;
    }
  }
}
