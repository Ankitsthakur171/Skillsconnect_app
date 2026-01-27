import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../ApiConstants.dart';

class ProfilePictureApi {
  /// Upload profile picture to Azure Blob and register with backend
  /// Returns the blob URL on success, null on failure
  static Future<String?> uploadProfilePicture({
    required File imageFile,
  }) async {
    try {
      print('📤 [ProfilePictureApi] Starting profile picture upload...');
      
      // Check if file exists
      if (!await imageFile.exists()) {
        print('❌ [ProfilePictureApi] File not found: ${imageFile.path}');
        return null;
      }

      final fileSize = await imageFile.length();
      print('📊 [ProfilePictureApi] File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      // Get auth cookie
      final authCookie = await _getAuthCookie();
      if (authCookie.isEmpty) {
        print('⚠️ [ProfilePictureApi] WARNING: Auth cookie is empty!');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authCookie.isNotEmpty) 'Cookie': authCookie,
      };

      // Step 1: Get SAS token
      print('🔄 [ProfilePictureApi] Step 1: Getting SAS token...');
      final monthYearFolder = _monthYearFolder();
      final studentNameForFile = await _getStudentNameForFilename();
      final sanitizedStudent = _sanitizeNameForFile(studentNameForFile);
      final random12 = _generateRandomCode(12);
      final fileName = '$sanitizedStudent-$random12${_getFileExtension(imageFile.path)}';
      final backendFolder = 'student_profile_pic/$monthYearFolder';
      final contentType = _detectContentType(imageFile.path);
      
      print('  - Folder: $backendFolder');
      print('  - File: $fileName');
      print('  - Content Type: $contentType');

      final sasEndpoint = Uri.parse(
        '${ApiConstantsStu.subUrl}common/sas-token'
        '?folderName=${Uri.encodeComponent(backendFolder)}'
        '&filesName=${Uri.encodeComponent(fileName)}'
        '&filesSize=$fileSize'
        '&filesType=${Uri.encodeComponent(contentType)}'
      );
      
      print('  - SAS URL: $sasEndpoint');

      final sasResp = await http.get(sasEndpoint, headers: headers)
        .timeout(const Duration(seconds: 60));

      print('  - SAS Response: ${sasResp.statusCode}');
      if (sasResp.statusCode != 200) {
        print('❌ SAS token failed: ${sasResp.statusCode}');
        print('   Response body: ${sasResp.body}');
        return null;
      }

      final Map<String, dynamic> sasMap = jsonDecode(sasResp.body);
      if (sasMap['status'] != true || sasMap['sas_url'] == null) {
        print('❌ Invalid SAS response: $sasMap');
        return null;
      }

      final String sasUrl = sasMap['sas_url'];
      final String blobUrl = sasMap['blob_url'];
      print('✅ Got SAS token successfully');
      print('  - Blob URL: $blobUrl');

      // Step 2: Upload to Azure Blob
      print('🔄 [ProfilePictureApi] Step 2: Uploading to Azure Blob...');
      final imageBytes = await imageFile.readAsBytes();
      print('  - Image read into memory');
      
      final putHeaders = {
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': contentType,
      };

      print('  - Sending PUT request...');
      final putResp = await http
        .put(Uri.parse(sasUrl), headers: putHeaders, body: imageBytes)
        .timeout(const Duration(minutes: 5));

      print('  - PUT response: ${putResp.statusCode}');
      if (putResp.statusCode != 201 && putResp.statusCode != 200) {
        print('❌ Azure upload failed: ${putResp.statusCode}');
        return null;
      }

      print('✅ Image uploaded to Azure successfully');

      // Step 3: Register with backend
      print('🔄 [ProfilePictureApi] Step 3: Registering profile picture...');
      final registerEndpoint = 
        Uri.parse('${ApiConstantsStu.subUrl}profile/update-profile-pic');
      
      final registerBody = jsonEncode({
        "profile_url": blobUrl,
        "image_name": fileName,
        "profile_action": "user-profile-pic",
      });
      
      final registerHeaders = {
        'Content-Type': 'application/json',
        if (authCookie.isNotEmpty) 'Cookie': authCookie,
      };

      print('  - Register URL: $registerEndpoint');
      print('  - Request body: $registerBody');
      
      final registerResp = await http.post(
        registerEndpoint,
        headers: registerHeaders,
        body: registerBody,
      ).timeout(const Duration(seconds: 60));

      print('  - Register response: ${registerResp.statusCode}');
      print('  - Register response body: ${registerResp.body}');
      
      if (registerResp.statusCode != 200 && registerResp.statusCode != 201) {
        print('❌ Registration failed: ${registerResp.statusCode}');
        print('   Response body: ${registerResp.body}');
        return null;
      }

      final Map<String, dynamic> regMap = jsonDecode(registerResp.body);
      if (regMap['success'] != true && regMap['status'] != true) {
        print('❌ Server failed to register profile picture: $regMap');
        return null;
      }

      print('✅ [ProfilePictureApi] Successfully uploaded and registered profile picture');
      return blobUrl;
    } catch (e, st) {
      print('❌ [ProfilePictureApi] Upload exception: $e');
      print('   Stack: $st');
      return null;
    }
  }

  // Helper methods

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
    
    final authToken = prefs.getString('authToken') ?? '';
    final connectSid = prefs.getString('connectSid') ?? '';
    
    print('🔐 [ProfilePictureApi] _getAuthCookie:');
    print('   - authToken found: ${authToken.isNotEmpty}');
    print('   - connectSid found: ${connectSid.isNotEmpty}');
    
    if (authToken.isNotEmpty && connectSid.isNotEmpty) {
      return 'authToken=$authToken; connect.sid=$connectSid';
    } else if (authToken.isNotEmpty) {
      return 'authToken=$authToken';
    } else if (connectSid.isNotEmpty) {
      return 'connect.sid=$connectSid';
    }
    
    return '';
  }

  static String _detectContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // default
  }

  static String _getFileExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.jpg')) return '.jpg';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.webp')) return '.webp';
    return '.jpg'; // default
  }
}
