import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/Resume_fetch_Model.dart';
import '../ApiConstants.dart';

class ResumeFetchApi {
  static Future<ResumeModel?> fetchResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');
      final connectSid = prefs.getString('connectSid');

      if (authToken == null || connectSid == null) {
        print('⚠️ Auth token or connect.sid missing');
        return null;
      }

      final headers = {
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        'Accept': 'application/json',
      };

      final url = Uri.parse(ApiConstantsStu.fetchResume);

      final response = await http.get(url, headers: headers);

      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['status'] == true && jsonMap['videoIntro'] != null && jsonMap['videoIntro'] is List) {
          final List videoIntroList = jsonMap['videoIntro'];

          if (videoIntroList.isNotEmpty) {
            final firstEntry = videoIntroList[0];
            final resumeUrl = firstEntry['resume'] as String?;
            final resumeName = firstEntry['resume_name'] as String? ?? '';

            if (resumeUrl != null && resumeUrl.startsWith('http')) {
              return ResumeModel(resume: resumeUrl, resumeName: resumeName);
            }
          }
        }

        print('⚠️ Resume info not found or invalid format');
        return null;
      } else {
        print('❌ Failed to fetch resume: ${response.statusCode} ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching resume: $e');
      return null;
    }
  }


  static Future<bool> updateResume({
    required String resumeUrl,
    required String resumeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    print('Starting resume update...');
    print('AuthToken: $authToken');
    print('ConnectSid: $connectSid');
    print('Resume URL: $resumeUrl');
    print('Resume Name: $resumeName');

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    final body = json.encode({
      'resume_url': resumeUrl,
      'resume_name': resumeName,
    });

    print('Headers: $headers');
    print('Request Body: $body');

    final request = http.Request(
      'POST',
      Uri.parse(
          ApiConstantsStu.updateResume),
    );

    request.headers.addAll(headers);
    request.body = body;

    try {
      final response = await request.send();

      print('Response status code: ${response.statusCode}');
      final respStr = await response.stream.bytesToString();
      print('Response body: $respStr');

      if (response.statusCode == 200) {
        print('✅ Resume updated successfully');
        return true;
      } else {
        print('❌ Resume update failed: ${response.statusCode} $respStr');
      }
    } catch (e, stacktrace) {
      print('❌ Resume update error: $e');
      print('Stacktrace: $stacktrace');
    }

    return false;
  }
}
