
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/WorkExperience_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class WorkExperienceApi {
  static Future<List<WorkExperienceModel>> fetchWorkExperienceApi({
    required String authToken,
    required String connectSid,
  }) async {
    try {
      var url = Uri.parse(
        ApiConstantsStu.fetchWorkExperience,
      );
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };
      var request = http.Request('GET', url);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      final String responseBody = await response.stream.bytesToString();
      await SessionGuard.scan(statusCode: response.statusCode, body: responseBody);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(responseBody);

        final List<dynamic> workExperienceList = data['workExperience'] ?? [];
        return workExperienceList
            .map((e) => WorkExperienceModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Failed to load workExperience details');
      }
    } catch (e) {
      print('❌ Error in WorkExperienceDetailApi: $e');
      return [];
    }
  }

  static Future<bool> saveWorkExperience({
    required WorkExperienceModel model,
    required String authToken,
    required String connectSid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAuthToken = prefs.getString('authToken') ?? '';
      final savedConnectSid = prefs.getString('connectSid') ?? '';


      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $savedAuthToken',
        'Cookie': 'connect.sid=$savedConnectSid',
      };

      final body = jsonEncode(model.toJson());
      print("📤 [saveWorkExperience] Request Body: $body");

      final url = Uri.parse(
        ApiConstantsStu.updateWorkExperience,
      );

      final response = await http.post(url, headers: headers, body: body);


      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print(
            "✅ [saveWorkExperience] Work Experience Saved: ${decoded['msg']}");
        return true;
      } else {
        await SessionGuard.scan(statusCode: response.statusCode, body: response.body);
        print("❌ [saveWorkExperience] Failed to save. Status: ${response.statusCode}, Response: ${response.body}");

        return false;
      }
    } catch (e) {
      print("❌ [saveWorkExperience] Exception occurred: $e");
      return false;
    }
  }

  static Future<bool> deleteWorkExperience({
    required int? workExperienceId,
    required String authToken,
    required String connectSid,
  }) async {
    var headers = {
      'Content-Type': 'application/json',
      'Cookie':
      'authToken=$authToken${connectSid.isNotEmpty ? '; connect.sid=$connectSid' : ''}',
    };

    var url = Uri.parse(
        '${ApiConstantsStu.subUrl}profile/student/delete/$workExperienceId?action=work_exp'
    );

    try {
      print('🟡 Attempting to delete Work Experience ID: $workExperienceId');
      print('🌐 Request URL: $url');

      final request = http.Request('DELETE', url)..headers.addAll(headers);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📩 Response status: ${response.statusCode}');
      print('📩 Response body: $responseBody');

      if (response.statusCode == 200) {
        print('✅ Work Experience $workExperienceId deleted successfully');
        return true;
      } else {
        await SessionGuard.scan(statusCode: response.statusCode, body: responseBody);
        print(
            '❌ Failed to delete Work Experience $workExperienceId → [${response.statusCode}]');
        return false;
      }
    } catch (e) {
      print('🚨 Exception while deleting Work Experience $workExperienceId → $e');
      return false;
    }
  }
}
