import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/Internship_Projects_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class InternshipProjectApi {
  static Future<List<InternshipProjectModel>> fetchInternshipProjects({
    required String authToken,
    required String connectSid,
  }) async {
    print('🔖 [InternshipProjectApi] fetchInternshipProjects START');
    print('🔖 authToken present=${authToken.isNotEmpty}');
    print('🔖 connectSid present=${connectSid.isNotEmpty} (optional)');

    try {
      var url = Uri.parse(
       ApiConstantsStu.internshipDetails,
      );

      final cookieParts = <String>[];
      if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      final cookieHeader = cookieParts.isNotEmpty ? cookieParts.join('; ') : '';

      var headers = {
        'Content-Type': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

      print('🔖 headers=$headers');

      var request = http.Request('GET', url);
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final String jsonString = await response.stream.bytesToString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final List<dynamic> rawList = data['projectInternship'] ?? [];
        return rawList.map((e) => InternshipProjectModel.fromJson(e)).toList();
      } else {
        throw Exception(' Failed to load internship/project details');
      }
    } catch (e) {
      print(' Error in InternshipProjectApi: $e');
      return [];
    }
  }

  static Future<bool> saveInternshipProject({
    required InternshipProjectModel model,
    required String authToken,
    required String connectSid,
  }) async {
    print('🔖 [InternshipProjectApi] saveInternshipProject START');
    print('🔖 authToken present=${authToken.isNotEmpty}');
    print('🔖 connectSid present=${connectSid.isNotEmpty} (optional)');
    print('🔖 model data=${model.toJson()}');

    try {
      final cookieParts = <String>[];
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      final cookieHeader = cookieParts.isNotEmpty ? cookieParts.join('; ') : '';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };
      final body = jsonEncode(model.toJson());
      final url = Uri.parse(
         ApiConstantsStu.updateInternshipDetails
      );

      print('🔖 headers=$headers');
      print('🔖 url=$url');

      final response = await http.post(url, headers: headers, body: body);
      
      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("✅ API Success: ${decoded['msg'] ?? 'No message'}");
        return true;
      } else {
        try {
          final error = jsonDecode(response.body);
          print("❗ Server Error: ${error['msg'] ?? 'Unknown error'}");
        } catch (_) {
          print("❗ Error parsing response body: ${response.body}");
        }
        return false;
      }
    } catch (e, stack) {
      print("❌ Exception during API call: $e");
      print("🧱 StackTrace: $stack");
      return false;
    }
  }

  static Future<bool> deleteProjectInternship({
    required int internshipId,
    required String authToken,
    required String connectSid,
  }) async {
    print('🔖 [InternshipProjectApi] deleteProjectInternship START');
    print('🔖 authToken present=${authToken.isNotEmpty}');
    print('🔖 connectSid present=${connectSid.isNotEmpty} (optional)');
    print('🔖 internshipId=$internshipId');

    final cookieParts = <String>[];
    if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
    final cookieHeader = cookieParts.isNotEmpty ? cookieParts.join('; ') : '';

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
      if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    };
    var url = Uri.parse(
        '${ApiConstantsStu.subUrl}profile/student/delete/$internshipId?action=project');

    print('🔖 headers=$headers');
    print('🔖 url=$url');

    try {
      final request = http.Request('DELETE', url)..headers.addAll(headers);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);
      
      if (response.statusCode == 200) {
        print('✅ Deleted Internship ID $internshipId successfully.');
        return true;
      } else {
        print(
            '❌ Failed to delete Internship ID $internshipId: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (e) {
      print('🚨 Exception during deleteInternship: $e');
      return false;
    }
  }
}
