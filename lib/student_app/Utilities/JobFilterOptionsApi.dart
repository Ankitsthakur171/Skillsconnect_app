import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';

class JobFilterOptionsApi {
  static Future<Map<String, dynamic>> fetchFilterOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    print("JobFilterOptionsApi → authToken exists: ${authToken.isNotEmpty}");
    print("JobFilterOptionsApi → connectSid exists: ${connectSid.isNotEmpty}");

    if (authToken.isEmpty) {
      throw Exception("No authToken found. User not logged in?");
    }

    const String endpoint = '/dcxqyqzqpdydfk/mobile/jobs';
    final url = Uri.parse('${ApiConstantsStu.baseUrl}$endpoint');

    print("Calling API → $url");
    print(
        "Headers → authToken=***${authToken.substring(authToken.length - 8)}");
    print(
        "Headers → connect.sid=***${connectSid.length > 8 ? connectSid.substring(connectSid.length - 8) : 'short'}");

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
              if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
            },
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 15));

      print("Response Status Code: ${response.statusCode}");
      print(
          "Response Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic> && data['status'] == true) {
          final courses =
              (data['courses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final jobTypes =
              (data['job_type'] as Map?)?.cast<String, dynamic>() ?? {};

          print(
              "API Success → Courses: ${courses.length}, Job Types: ${jobTypes.keys.length}");
          print(
              "Sample course: ${courses.isNotEmpty ? courses.first['course_name'] : 'none'}");
          print(
              "Sample job type: ${jobTypes.keys.isNotEmpty ? jobTypes.keys.first : 'none'}");

          return {
            'courses': courses,
            'jobTypes': jobTypes,
          };
        } else {
          print("API returned status false or wrong format");
          throw Exception(data['msg'] ?? 'Invalid response format');
        }
      } else {
        print("HTTP Error ${response.statusCode}: ${response.reasonPhrase}");
        throw Exception("Server error ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      print("ClientException: $e");
      rethrow;
    } on TimeoutException catch (_) {
      print("Request timed out");
      throw Exception("Request timeout. Check internet connection.");
    } catch (e, stack) {
      print("Unexpected error in JobFilterOptionsApi: $e");
      print(stack);
      rethrow;
    }
  }
}
