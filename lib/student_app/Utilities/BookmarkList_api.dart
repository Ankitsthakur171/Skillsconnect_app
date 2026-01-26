import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class BookmarkJob {
  final int bookmarkId;
  final String module;
  final int moduleId;
  final DateTime bookmarkedAt;
  final int entityId;
  final String title;
  final String subtitle;
  final String company;
  final String employmentType;
  final String opportunityType;
  final String? ctc;
  final String? companyLogo;
  final String? jobToken;

  BookmarkJob({
    required this.bookmarkId,
    required this.module,
    required this.moduleId,
    required this.bookmarkedAt,
    required this.entityId,
    required this.title,
    required this.subtitle,
    required this.company,
    required this.employmentType,
    required this.opportunityType,
    this.ctc,
    this.companyLogo,
    this.jobToken,
  });

  factory BookmarkJob.fromJson(Map<String, dynamic> j) {
    final extra = (j['extra'] is Map) ? (j['extra'] as Map<String, dynamic>) : <String, dynamic>{};

    String? parsedToken;
    if (j.containsKey('jobtoken')) parsedToken = j['jobtoken']?.toString();
    if (parsedToken == null && j.containsKey('jobToken')) parsedToken = j['jobToken']?.toString();
    if (parsedToken == null && extra.isNotEmpty) {
      parsedToken = (extra['jobtoken'] ?? extra['jobToken'] ?? extra['token'])?.toString();
    }

    return BookmarkJob(
      bookmarkId: j['bookmark_id'] is int ? j['bookmark_id'] as int : int.tryParse('${j['bookmark_id']}') ?? 0,
      module: j['module']?.toString() ?? '',
      moduleId: j['module_id'] is int ? j['module_id'] as int : int.tryParse('${j['module_id']}') ?? 0,
      bookmarkedAt: DateTime.tryParse(j['bookmarked_at']?.toString() ?? '') ?? DateTime.now(),
      entityId: j['entity_id'] is int ? j['entity_id'] as int : int.tryParse('${j['entity_id']}') ?? 0,
      title: j['title']?.toString() ?? '',
      subtitle: j['subtitle']?.toString() ?? '',
      company: extra['company']?.toString() ?? '',
      employmentType: extra['employment_type']?.toString() ?? '',
      opportunityType: extra['opportunity_type']?.toString() ?? '',
      ctc: extra['ctc']?.toString(),
      companyLogo: extra['company_logo']?.toString(),
      jobToken: parsedToken,
    );
  }
}

class BookmarkApi {
  static const String _base = ApiConstantsStu.bookmarkList;

  static Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final cookieParts = <String>[];
    if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
    if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');
    if (cookieParts.isNotEmpty) headers['Cookie'] = cookieParts.join('; ');
    return headers;
  }

  static Future<List<BookmarkJob>> fetchBookmarks({
    String module = 'Job',
    int page = 1,
    int limit = 20,
    int? userId,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse(_base).replace(queryParameters: {
        'module': module,
        'page': '$page',
        'limit': '$limit',
        if (userId != null) 'user_id': '$userId',
      });

      print('[BookmarkApi] fetchBookmarks -> $uri');
      print('[BookmarkApi] headers: $headers');

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      
      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: res.statusCode);
      
      if (res.statusCode != 200) {
        print('[BookmarkApi] fetchBookmarks non-200: ${res.statusCode} ${res.reasonPhrase}');
        return [];
      }

      final decoded = jsonDecode(res.body);
      if (decoded is Map && (decoded['success'] == true || decoded['status'] == true) && decoded['data'] is List) {
        final list = (decoded['data'] as List).whereType<Map<String, dynamic>>().toList();
        final items = list.map((m) => BookmarkJob.fromJson(m)).toList();
        print('[BookmarkApi] parsed ${items.length} bookmarks');
        return items;
      }

      print('[BookmarkApi] unexpected response shape: ${decoded.runtimeType}');
      return [];
    } catch (e, st) {
      print('[BookmarkApi] fetchBookmarks error: $e');
      print(st);
      return [];
    }
  }

  static Future<bool> removeBookmark({
    int? bookmarkId,
    int? entityId,
    required String module,
  }) async {
    try {
      final headers = await _buildHeaders();
      final uri = Uri.parse('${_base}common/remove-bookmark');
      final body = <String, dynamic>{'module': module};
      if (bookmarkId != null && bookmarkId > 0) body['bookmark_id'] = bookmarkId;
      if (entityId != null && entityId > 0) body['entity_id'] = entityId;

      print('[BookmarkApi] removeBookmark -> $uri');
      print('[BookmarkApi] body: $body');
      print('[BookmarkApi] headers: $headers');

      final res = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 12));
      
      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: res.statusCode);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && (decoded['success'] == true || decoded['status'] == true)) {
          print('[BookmarkApi] removeBookmark success');
          return true;
        }
        print('[BookmarkApi] removeBookmark returned 200 but success flag missing');
        return false;
      }

      print('[BookmarkApi] removeBookmark non-200: ${res.statusCode} ${res.reasonPhrase}');
      return false;
    } catch (e, st) {
      print('[BookmarkApi] removeBookmark error: $e');
      print(st);
      return false;
    }
  }
}
