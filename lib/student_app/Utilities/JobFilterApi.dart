import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class JobFilterApi {
  static Future<List<Map<String, dynamic>>> fetchJobs({
    required int page,
    required int limit,
    String? searchQuery,
    int? jobTypeId,
    int? courseId,
    int? locationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    print(
        "JobFilterApi → fetchJobs(page=$page, limit=$limit, search=$searchQuery, jobTypeId=$jobTypeId, courseId=$courseId, locationId=$locationId)");

    final Map<String, dynamic> body = {
      "page": page,
      "limit": limit,
    };

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      body["job_title"] = searchQuery.trim();
    }
    if (jobTypeId != null) body["job_type"] = jobTypeId;
    if (courseId != null) body["course"] = courseId;
    if (locationId != null) body["location"] = locationId;

    print("JobFilterApi → Request Body: $body");

    try {
      final response = await http
          .post(
        Uri.parse(ApiConstantsStu.jobList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Cookie': 'authToken=$authToken',
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 40));

      print("JobFilterApi → Response Status: ${response.statusCode}");
      print("JobFilterApi → Response Body: ${response.body}");

      if (response.statusCode != 200) {
        // 🔴 Critical: Check for auth errors
        await SessionGuard.scan(statusCode: response.statusCode, body: response.body);
        throw Exception("Failed to load jobs: HTTP ${response.statusCode}");
      }

      final data = json.decode(response.body);

      if (data['status'] != true) {
        throw Exception(data['msg'] ?? "API returned error");
      }

      if (data['jobs'] is! List) {
        throw Exception("Invalid response format: 'jobs' must be a list");
      }

      final List jobsList = data['jobs'];
      print("JobFilterApi → Success: ${jobsList.length} jobs");

      return jobsList.map<Map<String, dynamic>>((job) {
        try {
          final title = job['title']?.toString() ?? 'Untitled Job';
          final company = job['company_name']?.toString() ?? 'Unknown Company';

          final threeCities = job['three_cities_name']?.toString() ?? '';
          final totalCities = (job['total_cities'] is int)
              ? job['total_cities']
              : int.tryParse(job['total_cities']?.toString() ?? '') ?? 0;

          String location;
          if (threeCities.isNotEmpty) {
            location = totalCities > 3
                ? "$threeCities + ${totalCities - 3} more"
                : threeCities;
          } else {
            location = "Location not specified";
          }

          final dynamic rawSkills = job['skills'];
          List<String> skills;
          if (rawSkills is String) {
            skills = rawSkills
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else if (rawSkills is List) {
            skills = rawSkills
                .map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList();
          } else {
            skills = [];
          }

          final jobType = job['job_type']?.toString() ?? '';
          final logoUrl = job['company_logo']?.toString() ?? '';

          final createdOn = job['created_on']?.toString();
          final postTime = _normalizePostTime(createdOn);

          final ctc = job['cost_to_company']?.toString() ?? '';
          final salary = (ctc.isEmpty || ctc == "0") ? "Unpaid" : "₹$ctc LPA";

          final expiry = _calculateExpiry(job['end_date']?.toString());

          final Map<String, dynamic> result =
          Map<String, dynamic>.from(job as Map);

          result['id'] = job['id'] ?? 0;
          result['job_id'] = job['job_id'] ?? job['jobId'] ?? 0;

          result['title'] = title;
          result['company'] = company;
          result['location'] = location;
          result['salary'] = salary;
          result['postTime'] = postTime;
          result['expiry'] = expiry;
          result['job_type'] = jobType;
          result['tags'] = skills;
          result['logoUrl'] = logoUrl;

          result['slug'] = job['slug']?.toString() ??
              job['title_slug']?.toString() ??
              job['seo_slug']?.toString() ??
              '';

          result['applyUrl'] = job['apply_url']?.toString() ??
              job['job_profile_url']?.toString() ??
              '';

          return result;
        } catch (e) {
          print("JobFilterApi → Job Parse Error: $e");
          rethrow;
        }
      }).toList();
    } on TimeoutException catch (_) {
      throw Exception("Request timeout. Please try again.");
    } catch (e) {
      print("JobFilterApi → Unexpected Error: $e");
      rethrow;
    }
  }


  static String _normalizePostTime(String? value) {
    if (value == null || value.trim().isEmpty) return "N/A";

    final s = value.trim();

    final humanPattern =
    RegExp(r'\b(ago|min|mins|minute|minutes|hr|hrs|day|days)\b', caseSensitive: false);
    if (humanPattern.hasMatch(s)) return s;

    DateTime? dt;

    try {
      dt = DateTime.parse(s);
    } catch (_) {
      try {
        dt = DateFormat("yyyy-MM-dd HH:mm:ss").parseLoose(s);
      } catch (_) {
        return s;
      }
    }

    final diff = DateTime.now().difference(dt!);

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return "$m ${m == 1 ? "min" : "mins"} ago";
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      return "$h ${h == 1 ? "hr" : "hrs"} ago";
    }

    final d = diff.inDays;
    return "$d ${d == 1 ? "day" : "days"} ago";
  }


  static String _calculateExpiry(String? endDate) {
    if (endDate == null || endDate.isEmpty) return "N/A";
    DateTime? expiry;
    try {
      expiry = DateTime.parse(endDate);
    } catch (_) {
      return "N/A";
    }

    final daysLeft = expiry.difference(DateTime.now()).inDays;
    return daysLeft > 0 ? "$daysLeft days left" : "Expired";
  }
}
