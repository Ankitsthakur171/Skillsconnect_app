import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ApiConstants.dart';

class ForgotPasswordService {
  static const String _url = ApiConstantsStu.forget_password;

  Future<Map<String, dynamic>> sendResetOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return {
          'success': true,
          'message': responseBody['message'] ?? 'OTP sent',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
