
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/BasicEducation_Model.dart';
import '../../Model/EducationDetail_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class EducationDetailApi {
  static Future<List<EducationDetailModel>> fetchAllEducationDetails({
    String? authToken,
    String? connectSid,
  }) async {
    try {
      print('=== fetchAllEducationDetails START ===');
      if ((authToken == null || authToken.isEmpty) || (connectSid == null || connectSid.isEmpty)) {
        final prefs = await SharedPreferences.getInstance();
        print('SharedPreferences loaded for fetchAllEducationDetails');
        authToken = (authToken == null || authToken.isEmpty) ? (prefs.getString('authToken') ?? '') : authToken;
        connectSid = (connectSid == null || connectSid.isEmpty) ? (prefs.getString('connectSid') ?? '') : connectSid;
        print('Using authToken length=${authToken.length}, connectSid length=${connectSid.length}');
      }

      final uri = Uri.parse(ApiConstantsStu.educationDetails);
      print('Fetching URL: $uri');

      final headers = {'Content-Type': 'application/json'};
      final cookieParts = <String>[];
      if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      if (cookieParts.isNotEmpty) headers['Cookie'] = cookieParts.join('; ');

      print('Request headers: $headers');

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      print('fetchAllEducationDetails response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Non-200 status in fetchAllEducationDetails, returning empty list');
        return <EducationDetailModel>[];
      }

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      final Map<String, dynamic> decoded = jsonDecode(response.body);
      print('Decoded response keys: ${decoded.keys.toList()}');

      final List<dynamic> higherRaw = decoded['educationDetails'] ?? [];
      final List<dynamic> basicRaw = decoded['basicEducationDetails'] ?? [];
      print('Received higherRaw length=${higherRaw.length}, basicRaw length=${basicRaw.length}');

      final higher = higherRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => EducationDetailModel.fromJson(m))
          .toList();

      final basic = basicRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => EducationDetailModel.fromJson(m))
          .toList();

      final merged = <EducationDetailModel>[];
      merged.addAll(higher);
      merged.addAll(basic);

      print('Merged education details count: ${merged.length}');

      return merged;
    } catch (e, st) {
      print('EducationDetailApi.fetchAllEducationDetails error: $e');
      print(st);
      return <EducationDetailModel>[];
    }
  }

  // ---------------------------
  // Simple POST: higher education
  // ---------------------------

  static Future<bool> postHigherEducationSimple({
    required Map<String, dynamic> body,
    String? authToken,
    String? connectSid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences loaded for postHigherEducationSimple');
      authToken = (authToken == null || authToken.isEmpty) ? (prefs.getString('authToken') ?? '') : authToken;
      connectSid = (connectSid == null || connectSid.isEmpty) ? (prefs.getString('connectSid') ?? '') : connectSid;

      final uri = Uri.parse('${ApiConstantsStu.subUrl}profile/student/update-education-details');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final cookieParts = <String>[];
      if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      if (cookieParts.isNotEmpty) headers['Cookie'] = cookieParts.join('; ');

      // DEBUG: print request info
      try {
        print('=== POST HigherEducation START ===');
        print('URL: $uri');
        print('Headers: $headers');
        print('Body: ${jsonEncode(body)}');
      } catch (_) {}

      final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      // DEBUG: print response info
      try {
        print('HigherEducation response status: ${response.statusCode}');
        print('HigherEducation response body: ${response.body}');
      } catch (_) {}

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('status')) {
            final ok = decoded['status'] == true;
            print('HigherEducation API status key present: $ok');
            return ok;
          }
          print('HigherEducation 200 received but no status key — treating as success');
          return true;
        } catch (e) {
          print('HigherEducation parse error (treating 200 as success): $e');
          return true;
        }
      }

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print('HigherEducation API returned non-200 status: ${response.statusCode}');
      return false;
    } catch (e, st) {
      print('EducationDetailApi.postHigherEducationSimple error: $e');
      print(st);
      return false;
    }
  }

  static Future<bool> postHigherEducationFromModel({
    required EducationDetailModel model,
    String? degreeType,
    String? collegeId,
    String? course,
    String? specialization,
    String? courseType,
    String? gradingSystem,
  }) async {
    final Map<String, dynamic> body = {};

    if (degreeType != null && degreeType.isNotEmpty) body['degreeType'] = degreeType;
    if (collegeId != null && collegeId.isNotEmpty) body['college_id'] = collegeId;
    if (course != null && course.isNotEmpty) body['course'] = course;
    if (specialization != null && specialization.isNotEmpty) body['specialization'] = specialization;
    if (courseType != null && courseType.isNotEmpty) body['course_type'] = courseType;
    if (gradingSystem != null && gradingSystem.isNotEmpty) body['grading_system'] = gradingSystem;
    if (model.marks.isNotEmpty) body['marks'] = model.marks;
    if (model.passingMonth != null && model.passingMonth!.isNotEmpty) body['month'] = model.passingMonth;
    if (model.passingYear.isNotEmpty) body['year'] = model.passingYear;
    if (model.educationId != null && model.educationId! > 0) body['educationid'] = model.educationId.toString();
    if (body.isEmpty) {
      print('postHigherEducationFromModel: constructed body is empty — aborting');
      return false;
    }

    print('postHigherEducationFromModel: constructed body: ${jsonEncode(body)}');
    final result = await postHigherEducationSimple(body: body);
    print('postHigherEducationFromModel: result=$result');
    return result;
  }

  // ---------------------------
  // Simple POST: basic (school) education
  // ---------------------------
  static Future<bool> postBasicEducationSimple({
    required Map<String, dynamic> body,
    String? authToken,
    String? connectSid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences loaded for postBasicEducationSimple');
      authToken = (authToken == null || authToken.isEmpty) ? (prefs.getString('authToken') ?? '') : authToken;
      connectSid = (connectSid == null || connectSid.isEmpty) ? (prefs.getString('connectSid') ?? '') : connectSid;

      final uri = Uri.parse('${ApiConstantsStu.subUrl}profile/student/update-basic-education-details');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final cookieParts = <String>[];
      if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
      if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
      if (cookieParts.isNotEmpty) headers['Cookie'] = cookieParts.join('; ');

      // DEBUG: print request info
      try {
        print('=== POST BasicEducation START ===');
        print('URL: $uri');
        print('Headers: $headers');
        print('Body: ${jsonEncode(body)}');
      } catch (_) {}

      final response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      // DEBUG: print response info
      try {
        print('BasicEducation response status: ${response.statusCode}');
        print('BasicEducation response body: ${response.body}');
      } catch (_) {}

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('status')) {
            final ok = decoded['status'] == true;
            print('BasicEducation API status key present: $ok');
            return ok;
          }
          print('BasicEducation 200 received but no status key — treating as success');
          return true;
        } catch (e) {
          print('BasicEducation parse error (treating 200 as success): $e');
          return true;
        }
      }

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      print('BasicEducation API returned non-200 status: ${response.statusCode}');
      return false;
    } catch (e, st) {
      print('EducationDetailApi.postBasicEducationSimple error: $e');
      print(st);
      return false;
    }
  }

  static Future<bool> postBasicEducationFromModel({
    required BasicEducationModel model,
    String? degreeType,
    String? boardId,
    String? mediumId,
  }) async {
    final Map<String, dynamic> body = {};

    if (degreeType != null && degreeType.isNotEmpty) {
      body['degreeType'] = degreeType;
    }

    if (boardId != null && boardId.isNotEmpty) {
      body['boardName'] = boardId;
    } else if (model.boardId != 0) {
      body['boardName'] = model.boardId.toString();
    }

    if (mediumId != null && mediumId.isNotEmpty) {
      body['medium'] = mediumId;
    } else if (model.mediumName.isNotEmpty) {
      body['medium'] = model.mediumName;
    }

    if (model.marks.isNotEmpty) body['marks'] = model.marks;
    if (model.passingYear.isNotEmpty) body['year'] = model.passingYear;

    if (model.basicEducationId != 0) body['basic_education_id'] = model.basicEducationId.toString();

    if (body.isEmpty) {
      print('postBasicEducationFromModel: constructed body is empty — aborting');
      return false;
    }

    print('postBasicEducationFromModel: constructed body: ${jsonEncode(body)}');
    final result = await postBasicEducationSimple(body: body);
    print('postBasicEducationFromModel: result=$result');
    return result;
  }
}
