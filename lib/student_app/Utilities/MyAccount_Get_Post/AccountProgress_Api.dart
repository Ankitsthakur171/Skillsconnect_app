import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/Percentage_bar_Model.dart';
import '../ApiConstants.dart';

class ProfileCompletionApi {
  static Future<ProfileCompletionModel?> fetchProfileCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      print("🔑 Retrieved authToken: ${authToken.isEmpty ? '❌ EMPTY' : '✅ PRESENT'}");
      print("🔑 Retrieved connectSid: ${connectSid.isEmpty ? '❌ EMPTY' : '✅ PRESENT'}");

      if (authToken.isEmpty) {
        print('❌ Missing auth token');
        return null;
      }
      final cookieHeader = connectSid.isNotEmpty
          ? 'authToken=$authToken; connect.sid=$connectSid'
          : 'authToken=$authToken';

      var headers = {
        'Cookie': cookieHeader,
      };

      var url = Uri.parse(ApiConstantsStu.accountScreenUrl);
      var request = http.Request('GET', url);
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);

        if (data['status'] == true &&
            data['personalDetails'] != null &&
            data['personalDetails'] is List &&
            (data['personalDetails'] as List).isNotEmpty) {
          return ProfileCompletionModel.fromJson(data);
        } else {
          print('⚠️ Invalid response structure: $data');
          return null;
        }

      } else {
        print('❌ Server error: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }
}
