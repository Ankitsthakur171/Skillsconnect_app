import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utilities/ApiConstants.dart';

class VideoUpload {
  String questionId;
  String localPath;
  String question;
  String status; // pending, uploading, completed, failed
  String? blobUrl;
  String? error;
  DateTime createdAt;

  VideoUpload({
    required this.questionId,
    required this.localPath,
    required this.question,
    this.status = 'pending',
    this.blobUrl,
    this.error,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'localPath': localPath,
    'question': question,
    'status': status,
    'blobUrl': blobUrl,
    'error': error,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VideoUpload.fromJson(Map<String, dynamic> json) => VideoUpload(
    questionId: json['questionId'],
    localPath: json['localPath'],
    question: json['question'],
    status: json['status'] ?? 'pending',
    blobUrl: json['blobUrl'],
    error: json['error'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class VideoUploadService {
  static const String _storageKey = 'video_uploads_queue';
  static const String _authCookieKey = 'auth_cookie';

  /// Save a video upload to local storage
  static Future<void> saveUpload(VideoUpload upload) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = await getQueuedUploads();
    uploads.add(upload);
    
    final jsonList = uploads.map((u) => u.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    print('💾 [VideoUploadService] Saved upload: ${upload.question}');
  }

  /// Get all queued uploads from storage
  static Future<List<VideoUpload>> getQueuedUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null || jsonString.isEmpty) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => VideoUpload.fromJson(json)).toList();
    } catch (e) {
      print('❌ [VideoUploadService] Error parsing uploads: $e');
      return [];
    }
  }

  /// Update upload status in storage
  static Future<void> updateUploadStatus(
    String questionId,
    String status, {
    String? blobUrl,
    String? error,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = await getQueuedUploads();
    
    final index = uploads.indexWhere((u) => u.questionId == questionId);
    if (index != -1) {
      uploads[index].status = status;
      if (blobUrl != null) uploads[index].blobUrl = blobUrl;
      if (error != null) uploads[index].error = error;
      
      final jsonList = uploads.map((u) => u.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      print('✅ [VideoUploadService] Updated ${uploads[index].question} to $status');
    }
  }

  /// Remove a completed upload from storage
  static Future<void> removeUpload(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final uploads = await getQueuedUploads();
    uploads.removeWhere((u) => u.questionId == questionId);
    
    final jsonList = uploads.map((u) => u.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
    print('🗑️ [VideoUploadService] Removed upload: $questionId');
  }

  /// Process all pending uploads
  static Future<void> processPendingUploads({
    required Function(String, String) onProgress,
    required Function(String, bool) onComplete,
  }) async {
    final uploads = await getQueuedUploads();
    final pendingUploads = uploads.where((u) => u.status == 'pending' || u.status == 'uploading').toList();
    
    print('📤 [VideoUploadService] processPendingUploads: Found ${pendingUploads.length} pending uploads');
    
    if (pendingUploads.isEmpty) {
      print('✅ [VideoUploadService] No pending uploads to process');
      return;
    }

    print('📤 [VideoUploadService] Processing ${pendingUploads.length} uploads');

    for (int i = 0; i < pendingUploads.length; i++) {
      final upload = pendingUploads[i];
      int retryCount = 0;
      const maxRetries = 2;
      bool uploadSuccess = false;

      while (retryCount <= maxRetries && !uploadSuccess) {
        try {
          print('\n🔄 [VideoUploadService] [$i/${pendingUploads.length - 1}] Attempt ${retryCount + 1}/$maxRetries uploading: ${upload.question}');
          onProgress(upload.questionId, 'Uploading... (${retryCount + 1}/$maxRetries)');
          await updateUploadStatus(upload.questionId, 'uploading');
          
          uploadSuccess = await _uploadVideo(upload);
          print('📊 [VideoUploadService] Upload result for ${upload.question}: $uploadSuccess');
          
          if (uploadSuccess) {
            onProgress(upload.questionId, 'Completed ✓');
            onComplete(upload.questionId, true);
            // Auto-remove completed upload
            await removeUpload(upload.questionId);
          } else {
            retryCount++;
            if (retryCount <= maxRetries) {
              print('⚠️ [VideoUploadService] Retrying in 5 seconds...');
              onProgress(upload.questionId, 'Retrying... (${retryCount}/$maxRetries)');
              await Future.delayed(const Duration(seconds: 5));
            }
          }
        } catch (e, st) {
          retryCount++;
          print('❌ [VideoUploadService] Exception (attempt $retryCount): $e');
          if (retryCount > maxRetries) {
            print('❌ [VideoUploadService] Max retries exceeded for ${upload.question}');
            await updateUploadStatus(upload.questionId, 'failed', error: e.toString());
            onProgress(upload.questionId, 'Failed');
            onComplete(upload.questionId, false);
          } else {
            // Check if it's a network error or server error
            final isNetworkError = e.toString().contains('SocketException') || 
                                   e.toString().contains('Connection') ||
                                   e.toString().contains('timeout');
            
            // For network errors, retry sooner (3 seconds)
            // For other errors, wait longer (10 seconds)
            final delaySeconds = isNetworkError ? 3 : 10;
            print('⚠️ [VideoUploadService] ${isNetworkError ? 'Network error' : 'Server error'} - Retrying in $delaySeconds seconds...');
            onProgress(upload.questionId, 'Retrying... (${retryCount}/$maxRetries)');
            await Future.delayed(Duration(seconds: delaySeconds));
          }
        }
      }
      
      // Add delay between uploads to avoid overwhelming the server
      if (i < pendingUploads.length - 1) {
        print('⏳ [VideoUploadService] Waiting 2 seconds before next upload...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    print('✅ [VideoUploadService] All uploads processed');
  }

  static Future<bool> _uploadVideo(VideoUpload upload) async {
    final file = File(upload.localPath);
    if (!await file.exists()) {
      print('❌ [VideoUploadService] File not found: ${upload.localPath}');
      await updateUploadStatus(upload.questionId, 'failed', 
        error: 'File not found');
      return false;
    }

    try {
      print('📊 [VideoUploadService] Starting upload for: ${upload.question}');
      print('📊 [VideoUploadService] File path: ${upload.localPath}');
      
      final fileSize = await file.length();
      print('📊 [VideoUploadService] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      final authCookie = await _getAuthCookie();
      print('🔐 [VideoUploadService] Auth cookie length: ${authCookie.length}');
      if (authCookie.isEmpty) {
        print('⚠️ [VideoUploadService] WARNING: Auth cookie is empty!');
      }
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authCookie.isNotEmpty) 'Cookie': authCookie,
      };

      // Get SAS token
      print('🔄 [VideoUploadService] Step 1: Getting SAS token...');
      final monthYearFolder = _monthYearFolder();
      final studentNameForFile = await _getStudentNameForFilename();
      final sanitisedStudent = _sanitizeNameForFile(studentNameForFile);
      final random12 = _generateRandomCode(12);
      final generatedFileName = '$sanitisedStudent-$random12.mp4';
      final backendFolder = 'student_Videos/$monthYearFolder';
      
      print('  - Folder: $backendFolder');
      print('  - File: $generatedFileName');

      final sasEndpoint = Uri.parse(
        '${ApiConstantsStu.subUrl}common/sas-token'
        '?folderName=${Uri.encodeComponent(backendFolder)}'
        '&filesName=${Uri.encodeComponent(generatedFileName)}'
        '&filesSize=$fileSize'
        '&filesType=video/mp4'
      );
      
      print('  - SAS URL: $sasEndpoint');

      final sasResp = await http.get(sasEndpoint, headers: headers)
        .timeout(const Duration(seconds: 60));

      print('  - SAS Response: ${sasResp.statusCode}');
      if (sasResp.statusCode != 200) {
        print('❌ SAS token failed: ${sasResp.statusCode}');
        print('   Response body: ${sasResp.body}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'SAS token failed: ${sasResp.statusCode}');
        return false;
      }

      final Map<String, dynamic> sasMap = jsonDecode(sasResp.body);
      if (sasMap['status'] != true || sasMap['sas_url'] == null) {
        print('❌ Invalid SAS response: ${sasMap}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'Invalid SAS response');
        return false;
      }

      final String sasUrl = sasMap['sas_url'];
      final String blobUrl = sasMap['blob_url'];
      print('✅ Got SAS token successfully');

      // Upload file with better progress
      print('🔄 [VideoUploadService] Step 2: Uploading file (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)...');
      final fileBytes = await file.readAsBytes();
      print('  - File read into memory');
      
      final putHeaders = {
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': 'video/mp4',
      };

      print('  - Sending PUT request...');
      final putResp = await http
        .put(Uri.parse(sasUrl), headers: putHeaders, body: fileBytes)
        .timeout(const Duration(minutes: 10));

      print('  - PUT response: ${putResp.statusCode}');
      if (putResp.statusCode != 201 && putResp.statusCode != 200) {
        print('❌ Upload failed: ${putResp.statusCode}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'Upload failed: ${putResp.statusCode}');
        return false;
      }

      print('✅ File uploaded successfully');

      // Register video
      print('🔄 [VideoUploadService] Step 3: Registering video...');
      final registerEndpoint = 
        Uri.parse('${ApiConstantsStu.subUrl}profile/student/update-video');
      final videoAction = _mapQuestionToAction(upload.question);
      
      // Extract just filename from blob URL
      final blobFileName = blobUrl.split('/').last;
      
      final registerBody = jsonEncode({
        "fileUploadName": blobUrl,
        "video-action": videoAction,
      });
      final registerHeaders = {
        'Content-Type': 'application/json',
        if (authCookie.isNotEmpty) 'Cookie': authCookie,
      };

      print('  - Register URL: $registerEndpoint');
      print('  - Video action: $videoAction');
      print('  - Blob URL: $blobUrl');
      print('  - Blob filename: $blobFileName');
      print('  - Request body: $registerBody');
      
      final registerResp = await http.post(
        registerEndpoint,
        headers: registerHeaders,
        body: registerBody,
      ).timeout(const Duration(seconds: 60));

      print('  - Register response: ${registerResp.statusCode}');
      print('  - Register response body: ${registerResp.body}');
      
      // Handle 5xx errors differently (server issues - should retry)
      if (registerResp.statusCode >= 500 && registerResp.statusCode < 600) {
        print('❌ Registration server error: ${registerResp.statusCode}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'Server error: ${registerResp.statusCode}');
        return false;
      }
      
      // Handle other HTTP errors
      if (registerResp.statusCode != 200 && registerResp.statusCode != 201) {
        print('❌ Registration failed: ${registerResp.statusCode}');
        print('   Response body: ${registerResp.body}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'Registration failed: ${registerResp.statusCode}');
        return false;
      }

      final Map<String, dynamic> regMap = jsonDecode(registerResp.body);
      if (regMap['status'] != true) {
        print('❌ Server failed to register video: ${regMap}');
        await updateUploadStatus(upload.questionId, 'failed', 
          error: 'Server registration failed');
        return false;
      }

      await updateUploadStatus(upload.questionId, 'completed', 
        blobUrl: blobUrl);
      print('✅ [VideoUploadService] Successfully uploaded ${upload.question}');
      return true;
    } catch (e, st) {
      print('❌ [VideoUploadService] Upload exception: $e');
      print('   Stack: $st');
      await updateUploadStatus(upload.questionId, 'failed', error: e.toString());
      return false;
    }
  }

  static String _monthYearFolder() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]}_${now.year}';
  }

  static Future<String> _getStudentNameForFilename() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('student_name') ?? 'student';
  }

  static String _sanitizeNameForFile(String name) {
    final sanitized = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return sanitized.isNotEmpty ? sanitized.substring(0, 
      sanitized.length > 15 ? 15 : sanitized.length) : 'student';
  }

  static String _generateRandomCode(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static Future<String> _getAuthCookie() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try different possible keys for auth token
    final authToken = prefs.getString('authToken') ?? 
                     prefs.getString('auth_token') ?? 
                     '';
    
    // Try to get connectSid if it exists
    final connectSid = prefs.getString('connectSid') ?? '';
    
    print('🔐 [VideoUploadService] _getAuthCookie:');
    print('   - authToken found: ${authToken.isNotEmpty}');
    print('   - connectSid found: ${connectSid.isNotEmpty}');
    
    // Build cookie header: authToken=xxx; connect.sid=yyy
    if (authToken.isNotEmpty && connectSid.isNotEmpty) {
      return 'authToken=$authToken; connect.sid=$connectSid';
    } else if (authToken.isNotEmpty) {
      return 'authToken=$authToken';
    } else if (connectSid.isNotEmpty) {
      return 'connect.sid=$connectSid';
    }
    
    return '';
  }

  static String _mapQuestionToAction(String question) {
    final questionFieldMap = {
      'tell me about yourself': 'about_yourself',
      'how do you organize your day?': 'organize_your_day',
      'what are your strengths?': 'your_strength',
      'what is something you have taught yourself lately?': 'taught_yourself_tately',
    };
    
    final normalizedQuestion = question.toLowerCase().trim();
    return questionFieldMap[normalizedQuestion] ?? 'about_yourself';
  }
}

