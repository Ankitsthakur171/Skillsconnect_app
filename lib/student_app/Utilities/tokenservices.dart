import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      print('❌ No authToken found in SharedPreferences.');
      return null;
    } else {
      print('🔐 authToken loaded: ${token.substring(0, 20)}...');
      return token;
    }
  }

  static Future<String?> getConnectSid() async {
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getString('connectSid');

    if (sid == null || sid.isEmpty) {
      print('❌ No connect.sid found in SharedPreferences.');
      return null;
    } else {
      print('🔐 connect.sid loaded: ${sid.substring(0, 20)}...');
      return sid;
    }
  }
}
