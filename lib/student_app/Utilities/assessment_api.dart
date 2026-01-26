import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';

class Assessment {
  final String title;
  final String companyName;
  final String processName;
  final DateTime? invitedOn;
  final DateTime? endDate;
  final String assessmentUrl;
  final int processId;
  final String status;

  Assessment({
    required this.title,
    required this.companyName,
    required this.processName,
    required this.invitedOn,
    required this.endDate,
    required this.assessmentUrl,
    required this.processId,
    required this.status,
  });

  factory Assessment.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(String? s) {
      if (s == null) return null;
      try {
        return DateTime.tryParse(s);
      } catch (_) {
        return null;
      }
    }

    return Assessment(
      title: j['title'] ?? '',
      companyName: j['company_name'] ?? '',
      processName: j['process_name'] ?? '',
      invitedOn: parseDate(j['invited_on'] as String?),
      endDate: parseDate(j['end_date'] as String?),
      assessmentUrl: (j['assessment_url'] ?? j['invite_link'] ?? '') as String,
      processId: (j['process_id'] ?? 0) as int,
      status: j['status'] ?? '',
    );
  }
}

class AssessmentApi {
  static const String _endpoint = '${ApiConstantsStu.subUrl}jobs/assessment';

  static Future<List<Assessment>> fetchAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken.isNotEmpty) 'Cookie': 'authToken=$authToken',
    };

    final request = http.Request('GET', Uri.parse(_endpoint));
    request.headers.addAll(headers);
    request.body = '';

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final decoded = json.decode(resp.body);
      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true &&
          decoded['data'] is List) {
        final list = decoded['data'] as List;
        return list
            .map<Assessment>(
                (e) => Assessment.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format: ${decoded}');
      }
    } else {
      throw Exception(
          'Failed to fetch assessments: ${resp.statusCode} ${resp.reasonPhrase}');
    }
  }
}
