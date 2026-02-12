import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillsconnect/student_app/BottamTabScreens/AccountsTab/MyInterviewVid/camera_record_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:http/http.dart' as http;
import '../../../Model/My_Interview_Videos_Model.dart';
import '../../../Pages/Notification_icon_Badge.dart';
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/MyAccount_Get_Post/My_Interview_Videos_Api.dart';
import '../../../Services/VideoUploadService.dart';
import 'VideopreviewScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:camera/camera.dart';



class MyInterviewVideos extends StatefulWidget {
  const MyInterviewVideos({super.key});

  @override
  _MyInterviewVideosState createState() => _MyInterviewVideosState();
}

class _MyInterviewVideosState extends State<MyInterviewVideos>
    with WidgetsBindingObserver {

  VideoIntroModel? _videoIntroModel;
  final Map<String, String> _questionVideoPaths = {};
  bool _isFullScreen = false;

  CameraController? _cameraController;
List<CameraDescription>? _cameras;

  

  final String youtubeUrl = 'https://www.youtube.com/watch?v=yeTExU0nuho';
  String _videoId = '';
  WebViewController? _webViewController;
  bool _webViewLoading = false;

  // Scroll controller to detect when player goes offscreen
  ScrollController? _listScrollController;
  // Key for the player widget to compute visibility
  final GlobalKey _playerKey = GlobalKey();

  bool _isUploading = false;
  Map<String, String> _uploadProgress = {}; // Track upload progress: questionId -> status

  bool _showYoutube = false; // don't auto-play or auto-load WebView

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoId = _extractVideoId(youtubeUrl) ?? '';
    // Initialize WebView controller for the embedded YouTube iframe
    try {
      final params = PlatformWebViewControllerCreationParams();
      _webViewController = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController?.setNavigationDelegate(NavigationDelegate(
        onPageStarted: (uri) {
          if (mounted) setState(() => _webViewLoading = true);
        },
        onPageFinished: (uri) {
          if (mounted) setState(() => _webViewLoading = false);
        },
        onWebResourceError: (err) {
          if (mounted) setState(() => _webViewLoading = false);
          print('WebView resource error: ${err.description}');
        },
      ));
      // Do not auto-load the YouTube iframe; wait for user action to avoid
      // embed errors and unnecessary background work.
    } catch (e) {
      print('WebView controller init error: $e');
    }
    // attach scroll controller for visibility detection
    _listScrollController = ScrollController()..addListener(_onScroll);
    _fetchVideoIntro();
    _loadQueuedUploads(); // Load any previously queued uploads
    _processPendingUploads(); // Process them in background
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        // Hide the webview player when app is backgrounded to stop playback
        if (mounted) setState(() => _showYoutube = false);
      }
    } catch (e) {
      print('Lifecycle pause error: $e');
    }
  }

  

// Future<File?> _compressVideo(File inputFile) async {
//   try {
//     final originalSize =
//         inputFile.lengthSync() / (1024 * 1024);
//     print('🎥 Original video size: ${originalSize.toStringAsFixed(2)} MB');

//     final info = await VideoCompress.compressVideo(
//       inputFile.path,
//       quality: VideoQuality.MediumQuality, // ⭐ 720p → ~6–10MB
//       deleteOrigin: false,
//       includeAudio: true,
//     );

//     if (info == null || info.path == null) {
//       print('❌ Video compression failed');
//       return null;
//     }

//     final compressedFile = File(info.path!);
//     final compressedSize =
//         compressedFile.lengthSync() / (1024 * 1024);

//     print(
//         '🎥 Compressed video size: ${compressedSize.toStringAsFixed(2)} MB');

