import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class PasswordServices {
  static const String _baseurl = ApiConstantsStu.reset_password;

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseurl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "email": email,
          "otp": int.tryParse(otp),
          "password": password,
        }),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successful'};
      } else {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Exception occurred: $e'};
    }
  }
}
