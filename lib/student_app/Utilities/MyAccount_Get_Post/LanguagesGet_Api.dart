import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Model/Languages_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class LanguageDetailApi {
  static Future<List<LanguagesModel>> fetchLanguages({
    required String authToken,
    required String connectSid,
  }) async {
    try {
      final url = Uri.parse(
        ApiConstantsStu.fetchLanguageApi,
      );
      final headers = {
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };

      final request = http.Request('GET', url)..headers.addAll(headers);
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      await SessionGuard.scan(
        statusCode: streamedResponse.statusCode,
        body: responseBody,
      );

      if (streamedResponse.statusCode == 200) {
        final jsonData = json.decode(responseBody);

        if (jsonData is Map &&
            jsonData.containsKey('languages') &&
            jsonData['languages'] is List) {
          final langList = jsonData['languages'] as List;
          return langList
              .map((jsonItem) => LanguagesModel.fromJson(jsonItem))
              .toList();
        }
        throw Exception('Invalid response format');
      }
      throw Exception(
          'Failed to fetch languages: ${streamedResponse.reasonPhrase}');
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateLanguages({
    required String authToken,
    required String connectSid,
    required LanguagesModel language,
  }) async {
    final url = Uri.parse(
      ApiConstantsStu.updateLanguageApi,
    );
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    if (language.languageId == 0) {
      return {'success': false, 'data': 'Invalid language_id'};
    }

    final body = json.encode(language.toJson());

    try {
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      await SessionGuard.scan(statusCode: response.statusCode, body: responseBody);

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);

        int? newId;
        if (jsonData is Map &&
            jsonData.containsKey('data') &&
            jsonData['data'] is Map) {
          newId = jsonData['data']['id'] as int?;
        } else {
          final languages = await fetchLanguages(
              authToken: authToken, connectSid: connectSid);
          final newLanguage = languages.lastWhere(
            (lang) =>
                lang.languageId == language.languageId &&
                lang.proficiency == language.proficiency,
            orElse: () => language,
          );
          newId = newLanguage.id;
        }

        return {
          'success': true,
          'data': {
            'id': newId,
            'language': LanguagesModel(
              id: newId,
              languageId: language.languageId,
              languageName: language.languageName,
              proficiency: language.proficiency,
            ),
          },
        };
      }
      return {'success': false, 'data': responseBody};
    } catch (e) {
      return {'success': false, 'data': e.toString()};
    }
  }

  static Future<bool> deleteLanguage({
    required int? id,
    required String authToken,
    required String connectSid,
  }) async {
    if (id == null || id == 0) {
      return false;
    }

    final url = Uri.parse(
        '${ApiConstantsStu.subUrl}profile/student/delete/$id?action=language');
    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    try {
      final request = http.Request('DELETE', url)..headers.addAll(headers);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      await SessionGuard.scan(statusCode: response.statusCode, body: responseBody);

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
