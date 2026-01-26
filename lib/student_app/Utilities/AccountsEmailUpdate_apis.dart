
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConstants.dart';

class EmailOtpApi {
  static const String _sendOtpUrl =
      '${ApiConstantsStu.subUrl}profile/send-email-otp';
  static const String _verifyOtpUrl =
      '${ApiConstantsStu.subUrl}profile/verify-otp';

  static String _buildCookieHeader(String authToken, String connectSid) {
    final parts = <String>[];
    if (authToken.isNotEmpty) {
      if (!authToken.startsWith('authToken=')) {
        parts.add('authToken=$authToken');
      } else {
        parts.add(authToken);
      }
    }
    if (connectSid.isNotEmpty) {
      if (connectSid.startsWith('connect.sid=')) {
        parts.add(connectSid);
      } else if (connectSid.contains('authToken=')) {
        parts.add(connectSid);
      } else {
        parts.add('connect.sid=$connectSid');
      }
    }
    return parts.join('; ');
  }

  static Future<Map<String, dynamic>> sendEmailOtp({
    required String email,
    required String rechange,
    String? companyId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final cookieHeader = _buildCookieHeader(authToken, connectSid);

      final headers = {
        'Content-Type': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

      final body = <String, dynamic>{
        'email': email,
        'rechange': rechange,
      };
      if (companyId != null && companyId.isNotEmpty) {
        body['company_id'] = companyId;
      }

      final bodyString = jsonEncode(body);

      debugPrint('EmailOtpApi.sendEmailOtp -> url=$_sendOtpUrl');
      debugPrint('Headers: $headers');
      debugPrint('Request body: $bodyString');

      final resp = await http
          .post(Uri.parse(_sendOtpUrl), headers: headers, body: bodyString)
          .timeout(const Duration(seconds: 15));

      debugPrint('sendEmailOtp -> statusCode=${resp.statusCode}');
      debugPrint('sendEmailOtp -> raw body: ${resp.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(resp.body);
      } catch (e) {
        parsed = resp.body;
      }

      return {'status': resp.statusCode, 'body': parsed};
    } catch (e) {
      debugPrint('sendEmailOtp exception: $e');
      return {'status': 0, 'body': 'Exception: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String emailOtp,
    required String emailNew,
    required String rechange,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final cookieHeader = _buildCookieHeader(authToken, connectSid);

      final headers = {
        'Content-Type': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

      final body = {
        'email_otp': emailOtp,
        'email_new': emailNew,
        'rechange': rechange,
      };

      final bodyString = jsonEncode(body);

      debugPrint('EmailOtpApi.verifyOtp -> url=$_verifyOtpUrl');
      debugPrint('Headers: $headers');
      debugPrint('Request body: $bodyString');

      final resp = await http
          .post(Uri.parse(_verifyOtpUrl), headers: headers, body: bodyString)
          .timeout(const Duration(seconds: 15));

      debugPrint('verifyOtp -> statusCode=${resp.statusCode}');
      debugPrint('verifyOtp -> raw body: ${resp.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(resp.body);
      } catch (e) {
        parsed = resp.body;
      }

      return {'status': resp.statusCode, 'body': parsed};
    } catch (e) {
      debugPrint('verifyOtp exception: $e');
      return {'status': 0, 'body': 'Exception: $e'};
    }
  }
}
