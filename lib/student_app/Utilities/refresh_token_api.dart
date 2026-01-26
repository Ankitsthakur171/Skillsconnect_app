import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class RefreshTokenApi {
  static Future<String?> refresh(String refreshToken, String accessToken) async {
    final res = await http.post(
      Uri.parse('${ApiConstantsStu.subUrl}auth/refresh-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({"refreshToken": refreshToken}),
    );

    // 🔸 Scan for session issues (401 logout)
    await SessionGuard.scan(statusCode: res.statusCode);

    if (res.statusCode == 200) {
      final map = jsonDecode(res.body);
      return map['accessToken'];
    }
    return null;
  }
}
