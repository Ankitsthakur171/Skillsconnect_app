import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/Bookmark_Model.dart';
import 'ApiConstants.dart';
import '../../utils/session_guard.dart';

class BookmarkApi {

static Future<BookmarkModel?> toggleBookmark({
  required String module,
  required int moduleId,
  required String authToken,
  required String connectSid,
  required bool currentlyBookmarked,
}) async {
  print('🔖 [BookmarkApi] toggleBookmark START');
  print('🔖 module=$module, moduleId=$moduleId');
  print('🔖 currentlyBookmarked=$currentlyBookmarked');

  final cookieParts = <String>[];
  if (authToken.isNotEmpty) cookieParts.add('authToken=$authToken');
  if (connectSid.isNotEmpty) cookieParts.add('connect.sid=$connectSid');

  final headers = {
    'Content-Type': 'application/json',
    if (cookieParts.isNotEmpty) 'Cookie': cookieParts.join('; '),
  };

  final postUrl = Uri.parse(ApiConstantsStu.bookmark_add);
  final body = json.encode({
    'module': module,
    'module_id': moduleId,
  });

  print('➕ [BookmarkApi] POST → $postUrl');
  print('➕ POST body=$body');

  try {
    final resp = await http
        .post(postUrl, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));

    print('➕ POST status=${resp.statusCode}');
    print('➕ POST body=${resp.body}');

    await SessionGuard.scan(statusCode: resp.statusCode);

    if (resp.statusCode == 401) return null;

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      try {
        final parsed = json.decode(resp.body);
        final msg = parsed['message']?.toString().toLowerCase() ?? '';

        print('📩 Backend message="$msg"');

        if (msg.contains('removed')) {
          return BookmarkModel(
            module: module,
            moduleId: moduleId,
            isBookmarked: false,
          );
        }

        if (msg.contains('added') || msg.contains('bookmarked')) {
          return BookmarkModel(
            module: module,
            moduleId: moduleId,
            isBookmarked: true,
          );
        }
      } catch (_) {
        // fallback: toggle based on previous state
        return BookmarkModel(
          module: module,
          moduleId: moduleId,
          isBookmarked: !currentlyBookmarked,
        );
      }
    }
  } catch (e, st) {
    print('🚨 [BookmarkApi] EXCEPTION $e');
    print(st);
  }

  return null;
}
}
