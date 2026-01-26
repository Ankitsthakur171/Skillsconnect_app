import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'ApiConstants.dart';

class AccountsWhatsAppNumberUpdate {
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
      if (a.startsWith('authToken=')) parts.add(a);
      else parts.add('authToken=$a');
    }

    if (c.isNotEmpty) {
      if (c.startsWith('connect.sid=')) parts.add(c);
      else if (c.startsWith('authToken=')) parts.add(c);
      else parts.add('connect.sid=$c');
    }

    return parts.join('; ');
  }

  /// send OTP (for WhatsApp flow sendthru should be 'wp')
  static Future<Map<String, dynamic>> sendWhatsAppOtp({
    required String phoneNo,
    required String sendthru, // should be 'wp' for WhatsApp
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

      debugPrint('AccountsWhatsAppNumberUpdate.sendWhatsAppOtp -> url=$_sendMobileOtpUrl');
      debugPrint('Headers: $headers');
      debugPrint('Request body: $bodyString');

      final resp = await http
          .post(Uri.parse(_sendMobileOtpUrl), headers: headers, body: bodyString)
          .timeout(const Duration(seconds: 15));

      debugPrint('sendWhatsAppOtp -> statusCode=${resp.statusCode}');
      debugPrint('sendWhatsAppOtp -> raw body: ${resp.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(resp.body);
      } catch (e) {
        parsed = resp.body;
      }

      return {'status': resp.statusCode, 'body': parsed};
    } catch (e) {
      debugPrint('sendWhatsAppOtp exception: $e');
      return {'status': 0, 'body': 'Exception: $e'};
    }
  }

  /// verify OTP (for WhatsApp we include whatssapp when rechange == 'Yes' or 'New')
  static Future<Map<String, dynamic>> verifyWhatsAppOtp({
    required String mobileOtp,
    required String sendthru, // 'wp'
    required String rechange, // 'Yes' or 'New'
    String? phoneNo, // included as `whatssapp` key for WhatsApp flows
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
        'mobile_otp': mobileOtp,
        'sendthru': sendthru,
        'rechange': rechange,
      };

      // For WhatsApp flows we MUST include 'whatssapp' (server expects that param),
      // but only when verifying either current (rechange == 'Yes') or new (rechange == 'New').
      if ((rechange == 'Yes' || rechange == 'New') && phoneNo != null && phoneNo.isNotEmpty) {
        body['whatssapp'] = phoneNo;
      }

      final bodyString = jsonEncode(body);

      debugPrint('AccountsWhatsAppNumberUpdate.verifyWhatsAppOtp -> url=$_verifyOtpUrl');
      debugPrint('Headers: $headers');
      debugPrint('Request body: $bodyString');

      final resp = await http
          .post(Uri.parse(_verifyOtpUrl), headers: headers, body: bodyString)
          .timeout(const Duration(seconds: 15));

      debugPrint('verifyWhatsAppOtp -> statusCode=${resp.statusCode}');
      debugPrint('verifyWhatsAppOtp -> raw body: ${resp.body}');

      dynamic parsed;
      try {
        parsed = jsonDecode(resp.body);
      } catch (e) {
        parsed = resp.body;
      }

      return {'status': resp.statusCode, 'body': parsed};
    } catch (e) {
      debugPrint('verifyWhatsAppOtp exception: $e');
      return {'status': 0, 'body': 'Exception: $e'};
    }
  }
}
