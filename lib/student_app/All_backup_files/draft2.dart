// // Full edited file (upload/record logic changed/extended)
//
//
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
// import 'package:http/http.dart' as http;
// import '../../../Model/My_Interview_Videos_Model.dart';
// import '../../../Utilities/MyAccount_Get_Post/My_Interview_Videos_Api.dart';
// import 'VideopreviewScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class MyInterviewVideos extends StatefulWidget {
//   const MyInterviewVideos({super.key});
//
//   @override
//   _MyInterviewVideosState createState() => _MyInterviewVideosState();
// }
//
// class _MyInterviewVideosState extends State<MyInterviewVideos> {
//   VideoIntroModel? _videoIntroModel;
//   final Map<String, String> _questionVideoPaths = {};
//   bool _isFullScreen = false;
//
//   final String youtubeUrl = 'https://www.youtube.com/embed/yeTExU0nuho?si=7GeceW6FeSmT5bAi';
//   late YoutubePlayerController _controller;
//   late String _videoId;
//
//   bool _isUploading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _videoId = _extractVideoId(youtubeUrl) ?? '';
//     _controller = YoutubePlayerController.fromVideoId(
//       videoId: _videoId,
//       autoPlay: false,
//       params: const YoutubePlayerParams(
//         mute: false,
//         showControls: true,
//         showFullscreenButton: true,
//         enableCaption: true,
//       ),
//     );
//     _fetchVideoIntro();
//   }
//
//   Future<void> _fetchVideoIntro() async {
//     final api = VideoIntroApi();
//     final data = await api.fetchVideoIntroQuestions();
//
//     if (data != null) {
//       setState(() {
//         _videoIntroModel = data;
//         if (data.aboutYourself.trim().isNotEmpty) {
//           _questionVideoPaths["tell me about yourself".toLowerCase()] =
//               data.aboutYourself;
//         }
//
//         if (data.organizeYourDay.trim().isNotEmpty) {
//           _questionVideoPaths["how do you organize your day?".toLowerCase()] =
//               data.organizeYourDay;
//         }
//
//         if (data.yourStrength.trim().isNotEmpty) {
//           _questionVideoPaths["what are your strengths?".toLowerCase()] =
//               data.yourStrength;
//         }
//
//         if (data.taughtYourselfLately.trim().isNotEmpty) {
//           _questionVideoPaths[
//           "what is something you have taught yourself lately?"
//               .toLowerCase()] = data.taughtYourselfLately;
//         }
//       });
//     }
//   }
//
//   String? _extractVideoId(String url) {
//     final RegExp regExp = RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]+)');
//     final match = regExp.firstMatch(url);
//     final videoId = match?.group(1);
//     print('🔍 [MyInterviewVideos] Extracted YouTube video ID: $videoId');
//     if (videoId == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid YouTube URL', style: TextStyle(fontSize: 12.sp))),
//         );
//       });
//     }
//     return videoId;
//   }
//
//   // ---------------------------
//   // RECORD -> UPLOAD -> REGISTER
//   // ---------------------------
//   Future<void> _recordVideo(String question) async {
//     print('🔍 [MyInterviewVideos] _recordVideo: requesting permissions');
//     await [
//       Permission.camera,
//       Permission.storage,
//       Permission.microphone,
//     ].request();
//
//     final picker = ImagePicker();
//     print('🔍 [MyInterviewVideos] _recordVideo: opening camera');
//     final XFile? recorded = await picker.pickVideo(
//         source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
//
//     if (recorded == null) {
//       print('🔍 [MyInterviewVideos] _recordVideo: user cancelled or no video recorded');
//       return;
//     }
//
//     print('🔍 [MyInterviewVideos] _recordVideo: recorded file path: ${recorded.path}');
//
//     try {
//       final appDir = await getApplicationDocumentsDirectory();
//       final normalized = question.trim().toLowerCase();
//       final safeFileName = "${normalized.replaceAll(RegExp(r'\s+'), "_")}.mp4";
//       final newPath = path.join(appDir.path, safeFileName);
//       print('🔍 [MyInterviewVideos] _recordVideo: saving copy to $newPath');
//
//       final File newVideo = await File(recorded.path).copy(newPath);
//
//       // Immediately show in UI (local preview available)
//       setState(() {
//         _questionVideoPaths[normalized] = newVideo.path;
//       });
//
//       print('🎥 [MyInterviewVideos] Saved "$question" video to: $newPath');
//
//       // Start upload and register flow
//       await _uploadRecordedVideoAndRegister(newVideo.path, normalized);
//     } catch (e, st) {
//       print('❌ [MyInterviewVideos] _recordVideo: ERROR - $e\n$st');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to save video: $e')),
//       );
//     }
//   }
//
//   /// Helper: map question -> video-action keyword expected by backend.
//   String _mapQuestionToAction(String normalizedQuestion) {
//     if (normalizedQuestion.contains("tell me about")) return "about_yourself";
//     if (normalizedQuestion.contains("organize your day")) return "organize_your_day";
//     if (normalizedQuestion.contains("strength")) return "your_strength";
//     if (normalizedQuestion.contains("taught yourself")) return "taught_yourself_tately";
//     // fallback:
//     return "about_yourself";
//   }
//
//   /// Generate secure numeric string of length digits.
//   String _generateRandomCode(int length) {
//     final rnd = Random.secure();
//     const digits = '0123456789';
//     return List.generate(length, (_) => digits[rnd.nextInt(digits.length)]).join();
//   }
//
//   /// Read authToken and connectSid from SharedPreferences and build cookie string.
//   Future<String> _getAuthCookie() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final authToken = prefs.getString('authToken') ?? '';
//       final connectSid = prefs.getString('connectSid') ?? '';
//       String cookie = '';
//       if (authToken.isNotEmpty) {
//         // sometimes stored token already contains "authToken=" prefix; normalize
//         cookie += authToken.contains('authToken=') ? authToken : 'authToken=$authToken';
//       }
//       if (connectSid.isNotEmpty) {
//         if (cookie.isNotEmpty) cookie += '; ';
//         cookie += connectSid.contains('connect.sid=') ? connectSid : 'connect.sid=$connectSid';
//       }
//       print('🔐 [MyInterviewVideos] _getAuthCookie: cookie="$cookie"');
//       return cookie;
//     } catch (e, st) {
//       print('❌ [MyInterviewVideos] _getAuthCookie error: $e\n$st');
//       return '';
//     }
//   }
//
//   Future<void> _uploadRecordedVideoAndRegister(String localPath, String normalizedQuestion) async {
//     print('🔁 [MyInterviewVideos] _uploadRecordedVideoAndRegister: start for localPath=$localPath, question=$normalizedQuestion');
//
//     if (_isUploading) {
//       print('🔒 [MyInterviewVideos] _uploadRecordedVideoAndRegister: already uploading - skip');
//       return;
//     }
//
//     setState(() => _isUploading = true);
//
//     final file = File(localPath);
//     if (!await file.exists()) {
//       print('❌ [MyInterviewVideos] file does not exist at path: $localPath');
//       setState(() => _isUploading = false);
//       return;
//     }
//
//     final int fileSize = await file.length();
//     final monthYearFolder = _monthYearFolder();
//     final studentNameForFile = await _getStudentNameForFilename();
//     final sanitisedStudent = _sanitizeNameForFile(studentNameForFile);
//
//     // Use requested naming: SanitizedName-<12digits>.mp4
//     final random12 = _generateRandomCode(12);
//     final generatedFileName = '$sanitisedStudent-$random12.mp4';
//     final backendFolder = 'student_Videos/$monthYearFolder';
//
//     print('🔍 [MyInterviewVideos] Preparing to request SAS token');
//     print('   fileSize=$fileSize, folder=$backendFolder, fileName=$generatedFileName');
//
//     final authCookie = await _getAuthCookie();
//     final headers = <String, String>{
//       'Content-Type': 'application/json',
//       if (authCookie.isNotEmpty) 'Cookie': authCookie,
//     };
//
//     try {
//       // 1) REQUEST SAS token (GET)
//       final sasEndpoint = Uri.parse(
//           'https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/common/sas-token'
//               '?folderName=${Uri.encodeComponent(backendFolder)}'
//               '&filesName=${Uri.encodeComponent(generatedFileName)}'
//               '&filesSize=$fileSize'
//               '&filesType=video/mp4'
//       );
//
//       print('➡️ [MyInterviewVideos] GET SAS: $sasEndpoint');
//       final sasResp = await http.get(sasEndpoint, headers: headers).timeout(const Duration(seconds: 60));
//       print('⬅️ [MyInterviewVideos] SAS response status: ${sasResp.statusCode}');
//       if (sasResp.statusCode != 200) {
//         print('❌ [MyInterviewVideos] SAS request failed: ${sasResp.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to get SAS token: ${sasResp.statusCode}')),
//         );
//         setState(() => _isUploading = false);
//         return;
//       }
//
//       final Map<String, dynamic> sasMap = json.decode(sasResp.body);
//       print('📦 [MyInterviewVideos] SAS response body: $sasMap');
//
//       if (sasMap['status'] != true || sasMap['sas_url'] == null || sasMap['blob_url'] == null) {
//         print('❌ [MyInterviewVideos] SAS response missing required fields');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Invalid SAS response')),
//         );
//         setState(() => _isUploading = false);
//         return;
//       }
//
//       final String sasUrl = sasMap['sas_url'];
//       final String blobUrl = sasMap['blob_url'];
//       print('🔑 [MyInterviewVideos] sasUrl: $sasUrl');
//       print('🔗 [MyInterviewVideos] blobUrl: $blobUrl');
//
//       // 2) Upload file bytes to SAS URL via PUT
//       print('⬆️ [MyInterviewVideos] Uploading file to SAS URL ... (this may take a while)');
//
//       final fileBytes = await file.readAsBytes();
//       final putHeaders = {
//         'x-ms-blob-type': 'BlockBlob',
//         'Content-Type': 'video/mp4',
//         // Do not add Authorization - the SAS in URL is enough
//       };
//
//       // Use http.put
//       final putResp = await http.put(Uri.parse(sasUrl), headers: putHeaders, body: fileBytes).timeout(const Duration(minutes: 2));
//       print('⬅️ [MyInterviewVideos] PUT upload status: ${putResp.statusCode}');
//       if (putResp.statusCode != 201 && putResp.statusCode != 200) {
//         print('❌ [MyInterviewVideos] Upload failed: status=${putResp.statusCode}, body=${putResp.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Upload failed: ${putResp.statusCode}')),
//         );
//         setState(() => _isUploading = false);
//         return;
//       }
//       print('✅ [MyInterviewVideos] Upload succeeded.');
//
//       // 3) Register the uploaded video with backend via POST update-video
//       final registerEndpoint = Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/profile/student/update-video');
//       final videoAction = _mapQuestionToAction(normalizedQuestion);
//       final registerBody = json.encode({
//         "fileUploadName": blobUrl,
//         "video-action": videoAction,
//       });
//       final registerHeaders = {
//         'Content-Type': 'application/json',
//         if (authCookie.isNotEmpty) 'Cookie': authCookie,
//       };
//
//       print('➡️ [MyInterviewVideos] Registering uploaded video with backend: $registerEndpoint');
//       print('    body: $registerBody');
//       final registerResp = await http.post(registerEndpoint, headers: registerHeaders, body: registerBody).timeout(const Duration(seconds: 60));
//       print('⬅️ [MyInterviewVideos] Register response status: ${registerResp.statusCode}');
//       print('📦 [MyInterviewVideos] Register response body: ${registerResp.body}');
//
//       if (registerResp.statusCode != 200) {
//         print('❌ [MyInterviewVideos] Register API failed: ${registerResp.statusCode}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to register uploaded video')),
//         );
//         setState(() => _isUploading = false);
//         return;
//       }
//
//       // Optionally parse response to ensure success
//       final Map<String, dynamic> regMap = json.decode(registerResp.body);
//       if (regMap['status'] != true) {
//         print('❌ [MyInterviewVideos] Backend returned status=false for register: $regMap');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Server failed to register video')),
//         );
//         setState(() => _isUploading = false);
//         return;
//       }
//
//       print('🎉 [MyInterviewVideos] Video registered successfully. Refetching video intro data...');
//       // 4) REFRESH data so that preview will be available
//       await _fetchVideoIntro();
//
//       // 5) Update local map (prefer remote blob URL so preview works)
//       setState(() {
//         _questionVideoPaths[normalizedQuestion] = blobUrl;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Video uploaded and registered successfully')),
//       );
//       print('✅ [MyInterviewVideos] Flow completed successfully for question: $normalizedQuestion');
//     } catch (e, st) {
//       print('❌ [MyInterviewVideos] Exception in upload/register flow: $e\n$st');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Upload flow failed: $e')),
//       );
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }
//
//   // helper: month-year folder like Sep-2025 (matches your logs)
//   String _monthYearFolder() {
//     final now = DateTime.now();
//     final months = [
//       'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
//     ];
//     return '${months[now.month - 1]}-${now.year}';
//   }
//
//   // helper: tries to fetch student name for file naming by calling the same endpoint you use.
//   // This duplicates some logs you posted earlier (works even if you only have cookie-based auth).
//   Future<String> _getStudentNameForFilename() async {
//     print('🔍 [MyInterviewVideos] _getStudentNameForFilename: start');
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final authToken = prefs.getString('authToken') ?? '';
//       final connectSid = prefs.getString('connectSid') ?? '';
//       final url = Uri.parse('https://api.skillsconnect.in/dcxqyqzqpdydfk/mobile/profile/student/personal-details');
//
//       // Build cookie header with both values if present
//       String cookie = '';
//       if (authToken.isNotEmpty) cookie += authToken.contains('authToken=') ? authToken : 'authToken=$authToken';
//       if (connectSid.isNotEmpty) {
//         if (cookie.isNotEmpty) cookie += '; ';
//         cookie += connectSid.contains('connect.sid=') ? connectSid : 'connect.sid=$connectSid';
//       }
//
//       final headers = <String, String>{
//         'Content-Type': 'application/json',
//         if (cookie.isNotEmpty) 'Cookie': cookie,
//       };
//
//       print('➡️ [MyInterviewVideos] GET personal-details: $url (with Cookie: ${cookie.isNotEmpty})');
//       final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 60));
//       print('⬅️ [MyInterviewVideos] personal-details status: ${resp.statusCode}');
//       if (resp.statusCode != 200) {
//         print('❌ [MyInterviewVideos] personal-details failed: ${resp.body}');
//         return 'student';
//       }
//       final Map<String, dynamic> map = json.decode(resp.body);
//       final personal = map['personalDetails'];
//       if (personal is List && personal.isNotEmpty) {
//         final p = personal[0];
//         final first = (p['first_name'] ?? '').toString();
//         final last = (p['last_name'] ?? '').toString();
//         final result = '$first $last'.trim();
//         print('🔍 [MyInterviewVideos] got student name: $result');
//         return result.isEmpty ? 'student' : result;
//       }
//       return 'student';
//     } catch (e, st) {
//       print('❌ [MyInterviewVideos] _getStudentNameForFilename error: $e\n$st');
//       return 'student';
//     }
//   }
//
//   String _sanitizeNameForFile(String input) {
//     final out = input.replaceAll(RegExp(r'[^A-Za-z0-9\- ]'), '').trim().replaceAll(' ', '-');
//     print('🔍 [MyInterviewVideos] _sanitizeNameForFile: input="$input" output="$out"');
//     return out.isEmpty ? 'student' : out;
//   }
//
//   // ---------------------------
//   // UI AND BUILD (unchanged)
//   // ---------------------------
//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(context, designSize: const Size(390, 844), minTextAdapt: true, splitScreenMode: true);
//
//     return OrientationBuilder(
//       builder: (context, orientation) {
//         _isFullScreen = orientation == Orientation.landscape;
//         if (_isFullScreen) {
//           SystemChrome.setPreferredOrientations([
//             DeviceOrientation.landscapeLeft,
//             DeviceOrientation.landscapeRight
//           ]);
//           SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//         } else {
//           SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//           SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//         }
//
//         return WillPopScope(
//           onWillPop: () async {
//             await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//             await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//             return true;
//           },
//           child: Scaffold(
//             backgroundColor: Colors.white,
//             appBar: _isFullScreen
//                 ? null
//                 : AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               leading: iconCircleButton(
//                 Icons.arrow_back_ios_new,
//                 onPressed: () => Navigator.pop(context),
//               ),
//               centerTitle: true,
//               title: Text(
//                 "My Intro Videos",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16.sp,
//                   color: const Color(0xFF003840),
//                 ),
//               ),
//               actions: [
//                 iconCircleButton(Icons.notifications_none),
//               ],
//             ),
//             body: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
//               child: ListView(
//                 children: [
//                   Text(
//                     "Record Video Interview about Yourself",
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.w600,
//                       color: const Color(0xFF003840),
//                     ),
//                   ),
//                   SizedBox(height: 14.h),
//                   SizedBox(
//                     height: _isFullScreen
//                         ? MediaQuery.of(context).size.height
//                         : 160.h,
//                     child: _videoId.isNotEmpty
//                         ? YoutubePlayer(controller: _controller)
//                         : Center(
//                       child: Text(
//                         'Invalid YouTube URL',
//                         style: TextStyle(color: Colors.red, fontSize: 12.sp),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 14.h),
//                   _buildGuidelinesCard(),
//                   SizedBox(height: 18.h),
//                   _buildQuestionTile("Tell me about Yourself"),
//                   _buildQuestionTile("How do you organize your day?"),
//                   _buildQuestionTile("What are your strengths?"),
//                   _buildQuestionTile("What is something you have taught yourself lately?"),
//                   if (_isUploading)
//                     Padding(
//                       padding: EdgeInsets.only(top: 12.h),
//                       child: Row(
//                         children: [
//                           CircularProgressIndicator(),
//                           SizedBox(width: 10.w),
//                           Expanded(child: Text('Uploading video... Please wait.', style: TextStyle(fontSize: 13.sp))),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildGuidelinesCard() {
//     return Container(
//       padding: EdgeInsets.all(10.w),
//       decoration: BoxDecoration(
//         color: const Color(0xFFDFF2F3),
//         borderRadius: BorderRadius.circular(10.r),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Introduction",
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 14.sp,
//               color: const Color(0xFF003840),
//             ),
//           ),
//           SizedBox(height: 7.h),
//           Text(
//             "• This video will automatically stop playing after 60 seconds.",
//             style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
//           ),
//           Text(
//             "• Please ensure that the video and audio quality are of good standard.",
//             style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
//           ),
//           Text(
//             "• The Background should have no visible elements and be transparent.",
//             style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
//           ),
//           Text(
//             "• You can retake or check the video before uploading.",
//             style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
//           ),
//           Text(
//             "• Once you upload the video, it will no longer be available to retake.",
//             style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuestionTile(String question) {
//     final normalized = question.trim().toLowerCase();
//     final videoPath = _questionVideoPaths[normalized];
//     final hasPath = videoPath != null && videoPath.isNotEmpty;
//     final isRemote = hasPath && (videoPath!.startsWith('http') || videoPath.startsWith('https'));
//     final existsLocally = hasPath && !isRemote ? File(videoPath!).existsSync() : false;
//     final canPreview = isRemote || existsLocally;
//
//     return Container(
//       key: ValueKey('$normalized-$canPreview'),
//       margin: EdgeInsets.only(bottom: 12.h),
//       padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
//       decoration: BoxDecoration(
//         color: const Color(0xFFDFF2F3),
//         borderRadius: BorderRadius.circular(10.r),
//         border: Border.all(color: const Color(0xFFCED8D9)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Flexible(
//             child: Text(
//               question,
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 14.sp,
//                 color: const Color(0xFF003840),
//               ),
//               maxLines: 2,
//             ),
//           ),
//           SizedBox(width:2.w),
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF005E6A),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(25.r),
//               ),
//               padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
//             ),
//             icon: Icon(
//               canPreview ? Icons.play_circle_fill_outlined : Icons.play_arrow,
//               size: 18.w,
//               color: Colors.white,
//             ),
//             label: Text(
//               canPreview ? "Preview" : "Start",
//               style: TextStyle(color: Colors.white, fontSize: 13.sp),
//             ),
//             onPressed: () async {
//               print('🔍 [MyInterviewVideos] Button pressed for question: $question, canPreview: $canPreview, videoPath: $videoPath');
//               if (canPreview) {
//                 print('🔍 [MyInterviewVideos] Navigating to VideoPreviewScreen for question: $question');
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => VideoPreviewScreen(
//                       videoUrl: videoPath!,
//                       question: question,
//                     ),
//                   ),
//                 );
//               } else {
//                 print('🔍 [MyInterviewVideos] Showing AlertDialog for question: $question');
//                 final shouldProceed = await showDialog<bool>(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (context) => AlertDialog(
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20.r),
//                     ),
//                     title: Text(
//                       "Important",
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
//                     ),
//                     content: Text(
//                       "Once you upload the video, it will no longer be available to retake!",
//                       style: TextStyle(color: Colors.red, fontSize: 13.sp, fontWeight: FontWeight.w600),
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () {
//                           print('🔍 [MyInterviewVideos] AlertDialog: Cancel pressed for question: $question');
//                           Navigator.pop(context, false);
//                         },
//                         child: Text(
//                           "Cancel",
//                           style: TextStyle(color: Colors.black, fontSize: 12.sp),
//                         ),
//                       ),
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10.r),
//                           ),
//                           padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
//                         ),
//                         onPressed: () {
//                           print('🔍 [MyInterviewVideos] AlertDialog: Proceed pressed for question: $question');
//                           Navigator.pop(context, true);
//                         },
//                         child: Text(
//                           "Proceed",
//                           style: TextStyle(color: Colors.white, fontSize: 12.sp),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//                 if (shouldProceed == true) {
//                   print('🔍 [MyInterviewVideos] Proceeding with video recording for question: $question');
//                   _recordVideo(question);
//                 } else {
//                   print('🔍 [MyInterviewVideos] Recording cancelled for question: $question');
//                 }
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.close();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     super.dispose();
//   }
// }
//
// Widget iconCircleButton(IconData icon, {VoidCallback? onPressed}) {
//   return Material(
//     color: Colors.transparent,
//     shape: const CircleBorder(),
//     child: InkWell(
//       onTap: onPressed,
//       customBorder: const CircleBorder(),
//       child: Container(
//         margin: EdgeInsets.symmetric(horizontal: 5.w),
//         padding: EdgeInsets.all(9.w),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.grey.withOpacity(0.4)),
//           color: Colors.transparent,
//         ),
//         child: Icon(icon, size: 20.w, color: Colors.black),
//       ),
//     ),
//   );
// }
