import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class CityListApi {
  static Future<List<String>> fetchCities({
    required String cityName,
    required String stateId,
    required String authToken,
    required String connectSid,
  }) async {
    List<String> allCities = [];
    int offset = 0;
    const int limit = 50;
    bool hasMore = true;
    int retryCount = 0;
    const int maxRetries = 3;

    try {
      while (hasMore) {
        var url = Uri.parse(ApiConstantsStu.city_list);
        var headers = {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        };

        var body = jsonEncode({
          "city_name": cityName,
          "state_id": stateId.isNotEmpty ? int.parse(stateId) : null,
          "offset": offset,
          "limit": limit,
        });
        var request = http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = body;

        final response = await request.send().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("❌ Request timed out for city '$cityName' with state ID '$stateId', offset $offset");
            return http.StreamedResponse(Stream.value([]), 408);
          },
        );

        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final data = json.decode(resBody);
          if (data is Map && data['status'] == true) {
            if (data['data'] is List) {
              List options = data['data'];
              var cities = options
                  .map<String>((item) => item['name']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toList();
              allCities.addAll(cities);

              final pagination = data['pagination'];
              final total = pagination['total'] as int;
              offset += limit;
              hasMore = offset < total;
            } else if (data['data'] == false) {
              print("⚠️ No cities found for '$cityName' with state ID '$stateId'. Check token validity.");
              return allCities;
            } else {
              print("⚠️ Unexpected 'data' format, expected List or false. Response: $resBody");
              return allCities;
            }
          } else {
            print("⚠️ Invalid response structure, expected status: true. Response: $resBody");
            return allCities;
          }
        } else if (response.statusCode == 429 && retryCount < maxRetries) {
          retryCount++;
          final delay = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          print("⚠️ Rate limit hit (429). Retrying ($retryCount/$maxRetries) after $delay...");
          await Future.delayed(delay);
          continue;
        } else {
          // 🔴 Critical: Check for auth errors
          await SessionGuard.scan(statusCode: response.statusCode, body: resBody);
          print("❌ API failed for city '$cityName' with state ID '$stateId': ${response.statusCode} - ${response.reasonPhrase}");
          print("Response body: $resBody");
          return allCities;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
      return allCities;
    } catch (e) {
      print("❌ Error fetching cities for '$cityName' with state ID '$stateId': $e");
      return allCities;
    }
  }

  // Fetch cities with pagination support (single page only)
  static Future<Map<String, dynamic>> fetchCitiesPage({
    required String cityName,
    required String stateId,
    required String authToken,
    required String connectSid,
    required int offset,
    int limit = 30,
  }) async {
    try {
      var url = Uri.parse(ApiConstantsStu.city_list);
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      var body = jsonEncode({
        "city_name": cityName,
        "state_id": stateId.isNotEmpty ? int.parse(stateId) : null,
        "offset": offset,
        "limit": limit,
      });
      
      var request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      final response = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("❌ Request timed out for city page, offset $offset");
          return http.StreamedResponse(Stream.value([]), 408);
        },
      );

      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        if (data is Map && data['status'] == true && data['data'] is List) {
          List options = data['data'] as List;
          var cities = options
              .map<String>((item) => item['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList();

          final pagination = data['pagination'] as Map? ?? {};
          final total = pagination['total'] as int? ?? 0;

          return {
            'cities': cities,
            'total': total,
            'offset': offset,
            'hasMore': offset + limit < total,
          };
        }
      } else {
        await SessionGuard.scan(statusCode: response.statusCode, body: resBody);
      }
    } catch (e) {
      print("❌ Error fetching cities page at offset $offset: $e");
    }

    return {
      'cities': [],
      'total': 0,
      'offset': offset,
      'hasMore': false,
    };
  }
}