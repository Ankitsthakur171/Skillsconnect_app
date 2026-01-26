import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConstants.dart';

class DeleteApi {
  static const String _base = ApiConstantsStu.subUrl;
  static const String _deleteEndpoint = '${_base}profile/delete';

  static Future<String> _buildCookieHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final parts = <String>[];
    if (authToken.isNotEmpty) parts.add('authToken=$authToken');
    if (connectSid.isNotEmpty) parts.add('connect.sid=$connectSid');

    final cookie = parts.join('; ');
    debugPrint('DeleteApi._buildCookieHeader -> $cookie');
    return cookie;
  }

  static Map<String, dynamic>? _safeJsonDecode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> step1Request({String? reason}) async {
    final cookie = await _buildCookieHeader();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (cookie.isNotEmpty) headers['Cookie'] = cookie;

    final body = json.encode({
      'reason': reason ?? '',
      'otp': '',
      'step': 1,
    });

    debugPrint('DeleteApi.step1Request -> POST $_deleteEndpoint');
    debugPrint('Headers: $headers');
    debugPrint('Body: $body');

    try {
      final resp = await http
          .post(Uri.parse(_deleteEndpoint), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('DeleteApi.step1Request - status: ${resp.statusCode}');
      debugPrint('DeleteApi.step1Request - body: ${resp.body}');

      final parsed = resp.body.isNotEmpty ? _safeJsonDecode(resp.body) : null;
      return {
        'status': resp.statusCode,
        'body': parsed ?? resp.body,
      };
    } on TimeoutException catch (e) {
      debugPrint('DeleteApi.step1Request - timeout: $e');
      rethrow;
    } catch (e, st) {
      debugPrint('DeleteApi.step1Request - exception: $e\n$st');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> step2Request({
    required String reason,
    required String otp,
  }) async {
    final cookie = await _buildCookieHeader();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (cookie.isNotEmpty) headers['Cookie'] = cookie;

    final body = json.encode({
      'reason': reason,
      'otp': otp,
      'step': 2,
    });

    debugPrint('DeleteApi.step2Request -> POST $_deleteEndpoint');
    debugPrint('Headers: $headers');
    debugPrint('Body: $body');

    try {
      final resp = await http
          .post(Uri.parse(_deleteEndpoint), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('DeleteApi.step2Request - status: ${resp.statusCode}');
      debugPrint('DeleteApi.step2Request - body: ${resp.body}');

      final parsed = resp.body.isNotEmpty ? _safeJsonDecode(resp.body) : null;
      return {
        'status': resp.statusCode,
        'body': parsed ?? resp.body,
      };
    } on TimeoutException catch (e) {
      debugPrint('DeleteApi.step2Request - timeout: $e');
      rethrow;
    } catch (e, st) {
      debugPrint('DeleteApi.step2Request - exception: $e\n$st');
      rethrow;
    }
  }
}
