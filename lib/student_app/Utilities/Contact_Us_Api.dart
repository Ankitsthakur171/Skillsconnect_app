import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/Contack_Us_model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class ContactApi {
  static final String _url = '${ApiConstantsStu.subUrl}contact';

  static Future<String> _buildCookieHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final parts = <String>[];
    if (authToken.isNotEmpty) parts.add('authToken=$authToken');
    if (connectSid.isNotEmpty) parts.add('connect.sid=$connectSid');

    final cookie = parts.join('; ');
    debugPrint('ContactApi._buildCookieHeader - cookie: $cookie');
    return cookie;
  }

  static Future<ContactResponse> sendContact(ContactRequest request) async {
    final cookie = await _buildCookieHeader();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (cookie.isNotEmpty) {
      headers['Cookie'] = cookie;
    }

    final body = json.encode(request.toJson());

    debugPrint('ContactApi.sendContact - URL: $_url');
    debugPrint('ContactApi.sendContact - Headers: $headers');
    debugPrint('ContactApi.sendContact - Body: $body');

    try {
      final uri = Uri.parse(_url);
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('ContactApi.sendContact - statusCode: ${response.statusCode}');
      debugPrint('ContactApi.sendContact - responseBody: ${response.body}');

      final contactResponse = ContactResponse.fromRawJson(response.body, response.statusCode);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('ContactApi.sendContact - successful: ${contactResponse.message}');
        return contactResponse;
      } else {
        // 🔴 Critical: Check for auth errors
        await SessionGuard.scan(statusCode: response.statusCode, body: response.body);
        final msg = 'API error ${response.statusCode}: ${contactResponse.message}';
        debugPrint('ContactApi.sendContact - throwing: $msg');
        throw Exception(msg);
      }
    } on TimeoutException catch (te) {
      debugPrint('ContactApi.sendContact - timeout: $te');
      throw Exception('Request timed out.');
    } on http.ClientException catch (ce) {
      debugPrint('ContactApi.sendContact - client exception: $ce');
      throw Exception('Network client error: $ce');
    } catch (e, st) {
      debugPrint('ContactApi.sendContact - unknown exception: $e\n$st');
      rethrow;
    }
  }
}
