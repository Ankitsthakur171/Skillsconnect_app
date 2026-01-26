import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

import 'ApiConstants.dart';

class StateListApi {
  static Future<List<String>> fetchStates({
    required String countryId,
    required String authToken,
    required String connectSid,
  }) async {
    List<String> allStates = [];
    int offset = 0;
    const int limit = 50;
    bool hasMore = true;
    int retryCount = 0;
    const int maxRetries = 3;

    try {
      while (hasMore) {
        var url = Uri.parse(ApiConstantsStu.stateListUrl);
        var headers = {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        };

        var body = jsonEncode({
          "country_id": int.parse(countryId),
          "state_name": "",
          "offset": offset,
          "limit": limit,
        });
        var request = http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = body;

        final response = await request.send().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("❌ Request timed out for states with country ID '$countryId', offset $offset");
            return http.StreamedResponse(Stream.value([]), 408);
          },
        );

        final resBody = await response.stream.bytesToString();
        print("🔍 API Response for states with country ID '$countryId', offset $offset: $resBody");

        if (response.statusCode == 200) {
          final data = json.decode(resBody);
          if (data is Map && data['status'] == true) {
            if (data['data'] is List) {
              List options = data['data'];
              var states = options
                  .map<String>((item) => item['name']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toList();
              allStates.addAll(states);

              final pagination = data['pagination'];
              final total = pagination['total'] as int;
              offset += limit;
              hasMore = offset < total;
            } else if (data['data'] == false) {
              print("⚠️ No states found for country ID '$countryId'. Check token validity.");
              return allStates;
            } else {
              print("⚠️ Unexpected 'data' format, expected List or false. Response: $resBody");
              return allStates;
            }
          } else {
            print("⚠️ Invalid response structure, expected status: true. Response: $resBody");
            return allStates;
          }
        } else if (response.statusCode == 429 && retryCount < maxRetries) {
          retryCount++;
          final delay = Duration(milliseconds: 500 * pow(2, retryCount).toInt());
          print("⚠️ Rate limit hit (429). Retrying ($retryCount/$maxRetries) after $delay...");
          await Future.delayed(delay);
          continue;
        } else {
          print("❌ API failed for states with country ID '$countryId': ${response.statusCode} - ${response.reasonPhrase}");
          print("Response body: $resBody");
          return allStates;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
      return allStates;
    } catch (e) {
      print("❌ Error fetching states for country ID '$countryId': $e");
      return allStates;
    }
  }
}