//     return compressedFile;
//   } catch (e) {
//     print('❌ Compression error: $e');
//     return null;
//   }
// }


  Future<void> _fetchVideoIntro() async {
    final api = VideoIntroApi();
    final data = await api.fetchVideoIntroQuestions();

    if (data != null) {
      setState(() {
        _videoIntroModel = data;
        if (data.aboutYourself.trim().isNotEmpty) {
          _questionVideoPaths["tell me about yourself".toLowerCase()] =
              data.aboutYourself;
        }

        if (data.organizeYourDay.trim().isNotEmpty) {
          _questionVideoPaths["how do you organize your day?".toLowerCase()] =
              data.organizeYourDay;
        }

        if (data.yourStrength.trim().isNotEmpty) {
          _questionVideoPaths["what are your strengths?".toLowerCase()] =
              data.yourStrength;
        }

        if (data.taughtYourselfLately.trim().isNotEmpty) {
          _questionVideoPaths[
              "what is something you have taught yourself lately?"
                  .toLowerCase()] = data.taughtYourselfLately;
        }
      });
    }
  }

  String? _extractVideoId(String url) {
    try {
      final pattern = RegExp(
          r'(?:v=|\/embed\/|\.be\/|v\/|watch\?v=)([A-Za-z0-9_-]{11})');
      final match = pattern.firstMatch(url);
      final videoId = match != null ? match.group(1) : null;
      print('🔍 [MyInterviewVideos] Extracted YouTube video ID: $videoId');
      if (videoId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid YouTube URL', style: TextStyle(fontSize: 12))),
          );
        });
      }
      return videoId;
    } catch (e) {
      print('Error extracting video id: $e');
      return null;
    }
  }

  void _hideAndDisposePlayer() {
    if (mounted) {
      try {
        setState(() {
          _showYoutube = false;
        });
      } catch (_) {}
    }
  }

  void _onScroll() {
    if (!mounted) return;
    if (_playerKey.currentContext == null) return;
    if (_isFullScreen) return; // don't auto-pause in fullscreen

    try {
      final renderBox = _playerKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;

      // Determine visible area fraction
      final visibleTop = position.dy.clamp(0.0, screenHeight);
      final visibleBottom = (position.dy + size.height).clamp(0.0, screenHeight);
      final visibleHeight = (visibleBottom - visibleTop).clamp(0.0, size.height);
      final visibleFraction = visibleHeight / size.height;

      // If less than 30% visible, hide the player to stop playback and reduce CPU
      if (visibleFraction < 0.3) {
        if (_showYoutube) {
          setState(() {
            _showYoutube = false;
          });
        }
      }
    } catch (e) {
      // ignore layout exceptions during rapid scroll
    }
  }

  Future<File?> _lightCompress(File input) async {
  try {
    final info = await VideoCompress.compressVideo(
      input.path,
      quality: VideoQuality.LowQuality, // ⚡ FAST
      deleteOrigin: false,
      includeAudio: true,
    );

    if (info?.path == null) return null;

    print('🎥 Light compressed size: ${(File(info!.path!).lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB');
    return File(info.path!);
  } catch (_) {
    return null;
  }
}

Future<void> _recordVideo(String question) async {
  final result = await Navigator.push<File?>(
    context,
    MaterialPageRoute(
      builder: (_) => CameraRecordScreen(question: question),
    ),
  );

  if (result == null) return;

  final normalized = question.trim().toLowerCase();

  final appDir = await getApplicationDocumentsDirectory();
  final safeName =
      "${normalized.replaceAll(RegExp(r'\s+'), "_")}.mp4";
  final finalPath = path.join(appDir.path, safeName);

  final saved = await result.copy(finalPath);

  setState(() {
    _questionVideoPaths[normalized] = saved.path;
  });

  await _uploadRecordedVideoAndRegister(saved.path, normalized);
}


Future<void> _initCamera() async {
  _cameras ??= await availableCameras();

  final frontCamera = _cameras!.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.front,
    orElse: () => _cameras!.first,
  );

  _cameraController = CameraController(
    frontCamera,
    ResolutionPreset.medium, 
    enableAudio: true,
    imageFormatGroup: ImageFormatGroup.yuv420,
  );

  await _cameraController!.initialize();
}


// Future<void> _recordVideo(String question) async {
//   await [
//     Permission.camera,
//     Permission.storage,
//     Permission.microphone,
//   ].request();

