
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../ApiConstants.dart';

class LogoutApi {
  static Future<Map<String, dynamic>> logout(
      {String? token, String? connectSid}) async {
    final uri = Uri.parse(ApiConstantsStu.logout);
    try {
      if ((token == null || token.isEmpty) ||
          (connectSid == null || connectSid.isEmpty)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          token = (token == null || token.isEmpty)
              ? (prefs.getString('authToken') ?? '')
              : token;
          connectSid = (connectSid == null || connectSid.isEmpty)
              ? (prefs.getString('connectSid') ?? '')
              : connectSid;
        } catch (e) {
          return {
            'success': false,
            'message': 'Failed to read stored tokens: $e'
          };
        }
      }

      final request = http.Request('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (connectSid.isNotEmpty) {
        request.headers['Cookie'] = 'connect.sid=$connectSid';
      }

      print('🔍 [LogoutApi] POST $uri');

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final statusCode = streamedResponse.statusCode;

      print('🔍 [LogoutApi] response.statusCode: $statusCode');
      print('🔍 [LogoutApi] response.body: $responseBody');

      if (statusCode == 200) {
        try {
          final jsonData = jsonDecode(responseBody);
          return {'success': true, 'data': jsonData};
        } catch (_) {
          return {'success': true, 'data': responseBody};
        }
      } else {
        String message;
        try {
          final parsed = jsonDecode(responseBody);
          if (parsed is Map) {
            message = (parsed['message'] ??
                    parsed['msg'] ??
                    parsed['error'] ??
                    responseBody)
                .toString();
          } else {
            message = responseBody;
          }
        } catch (_) {
          message = responseBody;
        }
        return {
          'success': false,
          'status': statusCode,
          'message': message,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
