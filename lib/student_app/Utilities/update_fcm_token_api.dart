import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';

class UpdateFcmApi {
  static const _endpoint =
      '${ApiConstantsStu.subUrl}common/update-fcm-token';

  static Future<void> sendFcmToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastSent = prefs.getString('last_sent_fcm_token') ?? '';
      if (lastSent.isNotEmpty && lastSent == fcmToken) {
        print('FCM token unchanged — skipping POST.');
        return;
      }

      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken.isNotEmpty) {
        headers['Authorization'] = authToken.toLowerCase().startsWith('bearer ')
            ? authToken
            : 'Bearer $authToken';
      } else {
        headers['Authorization'] = 'Bearer <fallback-token-if-needed>';
      }

      if (connectSid.isNotEmpty) {
        headers['Cookie'] = 'connect.sid=$connectSid';
      } else {
        headers['Cookie'] = 'connect.sid=<fallback-cookie-if-needed>';
      }

      final url = Uri.parse(_endpoint);
      final body = jsonEncode({'fcmToken': fcmToken});

      final req = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        print('✅ FCM token updated successfully: ${resp.body}');
        await prefs.setString('last_sent_fcm_token', fcmToken);
      } else {
        print(
            '❌ Failed to update FCM token. Status: ${resp.statusCode}, Body: ${resp.body}');
      }
    } catch (e, st) {
      print('⚠️ Error sending FCM token: $e\n$st');
    }
  }
}
