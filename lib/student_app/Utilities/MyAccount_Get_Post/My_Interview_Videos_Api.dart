import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/My_Interview_Videos_Model.dart';
import '../ApiConstants.dart';
import '../../../utils/session_guard.dart';

class VideoIntroApi {
  Future<VideoIntroModel?> fetchVideoIntroQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    if (authToken.isEmpty) {
      debugPrint('❌ Missing authToken.');
      return null;
    }
    try {
      final response = await http.get(
        Uri.parse(ApiConstantsStu.fetchIntroVideos),
        headers: {
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        },
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['videoIntro'];

        if (data != null && data is List && data.isNotEmpty) {
          return VideoIntroModel.fromJson(data.first);
        } else {
          debugPrint("⚠️ No 'videoIntro' data found.");
        }
      } else {
        debugPrint(
            "❌ Failed to fetch: ${response.statusCode} ${response.reasonPhrase}");
      }

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);
    } catch (e) {
      debugPrint('❌ Exception during fetch: $e');
    }
    return null;
  }


  Future<bool> updateVideoIntro(String question, String videoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';

    if (authToken.isEmpty) {
      debugPrint('❌ Missing authToken.');
      return false;
    }

    final questionFieldMap = {
      'tell me about yourself': 'about_yourself',
      'how do you organize your day?': 'organize_your_day',
      'what are your strengths?': 'your_strength',
      'what is something you have taught yourself lately?': 'taught_yourself_tately',
    };

    final videoAction = questionFieldMap[question.toLowerCase()];
    if (videoAction == null) {
      debugPrint('❌ Invalid question: $question');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConstantsStu.updateIntroVideos),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'authToken=$authToken; connect.sid=$connectSid',
        },
        body: json.encode({
          'fileUploadName': videoUrl,
          'video-action': videoAction,
        }),
      );

      // 🔸 Scan for session issues (401 logout)
      await SessionGuard.scan(statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Video intro updated successfully: ${response.body}');
        return true;
      } else {
        debugPrint('❌ Failed to update video intro: ${response.statusCode} ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception during video intro update: $e');
      return false;
    }
  }
}
