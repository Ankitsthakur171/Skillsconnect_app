import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../ApiConstants.dart';
import '../update_fcm_token_api.dart';

class loginUser {
  static const String _loginUrl = ApiConstantsStu.loginUrl;

  static final String _requestOtpUrl = ApiConstantsStu.requestOtp;
  static const String _kAuthToken = 'authToken';
  static const String _kAuthTokenLegacy = 'auth_token';
  static const String _kConnectSid = 'connectSid';


  Future<Map<String, dynamic>> login(String username, String password,
      {String? otp}) async {
    final headers = {'Content-Type': 'application/json'};
    final bodyMap = {
      "username": username.trim(),
      "password": password,
      "LoginOTP": otp ?? "",
    };

    final requestBody = json.encode(bodyMap);

    try {
      final response = await http
          .post(Uri.parse(_loginUrl), headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 15));

      final status = response.statusCode;
      final rawBody = response.body;
      final rawCookie = response.headers['set-cookie'] ?? '';

      Map<String, dynamic> bodyJson = {};
      try {
        final decoded = json.decode(rawBody);
        if (decoded is Map<String, dynamic>) bodyJson = decoded;
      } catch (_) {
      }

      final token = (bodyJson['token'] ??
          (bodyJson['data'] is Map ? bodyJson['data']['token'] : null))
          ?.toString();

      String connectSid = '';
      final match = RegExp(r'connect\.sid=([^;]+)').firstMatch(rawCookie);
      if (match != null) connectSid = match.group(1) ?? '';

      print('🔐 [LoginUserApi] Extracted Connect SID: ${connectSid.isEmpty ? "EMPTY" : "OK (${connectSid.length} chars)"}');

      if (status == 200 && token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kAuthToken, token);
        await prefs.setString(_kAuthTokenLegacy, token);
        if (connectSid.isNotEmpty) {
          await prefs.setString(_kConnectSid, connectSid);
          print('✅ [LoginUserApi] Saved Connect SID to SharedPreferences');
        } else {
          print('⚠️ [LoginUserApi] Connect SID was empty - NOT saving to SharedPreferences');
        }

        // Update FCM token after successful login
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await UpdateFcmApi.sendFcmToken(fcmToken);
          }
        } catch (e) {
          // FCM token update failed, but don't fail the login
          print('Failed to update FCM token: $e');
        }

        return {
          'success': true,
          'message': bodyJson['message']?.toString() ?? 'Login successful',
          'token': token,
          'cookie': rawCookie,
          'code': bodyJson['code']?.toString(),
        };
      }

      final msg = bodyJson['message']?.toString() ??
          (rawBody.isNotEmpty ? rawBody : 'Login failed');

      return {
        'success': false,
        'message': msg,
        'code': bodyJson['code']?.toString(),
        'cookie': rawCookie,
        'status': status,
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }


  Future<Map<String, dynamic>> requestLoginOtp(String username) async {
    final headers = {'Content-Type': 'application/json'};
    final requestBody = json.encode({"username": username.trim()});

    try {
      final response = await http
          .post(Uri.parse(_requestOtpUrl), headers: headers, body: requestBody)
          .timeout(const Duration(seconds: 15));

      final status = response.statusCode;
      final rawBody = response.body;

      Map<String, dynamic> bodyJson = {};
      try {
        final decoded = json.decode(rawBody);
        if (decoded is Map<String, dynamic>) bodyJson = decoded;
      } catch (_) {
        // ignore non-JSON
      }

      final success =
          (bodyJson['success'] == true) || (status == 200 && (bodyJson.isEmpty || bodyJson['message'] != null));

      final message = bodyJson['message']?.toString() ??
          (rawBody.isNotEmpty ? rawBody : 'OTP request failed');

      return {
        'success': success,
        'message': message,
        'status': status,
        'raw': rawBody,
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthToken) ?? prefs.getString(_kAuthTokenLegacy);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthToken);
    await prefs.remove(_kAuthTokenLegacy);
    await prefs.remove(_kConnectSid);
  }
}
