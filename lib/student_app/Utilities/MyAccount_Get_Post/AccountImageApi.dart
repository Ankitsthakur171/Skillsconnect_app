import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/AccountScreen_Image_Name_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class AccountImageApi {
  static Future<AcountScreenImageModel?> fetchAccountScreenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final response = await http.get(
        Uri.parse(ApiConstantsStu.accountScreenUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Cookie': 'connect.sid=$connectSid'
        },
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        print("✅ Full JSON AcountScreen: $jsonData");

        if (jsonData.containsKey('personalDetails')) {
          final details = jsonData['personalDetails'];
          print("📦 AcountScreen: $details");

          if (details is List && details.isNotEmpty && details[0] is Map) {
            print("🔍 First Entry: ${details[0]}");
            return AcountScreenImageModel.fromJson(details[0]);
          }
        }
      }
      else {
        print('❌ Failed: ${response.statusCode}');
      }

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);
    } catch (e) {
      print('❌ Error in fetchAccountScreenData: $e');
    }
    return null;
  }
}
