import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/Notification_Model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class NotificationsApi {
  static const String _base = "${ApiConstantsStu.subUrl}common";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authToken.isNotEmpty) {
      headers['Authorization'] =
      authToken.toLowerCase().startsWith('bearer ') ? authToken : 'Bearer $authToken';
    }
    if (connectSid.isNotEmpty) {
      headers['Cookie'] = 'authToken=$authToken; connect.sid=$connectSid';
    }
    return headers;
  }

  static Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) async {
    final uri = Uri.parse("$_base/get-all-notifications${unreadOnly ? '?read_status=No' : ''}");
    final response = await http.get(uri, headers: await _headers());

    // 🔸 Scan for session issues (401 logout)
    await SessionGuard.scan(statusCode: response.statusCode);

    if (response.statusCode != 200) {
      throw Exception("Failed to load notifications: ${response.body}");
    }

    final decoded = json.decode(response.body);

    final dynamic data = (decoded is Map<String, dynamic>) ? decoded['data'] : null;
    List rawList;

    if (data is List) {
      rawList = data;
    } else if (data is Map && data['rows'] is List) {
      rawList = data['rows'] as List;
    } else {
      rawList = const [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  static Future<void> markAsRead(int id) async {
    final uri = Uri.parse("$_base/update-notification-read-status");
    final body = json.encode({
      "notification_id": id.toString(),
      "read_status": "Yes",
    });

    final response = await http.post(uri, headers: await _headers(), body: body);

    // 🔸 Scan for session issues (401 logout)
    await SessionGuard.scan(statusCode: response.statusCode);

    if (response.statusCode != 200) {
      throw Exception("Failed to mark notification as read: ${response.body}");
    }
  }
}
