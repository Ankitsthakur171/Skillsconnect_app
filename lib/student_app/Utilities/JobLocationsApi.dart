import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class JobLocationsApi {
  static Future<List<Map<String, dynamic>>> fetchLocationsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      throw Exception("No auth token found. Please login again.");
    }

    final url = Uri.parse(ApiConstantsStu.jobLocationApi);
    print("Fetching locations from: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken',
        },
      ).timeout(const Duration(seconds: 15));

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print("Locations API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List raw = data['data'] as List;
          final List<Map<String, dynamic>> normalized = raw.map<Map<String, dynamic>>((e) {
            if (e is Map) {
              final mapItem = Map<String, dynamic>.from(e);
              final dynamic rawId = mapItem['id'] ?? mapItem['location_id'] ?? mapItem['city_id'];
              final int? id = rawId == null ? null : int.tryParse(rawId.toString());
              final String name = (mapItem['name'] ?? mapItem['city_name'] ?? mapItem['location_name'] ?? mapItem['label'] ?? '').toString().trim();
              return {'id': id, 'name': name, ...mapItem};
            } else {
              return {'id': null, 'name': e.toString().trim()};
            }
          }).where((m) => (m['name'] as String).isNotEmpty).toList();

          print("Loaded ${normalized.length} locations (raw)");
          return normalized;
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("JobLocationsApi Error: $e");
      rethrow;
    }
  }

  static Future<List<String>> fetchLocationNames() async {
    final raw = await fetchLocationsRaw();
    final Set<String> unique = raw.map((m) => (m['name'] as String).trim()).where((s) => s.isNotEmpty).toSet();
    final sorted = ['All Locations', ...unique.toList()..sort()];
    return sorted;
  }
}
