import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class JobDetailApi {
  static Future<Map<String, dynamic>> fetchJobDetail({
    required String token,
    int? moduleId,
  }) async {
    if ((token.isEmpty) && (moduleId == null || moduleId == 0)) {
      throw Exception('Job token and moduleId are both missing.');
    }

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
    };

    final Uri uri = Uri.parse(ApiConstantsStu.job_detail);

    Future<http.Response> _post(Map<String, dynamic> body) {
      final bodyJson = jsonEncode(body);
      print('[JobDetailApi] POST -> $uri');
      print('[JobDetailApi] headers: $headers');
      print('[JobDetailApi] body: $bodyJson');
      return http.post(uri, headers: headers, body: bodyJson)
          .timeout(const Duration(seconds: 15));
    }

    final hasId = moduleId != null && moduleId > 0;
    final hasToken = token.trim().isNotEmpty;

    final Map<String, dynamic> byId = {
      'job_id': (moduleId ?? 0).toString(),
      'slug': '',
      'token': ''
    };
    final Map<String, dynamic> byToken = {
      'job_id': '',
      'slug': '',
      'token': token.trim()
    };

    final List<Map<String, dynamic>> order = hasId
        ? [byId, if (hasToken) byToken]
        : (hasToken ? [byToken, byId] : [byId]);

    Exception? lastEx;
    for (int i = 0; i < order.length; i++) {
      final attemptBody = order[i];
      try {
        final resp = await _post(attemptBody);
        print('[JobDetailApi] attempt #${i + 1} status: ${resp.statusCode}');
        print('[JobDetailApi] attempt #${i + 1} body: ${resp.body}');

        // 🔸 Scan for session issues (401 logout)
        await SessionGuard.scan(statusCode: resp.statusCode);

        if (resp.statusCode == 200) {
          final Map<String, dynamic> decoded =
          jsonDecode(resp.body) as Map<String, dynamic>;
          return _extractJobMap(decoded);
        } else {
          lastEx = Exception('Non-200 (${resp.statusCode}): ${resp.body}');
          print(
              '[JobDetailApi] Non-200 response: ${resp.statusCode} - ${resp.body}');
        }
      } catch (e, st) {
        lastEx = e is Exception ? e : Exception(e.toString());
        print('[JobDetailApi] Exception on attempt #${i + 1}: $e');
        print(st);
      }
    }

    throw Exception('Failed to fetch Job Details: ${lastEx ?? 'unknown error'}');
  }

  static Map<String, dynamic> _extractJobMap(Map<String, dynamic> data) {
    if (data['status'] == true &&
        data['job_details'] != null &&
        data['job_details'] is Map) {
      final jobDetails =
      Map<String, dynamic>.from(data['job_details'] as Map<String, dynamic>);

      final String slug =
      (jobDetails['job_slug'] ?? jobDetails['slug'] ?? '').toString().trim();
      final String invitationToken =
      (jobDetails['job_invitation_token'] ?? '').toString().trim();

      String jobDescription = jobDetails['job_description'] ?? '';
      List<String> responsibilities = [];
      List<String> requirements = [];
      List<String> niceToHave = [];

      if (jobDescription.contains('<strong>Responsibilities:</strong>')) {
        final respStart = jobDescription.indexOf('<strong>Responsibilities:</strong>') +
            '<strong>Responsibilities:</strong>'.length;
        final respEnd = jobDescription.contains('<strong>Requirements:</strong>')
            ? jobDescription.indexOf('<strong>Requirements:</strong>', respStart)
            : jobDescription.length;
        final respText = jobDescription
            .substring(respStart, respEnd)
            .split('<li>')
            .where((part) => part.contains('</li>'))
            .map((part) =>
            part.split('</li>')[0].replaceAll(RegExp(r'<[^>]+>'), '').trim())
            .where((item) => item.isNotEmpty)
            .toList();
        responsibilities.addAll(respText);
      }

      if (jobDescription.contains('<strong>Requirements:</strong>')) {
        final reqStart = jobDescription.indexOf('<strong>Requirements:</strong>') +
            '<strong>Requirements:</strong>'.length;
        final reqEnd = jobDescription.contains('<strong>Nice to Have:</strong>')
            ? jobDescription.indexOf('<strong>Nice to Have:</strong>', reqStart)
            : jobDescription.length;
        final reqText = jobDescription
            .substring(reqStart, reqEnd)
            .split('<li>')
            .where((part) => part.contains('</li>'))
            .map((part) =>
            part.split('</li>')[0].replaceAll(RegExp(r'<[^>]+>'), '').trim())
            .where((item) => item.isNotEmpty)
            .toList();
        requirements.addAll(reqText);
      }

      if (jobDescription.contains('<strong>Nice to Have:</strong>')) {
        final niceStart =
            jobDescription.indexOf('<strong>Nice to Have:</strong>') +
                '<strong>Nice to Have:</strong>'.length;
        final niceText = jobDescription
            .substring(niceStart)
            .split('<li>')
            .where((part) => part.contains('</li>'))
            .map((part) =>
            part.split('</li>')[0].replaceAll(RegExp(r'<[^>]+>'), '').trim())
            .where((item) => item.isNotEmpty)
            .toList();
        niceToHave.addAll(niceText);
      }

      final rawLocation =
          data['job_location_detail'] ?? jobDetails['job_location_detail'];
      String formattedLocation = 'N/A';
      int totalOpenings = 0;
      List<Map<String, dynamic>> parsedLocations = [];

      if (rawLocation is List) {
        final Set<String> citySet = {};
        for (final loc in rawLocation.whereType<Map<String, dynamic>>()) {
          final city = (loc['city_name']?.toString().trim() ?? '');
          if (city.isNotEmpty) citySet.add(city);

          final openingRaw = (loc['opening'] ?? '').toString().trim();
          final openingCount = int.tryParse(openingRaw) ?? 0;
          totalOpenings += openingCount;

          parsedLocations.add({
            'id': loc['id'],
            'city_name': city,
            'state_name': loc['state_name']?.toString() ?? '',
            'opening': openingCount,
            'raw': loc,
          });
        }
        final cityList = citySet.toList()..sort();
        formattedLocation = cityList.join(' • ');
      } else {
        final directCity =
        (jobDetails['city_name'] ?? jobDetails['town_name'] ?? '').toString().trim();
        if (directCity.isNotEmpty) formattedLocation = directCity;
      }

      List<Map<String, String>> applicationProcess = [];
      final rawProcess = data['process'] ?? jobDetails['process'];
      if (rawProcess is List) {
        for (final p in rawProcess.whereType<Map<String, dynamic>>()) {
          final name = (p['name'] ?? '').toString();
          final type = (p['type'] ?? '').toString();
          if (name.isNotEmpty || type.isNotEmpty) {
            applicationProcess.add({'name': name, 'type': type});
          }
        }
      }

      List<Map<String, String>> qualifications = [];
      final rawCourses = jobDetails['job_course_detail'] ?? data['job_course_detail'];
      if (rawCourses is List) {
        for (final c in rawCourses.whereType<Map<String, dynamic>>()) {
          final courseName = (c['course_name'] ?? c['course'] ?? '').toString().trim();
          final specialization =
          (c['specialization_name'] ?? c['specialization'] ?? '').toString().trim();
          if (courseName.isEmpty && specialization.isEmpty) continue;
          qualifications.add({
            'course_name': courseName,
            'specialization_name': specialization,
          });
        }
      }
      final rawJobCourseDetail = rawCourses;

      final String ctcBreakDown = jobDetails['ctc_break_down']?.toString() ?? '';
      final String fixedPay = jobDetails['fixed_pay']?.toString() ?? '';
      final String variablePay = jobDetails['variable_pay']?.toString() ?? '';
      final String otherIncentives =
          jobDetails['other_incentives']?.toString() ?? '';
      final String probationDuration =
          jobDetails['probation_duration']?.toString() ?? '';
      final String rawJoining = jobDetails['joining_date']?.toString() ?? '';
      String joiningDateFormatted = '';
      DateTime? joiningDateObj;
      if (rawJoining.isNotEmpty) {
        if (RegExp(r'^\d{1,2}-\d{1,2}-\d{4}$').hasMatch(rawJoining)) {
          try {
            final parts = rawJoining.split('-');
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            joiningDateObj = DateTime.utc(year, month, day);
            joiningDateFormatted =
            '${_pad2(day)} ${_monthName(month)} $year';
            print(
                '[JobDetailApi] parsed joining_date (dd-mm-yyyy) -> $joiningDateFormatted (UTC)');
          } catch (e) {
            print('[JobDetailApi] failed to parse joining_date "$rawJoining": $e');
          }
        } else {
          try {
            final dt = DateTime.parse(rawJoining).toUtc();
            joiningDateObj = DateTime.utc(dt.year, dt.month, dt.day);
            joiningDateFormatted =
            '${_pad2(joiningDateObj.day)} ${_monthName(joiningDateObj.month)} ${joiningDateObj.year}';
            print(
                '[JobDetailApi] parsed joining_date (ISO) -> $joiningDateFormatted (UTC)');
          } catch (e) {
            print(
                '[JobDetailApi] joining_date not in expected format: $rawJoining (err: $e)');
          }
        }
      } else if (jobDetails['start_date'] != null) {
        try {
          final dt = DateTime.parse(jobDetails['start_date'].toString()).toUtc();
          joiningDateObj = DateTime.utc(dt.year, dt.month, dt.day);
          joiningDateFormatted =
          '${_pad2(joiningDateObj.day)} ${_monthName(joiningDateObj.month)} ${joiningDateObj.year}';
          print(
              '[JobDetailApi] fallback joining_date from start_date -> $joiningDateFormatted (UTC)');
        } catch (e) {
          // ignore
        }
      }

      final String rawPostedOn = jobDetails['posted_on']?.toString() ??
          jobDetails['created_on']?.toString() ??
          '';
      String postedOnHuman = 'N/A';
      if (rawPostedOn.isNotEmpty) {
        try {
          final createdOnUtc = DateTime.parse(rawPostedOn).toUtc();
          postedOnHuman = _humanTimeDifferenceFromUtc(createdOnUtc);
        } catch (e) {
          print('[JobDetailApi] failed to parse posted_on "$rawPostedOn": $e');
        }
      }

      final String rawEndDate = jobDetails['end_date']?.toString() ?? '';
      String expiryHuman = 'N/A';
      if (rawEndDate.isNotEmpty) {
        try {
          final expiryUtc = DateTime.parse(rawEndDate).toUtc();
          expiryHuman = _humanExpiryFromUtc(expiryUtc);
        } catch (e) {
          print('[JobDetailApi] failed to parse end_date "$rawEndDate": $e');
        }
      }

      return {
        'id': jobDetails['id'] ?? 0,
        'job_id': jobDetails['job_id'] ?? 0,
        'title': jobDetails['title'] ?? '',
        'company': jobDetails['company_name'] ?? '',
        'location': formattedLocation,
        'locations': parsedLocations,
        'openings': totalOpenings,
        'logoUrl': jobDetails['company_logo'] ?? '',
        'slug': slug,
        'job_invitation_token': invitationToken,
        'applied': (data['applied'] == true) || (jobDetails['applied'] == true),
        'responsibilities': responsibilities,
        'terms': [],
        'requirements': requirements,
        'niceToHave': niceToHave,
        'aboutCompany': [
          jobDetails['company_profile']?.replaceAll(RegExp(r'<[^>]+>'), '') ?? ''
        ],
        'job_type': jobDetails['job_type']?.toString() ?? '',

        'skills': (jobDetails['skills'] != null)
            ? jobDetails['skills']
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
            : [],

        'salary': '₹${jobDetails['cost_to_company'] ?? '0'} LPA',
        'ctc_break_down': ctcBreakDown,
        'fixed_pay': fixedPay,
        'variable_pay': variablePay,
        'other_incentives': otherIncentives,
        'probation_duration': probationDuration,
        'joining_date': joiningDateFormatted,
        'joining_date_obj': joiningDateObj?.toIso8601String(),
        'posted_on': rawPostedOn,
        'postTime': postedOnHuman,
        'expiry': expiryHuman,
        'end_date_raw': rawEndDate,
        'application_process': applicationProcess,
        'bookmarkStatus': jobDetails['bookmarkStatus'] ?? '',
        'qualification': qualifications,
        'job_course_detail': rawJobCourseDetail,
      };
    } else {
      throw Exception(
          'API responded with status false or job_details is null. Message: ${data['msg'] ?? 'No message'}');
    }
  }

  static String _pad2(int v) => v.toString().padLeft(2, '0');

  static String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (m < 1 || m > 12) return m.toString();
    return months[m - 1];
  }

  static String _humanTimeDifferenceFromUtc(DateTime createdOnUtc) {
    final nowUtc = DateTime.now().toUtc();
    final diff = nowUtc.difference(createdOnUtc);
    final minutesAgo = diff.inMinutes;
    final hoursAgo = diff.inHours;
    if (minutesAgo < 60) return '$minutesAgo mins ago';
    if (hoursAgo < 24) return '$hoursAgo hr ago';
    final days = (hoursAgo ~/ 24);
    return '$days days ago';
  }

  static String _humanExpiryFromUtc(DateTime expiryUtc) {
    final nowUtc = DateTime.now().toUtc();
    final daysLeft = expiryUtc.difference(nowUtc).inDays;
    return daysLeft > 0 ? '$daysLeft days left' : 'Expired';
  }
}
