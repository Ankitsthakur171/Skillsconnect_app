import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';

class JoinInterview {
  final bool ok;
  final String? url;
  final String? message;
  final Map<String, dynamic>? raw;

  JoinInterview({required this.ok, this.url, this.message, this.raw});
}

class JoinInterviewApi {
  static const String _endpoint =
      '${ApiConstantsStu.subUrl}interview-room/join-interview';

  static Future<JoinInterview> joinInterview({
    required String meetingId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Cookie': _buildCookie(authToken: authToken, connectSid: connectSid),
      };

      final reqBody = jsonEncode({"meeting_id": meetingId});
      final resp = await http.post(Uri.parse(_endpoint), headers: headers, body: reqBody);

      if (resp.statusCode != 200) {
        return JoinInterview(
          ok: false,
          message: 'Join failed: HTTP ${resp.statusCode}',
        );
      }

      Map<String, dynamic> body;
      try {
        body = jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return JoinInterview(
          ok: false,
          message: 'Invalid server response',
        );
      }

      String? url = _firstNonEmptyString(
        body['url'],
        body['meeting_url'],
        body['meetingLink'],
        body['meeting_link'],
        body['data'] is Map ? (body['data']['url'] ?? body['data']['meeting_link']) : null,
      );

      final bool statusTrue = _isTrue(body['status']) || _isTrue(body['success']);

      if (statusTrue && url != null && url.trim().isNotEmpty) {
        return JoinInterview(ok: true, url: url, raw: body);
      }

      final msg = _firstNonEmptyString(
        body['message'],
        body['msg'],
        body['error'],
      ) ??
          'Unable to get meeting link';

      return JoinInterview(ok: false, message: msg, raw: body);
    } catch (e) {
      return JoinInterview(ok: false, message: 'Join exception: $e');
    }
  }

  static String _buildCookie({required String authToken, required String connectSid}) {
    // Send both if available (server will ignore unknown)
    final parts = <String>[];
    if (authToken.isNotEmpty) parts.add('authToken=$authToken');
    if (connectSid.isNotEmpty) parts.add('connect.sid=$connectSid');
    return parts.join('; ');
  }

  static bool _isTrue(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true' || v.toLowerCase() == 'success';
    if (v is num) return v != 0;
    return false;
  }

  static String? _firstNonEmptyString(dynamic a, [dynamic b, dynamic c, dynamic d, dynamic e]) {
    for (final v in [a, b, c, d, e]) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
