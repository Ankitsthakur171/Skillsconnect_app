import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'ApiConstants.dart';

class AccountsMobileNumberUpdate {
  static const String _sendMobileOtpUrl =
      '${ApiConstantsStu.subUrl}profile/send-mobile-otp';
  static const String _verifyOtpUrl =
      '${ApiConstantsStu.subUrl}profile/verify-otp';

  static String _buildCookieHeader(String authTokenRaw, String connectSidRaw) {
    String _firstSegment(String raw) {
      if (raw.isEmpty) return '';
      return raw.split(';').first.trim();
    }

    final a = _firstSegment(authTokenRaw);
    final c = _firstSegment(connectSidRaw);

    final parts = <String>{};

    if (a.isNotEmpty) {
      if (a.startsWith('authToken=')) {
        parts.add(a);
      } else {
        parts.add('authToken=$a');
      }
    }

    if (c.isNotEmpty) {
      if (c.startsWith('connect.sid=')) {
        parts.add(c);
      } else if (c.startsWith('authToken=')) {
        parts.add(c);
      } else {
        parts.add('connect.sid=$c');
      }
    }

    return parts.join('; ');
  }

  static Future<Map<String, dynamic>> sendMobileOtp({
    required String phoneNo,
    required String sendthru,
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

      final body = {'phone_no': phoneNo, 'sendthru': sendthru};
      final bodyString = jsonEncode(body);

      debugPrint('AccountsMobileNumberUpdate.sendMobileOtp -> url=$_sendMobileOtpUrl');
      debugPrint('Headers: $headers');
      debugPrint('Request body: $bodyString');

      final resp = await http
          .post(Uri.parse(_sendMobileOtpUrl), headers: headers, body: bodyString)
          .timeout(const Duration(seconds: 15));

      debugPrint('sendMobileOtp -> statusCode=${resp.statusCode}');
      debugPrint('sendMobileOtp -> raw body: ${resp.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(resp.body);
      } catch (e) {
        parsed = resp.body;
      }

      return {'status': resp.statusCode, 'body': parsed};
    } catch (e) {
      debugPrint('sendMobileOtp exception: $e');
      return {'status': 0, 'body': 'Exception: $e'};
    }
  }

  /// verifyOtp
  /// - mobileOtp: the code entered by user
  /// - sendthru: 'mb' or 'wp'
  /// - rechange: 'Yes' (verify current) or 'New' (apply new)
  /// - phoneNo: must be provided (current number for 'Yes', new number for 'New')
  /// The server expects `whatssapp` to be present (not empty) for both step1 and step2.
  static Future<Map<String, dynamic>> verifyOtp({
    required String mobileOtp,
    required String sendthru,
    required String rechange,
    required String phoneNo,
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

      // Build body: server expects mobile_otp, sendthru, rechange, and whatssapp (not phone_no)
      final body = <String, dynamic>{
        'mobile_otp': mobileOtp,
        'sendthru': sendthru,
        'rechange': rechange,
        'whatssapp': phoneNo, // MUST BE PRESENT and NOT EMPTY per your requirement
      };

      final bodyString = jsonEncode(body);

      debugPrint('AccountsMobileNumberUpdate.verifyOtp -> url=$_verifyOtpUrl');
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
