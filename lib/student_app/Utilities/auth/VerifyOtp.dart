import 'dart:convert';
import 'package:http/http.dart' as http;

import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

Future<Map<String, dynamic>> VerifyOtp(String email, String Otp) async {
  final url = Uri.parse(
    ApiConstantsStu.verify_otp,
  );
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({"email": email.trim(), "otp": int.tryParse(Otp)});
  try {
    final response = await http.post(url, headers: headers, body: body);
    final responsedata = jsonDecode(response.body);

    // 🔸 Scan for session issues (401 logout)
    await SessionGuard.scan(statusCode: response.statusCode);

    if (response.statusCode == 200) {
      return {
        "success": true,
        "message": responsedata['message'] ?? "OTP verified successfully",
      };
    } else {
      return {
        "success": false,
        "message": responsedata['message'] ?? "Invalid OTP",
      };
    }
  } catch (e) {
    return {"success": false, "message": "Error verifying OTP: $e"};
  }
}