//   final picker = ImagePicker();
//   final XFile? recorded = await picker.pickVideo(
//     source: ImageSource.camera,
//     maxDuration: const Duration(seconds: 60),
//   );
//   if (recorded == null) return;
//   try {
//     final normalized = question.trim().toLowerCase();
//     final originalFile = File(recorded.path);
//     // 🔥 COMPRESS VIDEO
//     final compressedFile = await _compressVideo(originalFile);
//     if (compressedFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Video compression failed')),
//       );
//       return;
//     }
//     final appDir = await getApplicationDocumentsDirectory();
//     final safeFileName =
//         "${normalized.replaceAll(RegExp(r'\s+'), "_")}.mp4";
//     final finalPath = path.join(appDir.path, safeFileName);
//     final finalVideo = await compressedFile.copy(finalPath);
//     setState(() {
//       _questionVideoPaths[normalized] = finalVideo.path;
//     });
//     // 🚀 Upload COMPRESSED video
//     await _uploadRecordedVideoAndRegister(finalVideo.path, normalized);
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to record video: $e')),
//     );
//   }
// }


  String _mapQuestionToAction(String normalizedQuestion) {
    if (normalizedQuestion.contains("tell me about")) return "about_yourself";
    if (normalizedQuestion.contains("organize your day")) {
      return "organize_your_day";
    }
    if (normalizedQuestion.contains("strength")) return "your_strength";
    if (normalizedQuestion.contains("taught yourself")) {
      return "taught_yourself_tately";
    }
    // fallback:
    return "about_yourself";
  }

  String _generateRandomCode(int length) {
    final rnd = Random.secure();
    const digits = '0123456789';
    return List.generate(length, (_) => digits[rnd.nextInt(digits.length)])
        .join();
  }

  Future<String> _getAuthCookie() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';
      String cookie = '';
      if (authToken.isNotEmpty) {
        cookie += authToken.contains('authToken=')
            ? authToken
            : 'authToken=$authToken';
      }
      if (connectSid.isNotEmpty) {
        if (cookie.isNotEmpty) cookie += '; ';
        cookie += connectSid.contains('connect.sid=')
            ? connectSid
            : 'connect.sid=$connectSid';
      }
      return cookie;
    } catch (_) {
      return '';
    }
  }

  Future<void> _uploadRecordedVideoAndRegister(
      String localPath, String normalizedQuestion) async
  {
    if (_isUploading) return;

    final file = File(localPath);
    if (!await file.exists()) {
      print('❌ File not found');
      return;
    }

    // Create upload record
    final questionId = normalizedQuestion.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final upload = VideoUpload(
      questionId: questionId,
      localPath: localPath,
      question: normalizedQuestion,
      status: 'pending',
    );

    // Save to queue
    await VideoUploadService.saveUpload(upload);
    print('🎬 [MyInterviewVideos] Saved upload to queue, starting upload now...');
    
    // Show temporary preview
    setState(() {
      _questionVideoPaths[normalizedQuestion] = localPath; // Local path for preview
      _uploadProgress[questionId] = 'Starting upload...';
    });

    // Process uploads IMMEDIATELY (don't wait)
    _processPendingUploads();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video uploaded queued. Starting upload...')),
    );
  }

  Future<void> _loadQueuedUploads() async {
    final uploads = await VideoUploadService.getQueuedUploads();
    for (final upload in uploads) {
      if (upload.blobUrl != null && upload.blobUrl!.isNotEmpty) {
        // Already uploaded, update with blob URL
        setState(() {
          _questionVideoPaths[upload.question] = upload.blobUrl!;
          _uploadProgress[upload.questionId] = 'Completed';
        });
      } else if (upload.status == 'completed') {
        // Mark as completed in UI
        setState(() {
          _uploadProgress[upload.questionId] = 'Completed';
        });
      } else if (upload.status == 'failed') {
        // Show failed status
        setState(() {
          _uploadProgress[upload.questionId] = 'Failed: ${upload.error ?? 'Unknown error'}';
        });
      } else {
        // Pending or uploading
        setState(() {
          _uploadProgress[upload.questionId] = upload.status == 'uploading' ? 'Uploading...' : 'Queued...';
        });
      }
    }
  }

  Future<void> _processPendingUploads() async {
  print('📤 [MyInterviewVideos] _processPendingUploads called');

  if (mounted) {
    setState(() => _isUploading = true);
  }

  try {
    await VideoUploadService.processPendingUploads(
      onProgress: (questionId, status) {
        print('📤 Progress: $questionId -> $status');
        if (mounted) {
          setState(() {
            _uploadProgress[questionId] = status;
          });
        }
      },
      onComplete: (questionId, success) {
        print('✅ Complete: $questionId -> $success');
        if (mounted) {
          setState(() {
            _uploadProgress[questionId] =
                success ? 'Completed ✓' : 'Failed - Check logs';
          });
        }
      },
    );

    await _fetchVideoIntro();
  } catch (e) {
    print('❌ Upload processing error: $e');
  } finally {
    if (mounted) {
      setState(() => _isUploading = false);
    }
  }
}

  String _monthYearFolder() {
    final now = DateTime.now();
    final months = [
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
    return '${months[now.month - 1]}-${now.year}';
  }

  Future<String> _getStudentNameForFilename() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final connectSid = prefs.getString('connectSid') ?? '';
      final url =
          Uri.parse('${ApiConstantsStu.subUrl}profile/student/personal-details');

      String cookie = '';
      if (authToken.isNotEmpty) {
        cookie += authToken.contains('authToken=')
            ? authToken
            : 'authToken=$authToken';
      }
      if (connectSid.isNotEmpty) {
        if (cookie.isNotEmpty) cookie += '; ';
        cookie += connectSid.contains('connect.sid=')
            ? connectSid
            : 'connect.sid=$connectSid';
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (cookie.isNotEmpty) 'Cookie': cookie,
      };

      final resp = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) {
        return 'student';
      }
      final Map<String, dynamic> map = json.decode(resp.body);
      final personal = map['personalDetails'];
      if (personal is List && personal.isNotEmpty) {
        final p = personal[0];
        final first = (p['first_name'] ?? '').toString();
        final last = (p['last_name'] ?? '').toString();
        final result = '$first $last'.trim();
        return result.isEmpty ? 'student' : result;
      }
      return 'student';
    } catch (_) {
      return 'student';
    }
  }

  String _sanitizeNameForFile(String input) {
    final out = input
        .replaceAll(RegExp(r'[^A-Za-z0-9\- ]'), '')
        .trim()
        .replaceAll(' ', '-');
    return out.isEmpty ? 'student' : out;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context,
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true);

    return OrientationBuilder(
      builder: (context, orientation) {
        _isFullScreen = orientation == Orientation.landscape;
        if (_isFullScreen) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }

        return WillPopScope(
          onWillPop: () async {
            _hideAndDisposePlayer();

            await SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp]);
            await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            return true;
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _isFullScreen
                ? null
                : IntroVideosAppBar(
              onBack: () {
                _hideAndDisposePlayer();
                Navigator.pop(context);
              },
            ),

            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              child: ListView(
                controller: _listScrollController,
                children: [
                  Text(
                    "Record Video Interview about Yourself",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003840),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  LayoutBuilder(builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.of(context).size.width;
                    final playerHeight = _isFullScreen
                        ? MediaQuery.of(context).size.height
                        : 160.h;

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: availableWidth,
                        minWidth: 0,
                      ),
                      child: SizedBox(
                        key: _playerKey,
                        width: availableWidth,
                        height: playerHeight,
                        child: (_videoId.isNotEmpty && _showYoutube)
                            ? ClipRect(
                                child: (_webViewController != null)
                                    ? WebViewWidget(controller: _webViewController!)
                                    : const SizedBox.shrink(),
                              )
                            : (_videoId.isEmpty)
                                ? Center(
                                    child: Text(
                                      'Invalid YouTube URL',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12.sp),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () async {
                                      if (_webViewController != null) {
                                        final url = Uri.parse('https://www.youtube-nocookie.com/embed/$_videoId?rel=0&playsinline=1&autoplay=1&mute=1&enablejsapi=1');
                                        if (mounted) {
                                          setState(() {
                                          _showYoutube = true;
                                          _webViewLoading = true;
                                        });
                                        }
                                        try {
                                          await _webViewController!.loadRequest(url);
                                        } catch (e) {
                                          print('WebView load error: $e');
                                          if (mounted) setState(() => _webViewLoading = false);
                                        }
                                      } else {
                                        setState(() => _showYoutube = true);
                                      }
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          'https://img.youtube.com/vi/$_videoId/hqdefault.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          color: Colors.black26,
                                        ),
                                        const Center(
                                          child: Icon(Icons.play_circle_fill,
                                              size: 64, color: Colors.white),
                                        ),
                                        if (_webViewLoading)
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      ],
                                    ),
                                  ),
                      ),
                    );
                  }),
                  SizedBox(height: 14.h),
                  _buildGuidelinesCard(),
                  SizedBox(height: 18.h),
                  _buildQuestionTile("Tell me about Yourself"),
                  _buildQuestionTile("How do you organize your day?"),
                  _buildQuestionTile("What are your strengths?"),
                  _buildQuestionTile(
                      "What is something you have taught yourself lately?"),
                  if (_isUploading)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(width: 10.w),
                          Expanded(
                              child: Text('Uploading video... Please wait.',
                                  style: TextStyle(fontSize: 13.sp))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidelinesCard() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF2F3),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Introduction",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
              color: const Color(0xFF003840),
            ),
          ),
          SizedBox(height: 7.h),
          _bulletRow("This video will automatically stop playing after 60 seconds."),
          _bulletRow("Please ensure that the video and audio quality are of good standard."),
          _bulletRow("The background should have no visible elements and be unobtrusive."),
          _bulletRow("You can retake or check the video before uploading."),
          _bulletRow("Once you upload the video, it will no longer be available to re-take."),
        ],
      ),
    );
  }

  Widget _bulletRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(String question) {
    final normalized = question.trim().toLowerCase();
    final videoPath = _questionVideoPaths[normalized];
    final hasPath = videoPath != null && videoPath.isNotEmpty;
    final isRemote = hasPath &&
        (videoPath!.startsWith('http') || videoPath.startsWith('https'));
    final existsLocally =
        hasPath && !isRemote ? File(videoPath!).existsSync() : false;
    final canPreview = isRemote || existsLocally;

    final questionId = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    // Determine upload status for this question (questionId or normalized key)
    final statusRaw = _uploadProgress[questionId] ?? _uploadProgress[normalized];
    final status = statusRaw ?? '';
    final isInProgress = status.toLowerCase().contains('upload') || status.toLowerCase().contains('queued') || status.toLowerCase().contains('starting');

    return Container(
      key: ValueKey('$normalized-$canPreview'),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF2F3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFCED8D9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              question,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: const Color(0xFF003840),
              ),
            ),
          ),
          // Show upload status on the button if available
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005E6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
            icon: isInProgress
                ? SizedBox(
                    height: 16.h,
                    width: 16.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    canPreview ? Icons.play_circle_fill_outlined : Icons.play_arrow,
                    size: 18.w,
                    color: Colors.white,
                  ),
            label: Text(
              // prefer a friendly status label when uploading/queued, otherwise original labels
              status.isNotEmpty
                  ? (status.length > 18 ? status.substring(0, 18) + '...' : status)
                  : (canPreview ? "Preview" : "Start"),
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
            onPressed: isInProgress
                ? null
                : () async {
                    if (canPreview) {
                      // hide/stop youtube before pushing preview to avoid surface flash
                      _hideAndDisposePlayer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPreviewScreen(
                            videoUrl: videoPath!,
                            question: question,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) setState(() => _showYoutube = true);
                      });
                    } else {
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          title: Text(
                            "Important",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          content: Text(
                            "Once you upload the video, it will no longer be available to re-take!",
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.black, fontSize: 12.sp),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                              ),
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text(
                                "Proceed",
                                style: TextStyle(color: Colors.white, fontSize: 12.sp),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (shouldProceed == true) {
                        _recordVideo(question);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);

  try {
    _hideAndDisposePlayer();
  } catch (_) {}
  try {
    _listScrollController?.removeListener(_onScroll);
    _listScrollController?.dispose();
  } catch (_) {}

  VideoCompress.dispose();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  super.dispose();
}

}

Widget iconCircleButton(IconData icon, {VoidCallback? onPressed}) {
  return Material(
    color: Colors.transparent,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        padding: EdgeInsets.all(9.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20.w, color: Colors.black),
      ),
    ),
  );
}


class IntroVideosAppBar extends StatelessWidget implements PreferredSizeWidget {
  const IntroVideosAppBar({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Size get preferredSize => Size.fromHeight(64.h);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: true,
        bottom: false,
        child: SizedBox(
          height: 64.h,
          child: Padding(
            padding: EdgeInsets.fromLTRB(17.w, 17.h, 17.w, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                iconCircleButton(
                  Icons.arrow_back_ios_new,
                  onPressed: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "My Intro Videos",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: const Color(0xFF003840),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40.h,
                  width: 40.h,
                  child: const Center(child: NotificationBell()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
