import 'package:shared_preferences/shared_preferences.dart';

class StudentAuth {
  static const String _authTokenKey = 'auth_token'; // HR/TPO format
  static const String _legacyAuthTokenKey = 'authToken'; // Legacy student format
  static const String _legacyConnectSidKey = 'connectSid'; // Legacy student format

  /// Get the authentication token (prefers HR/TPO format, falls back to legacy)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Try HR/TPO format first
    var token = prefs.getString(_authTokenKey);
    if (token != null && token.isNotEmpty) return token;
    // Fall back to legacy format
    return prefs.getString(_legacyAuthTokenKey);
  }

  /// Get legacy auth token (for backward compatibility)
  static Future<String?> getLegacyAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_legacyAuthTokenKey);
  }

  /// Get legacy connect.sid (for backward compatibility)
  static Future<String?> getLegacyConnectSid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_legacyConnectSidKey);
  }

  /// Get authentication headers for API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  /// Get legacy cookie headers (for backward compatibility)
  static Future<Map<String, String>> getLegacyCookieHeaders() async {
    final authToken = await getLegacyAuthToken();
    final connectSid = await getLegacyConnectSid();
    final headers = <String, String>{'Content-Type': 'application/json'};

    final cookieParts = <String>[];
    if (authToken != null && authToken.isNotEmpty) {
      cookieParts.add('authToken=$authToken');
    }
    if (connectSid != null && connectSid.isNotEmpty) {
      cookieParts.add('connect.sid=$connectSid');
    }
    if (cookieParts.isNotEmpty) {
      headers['Cookie'] = cookieParts.join('; ');
    }

    return headers;
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear authentication data
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_legacyAuthTokenKey);
    await prefs.remove(_legacyConnectSidKey);
    await prefs.remove('user_data');
    await prefs.remove('user_id');
  }
}