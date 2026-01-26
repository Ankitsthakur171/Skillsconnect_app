import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/Skiils_Model.dart';
import '../ApiConstants.dart';

class SkillsApi {
  static Future<List<SkillsModel>> fetchSkills({
    required String authToken,
    required String connectSid,
  }) async {
    print('🔍 [SkillsApi.fetchSkills] START');

    // ✅ Guard: authToken is mandatory
    if (authToken.isEmpty) {
      print('❌ [SkillsApi.fetchSkills] authToken is empty');
      return [];
    }

    try {
      final uri = Uri.parse(ApiConstantsStu.fetchSkills);
      print('🔍 [SkillsApi.fetchSkills] url=$uri');

      // ✅ Build cookie safely (use all parameters)
      final cookieParts = <String>[];
      cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) {
        cookieParts.add('connect.sid=$connectSid');
      }

      final headers = {
        'Cookie': cookieParts.join('; '),
      };

      print('🔍 [SkillsApi.fetchSkills] headers=$headers');

      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final response = await request.send();
      print(
        '🔍 [SkillsApi.fetchSkills] statusCode=${response.statusCode}',
      );

      final responseBody = await response.stream.bytesToString();
      print('🔍 [SkillsApi.fetchSkills] body=$responseBody');

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);

        if (decoded is Map &&
            decoded['status'] == true &&
            decoded['skills'] != null) {
          final skillsList = <SkillsModel>[];
          final data = decoded['skills'];

          if (data is List) {
            for (final skillItem in data) {
              if (skillItem is Map &&
                  skillItem['skills'] is String) {
                final rawSkills =
                    (skillItem['skills'] as String).trim();

                if (rawSkills.isNotEmpty) {
                  final individualSkills =
                      rawSkills.split(',');

                  for (final s in individualSkills) {
                    final skill = s.trim();
                    if (skill.isNotEmpty) {
                      skillsList.add(
                        SkillsModel(skills: skill),
                      );
                    }
                  }
                }
              }
            }
          } else {
            print(
              '⚠️ [SkillsApi.fetchSkills] Unexpected skills type: $data',
            );
          }

          print(
            '✅ [SkillsApi.fetchSkills] fetched ${skillsList.length} skills',
          );
          return skillsList;
        }

        print('⚠️ [SkillsApi.fetchSkills] No skills in response');
        return [];
      }

      print(
        '❌ [SkillsApi.fetchSkills] Failed with status ${response.statusCode}',
      );
      return [];
    } catch (e, st) {
      print('🚨 [SkillsApi.fetchSkills] Exception: $e');
      print(st);
      return [];
    }
  }
}
