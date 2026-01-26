// lib/Utilities/InterviewScreen_Api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/InterviewScreen_Model.dart';
import 'ApiConstants.dart';

/// Keep your old fetchInterviews if you like, but add this helper which
/// returns both parsed list and raw JSON and supports If-None-Match (ETag).
class InterviewApi {
  // Existing method kept for compatibility (optional)
  static Future<List<InterviewModel>> fetchInterviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';
      var url = Uri.parse(ApiConstantsStu.interview_screen);
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };
      var request = http.Request('POST', url);
      request.body = json.encode({
        "job_id": "",
        "from_date": "",
        "to_date": "",
        "from": "",
        "interviewTitle": "",
        "sort": ""
      });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = json.decode(body);
        final List<dynamic> data = jsonData['scheduled_meeting_list'] ?? [];
        return data.map((item) => InterviewModel.fromJson(item)).toList();
      } else {
        print('Failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching interview list: $e');
      return [];
    }
  }

  static Future<_FetchResult> fetchInterviewsRawAndParsed({String? ifNoneMatch}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';

      var url = Uri.parse(ApiConstantsStu.interview_screen);
      var headers = {
        'Content-Type': 'application/json',
        'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
      };
      if (ifNoneMatch != null && ifNoneMatch.isNotEmpty) {
        headers['If-None-Match'] = ifNoneMatch;
      }

      var request = http.Request('POST', url);
      request.body = json.encode({
        "job_id": "",
        "from_date": "",
        "to_date": "",
        "from": "",
        "interviewTitle": "",
        "sort": ""
      });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = json.decode(body);
        final List<dynamic> data = jsonData['scheduled_meeting_list'] ?? [];
        final parsed = data.map((item) => InterviewModel.fromJson(item)).toList();

        final etag = response.headers['etag'];

        final rawArrayJson = json.encode(data);

        return _FetchResult(parsed: parsed, rawBody: rawArrayJson, notModified: false, etag: etag);
      } else if (response.statusCode == 304) {
        return _FetchResult(parsed: null, rawBody: null, notModified: true, etag: ifNoneMatch);
      } else {
        print('InterviewApi fetch failed with status: ${response.statusCode}');
        return _FetchResult(parsed: <InterviewModel>[], rawBody: null, notModified: false, etag: null);
      }
    } catch (e) {
      print('InterviewApi fetch error: $e');
      return _FetchResult(parsed: <InterviewModel>[], rawBody: null, notModified: false, etag: null);
    }
  }
}

class _FetchResult {
  final List<InterviewModel>? parsed;
  final String? rawBody;
  final bool notModified;
  final String? etag;
  _FetchResult({this.parsed, this.rawBody, this.notModified = false, this.etag});
}
