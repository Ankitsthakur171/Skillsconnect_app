
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class JobApi {
  static Future<List<Map<String, dynamic>>> fetchJobs({
    int page = 1,
    int limit = 10,
    String? query,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    print("JobApi → authToken exists: ${authToken.isNotEmpty}");
    print("JobApi → connectSid exists: ${connectSid.isNotEmpty}");
    print("JobApi → Calling API → ${ApiConstantsStu.jobList}");

    final bodyMap = <String, dynamic>{
      "page": page,
      "limit": limit,
      if (query != null && query.trim().isNotEmpty) "job_title": query.trim(),
    };
    if (kDebugMode) {
      print("JobApi → Request Body: $bodyMap");
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstantsStu.jobList),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
              'Cookie':
                  'authToken=$authToken${connectSid.isNotEmpty ? '; connect.sid=$connectSid' : ''}',
            },
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 40));

      print("JobApi → Response Status Code: ${response.statusCode}");
      print("JobApi → Response Body: ${response.body}");

      // Check for token expiry or unauthorized access
      await SessionGuard.scan(statusCode: response.statusCode, body: response.body);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch jobs: ${response.statusCode} - ${response.reasonPhrase}');
      }

      final data = json.decode(response.body);

      if (data['status'] != true) {
        print("JobApi → API status=false, msg=${data['msg']}");
        throw Exception('Invalid response: ${data['msg'] ?? 'Unknown error'}');
      }

      if (data['jobs'] is! List) {
        throw Exception('Invalid response format: jobs is not a list');
      }

      final jobsList = data['jobs'] as List;

      print("JobApi → Success. Received ${jobsList.length} jobs.");

      return jobsList.map<Map<String, dynamic>>((raw) {
        final job = Map<String, dynamic>.from(raw as Map);

        final String title = (job['title'] ?? '').toString();
        final String company = (job['company_name'] ?? '').toString();

        final String threeCities = (job['three_cities_name'] ?? '').toString();
        final int totalCities = job['total_cities'] is int
            ? job['total_cities'] as int
            : int.tryParse(job['total_cities']?.toString() ?? '0') ?? 0;

        String location;
        if (threeCities.isNotEmpty) {
          location = totalCities > 3
              ? '$threeCities + ${totalCities - 3} more'
              : threeCities;
        } else {
          location = 'Location not specified';
        }

        List<String> tags = [];
        final dynamic skillsRaw = job['skills'];
        if (skillsRaw is String) {
          tags = skillsRaw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (skillsRaw is List) {
          tags = skillsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        final String jobType = (job['job_type'] ?? '').toString();
        final createdOnStr = job['created_on']?.toString() ?? '';
        final createdOn = DateTime.tryParse(createdOnStr) ?? DateTime.now();
        final now = DateTime.now();
        final diff = now.difference(createdOn);
        final String postTime = diff.inMinutes < 60
            ? '${diff.inMinutes} mins ago'
            : diff.inHours < 24
                ? '${diff.inHours} hr ago'
                : '${diff.inDays} days ago';

        final rawCtc = job['cost_to_company']?.toString() ?? '';
        final String salary =
            rawCtc.isEmpty || rawCtc == '0' ? 'Unpaid' : '₹$rawCtc LPA';

        final expiry = _calculateExpiry(job['end_date']?.toString());

        final int id = job['id'] is int
            ? job['id'] as int
            : int.tryParse(job['id']?.toString() ?? '0') ?? 0;

        final int jobId = job['job_id'] is int
            ? job['job_id'] as int
            : job['jobId'] is int
                ? job['jobId'] as int
                : int.tryParse(
                        (job['job_id'] ?? job['jobId'] ?? '0').toString()) ??
                    0;

        final String jobToken =
            (job['job_invitation_token'] ?? job['jobToken'] ?? '').toString();

        final String logoUrl = (job['company_logo'] ?? '').toString();

        final String slug = (job['slug'] ??
                job['title_slug'] ??
                job['seo_slug'] ??
                job['job_slug'] ??
                '')
            .toString();

        final String applyUrl =
            (job['apply_url'] ?? job['job_profile_url'] ?? '').toString();

        final endDateRaw = job['end_date']?.toString();
        if (endDateRaw != null) {
          print('[JobList_Api] Job "$title" has end_date: $endDateRaw');
        }
        return {
          'title': title,
          'company': company,
          'location': location,
          'salary': salary,
          'postTime': postTime,
          'expiry': expiry,
          'job_type': jobType,
          'tags': tags,
          'logoUrl': logoUrl,
          'jobToken': jobToken,
          'id': id,
          'job_id': jobId,
          'slug': slug,
          'applyUrl': applyUrl,
          'end_date': endDateRaw,
        };
      }).toList();
    } on http.ClientException catch (e) {
      print("JobApi → NETWORK ERROR: $e");
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      print("JobApi → TIMEOUT ERROR: $e");
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      print("JobApi → UNEXPECTED ERROR: $e");
      rethrow;
    }
  }

  static String _calculateExpiry(String? endDate) {
    if (endDate == null || endDate.isEmpty) return 'N/A';
    final expiry = DateTime.tryParse(endDate);
    if (expiry == null) return 'N/A';

    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    return daysLeft > 0 ? '$daysLeft days left' : 'Expired';
  }
}
