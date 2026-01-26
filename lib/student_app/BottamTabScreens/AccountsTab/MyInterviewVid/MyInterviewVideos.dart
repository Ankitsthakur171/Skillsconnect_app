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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../Model/My_Interview_Videos_Model.dart';
import '../../../Pages/Notification_icon_Badge.dart';
import '../../../Utilities/ApiConstants.dart';
import '../../../Utilities/MyAccount_Get_Post/My_Interview_Videos_Api.dart';
import '../../../Services/VideoUploadService.dart';
import 'VideopreviewScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final String youtubeUrl = 'https://www.youtube.com/watch?v=yeTExU0nuho';
  YoutubePlayerController? _controller;
  String _videoId = '';

  bool _isUploading = false;
  Map<String, String> _uploadProgress = {}; // Track upload progress: questionId -> status

  bool _showYoutube = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoId = _extractVideoId(youtubeUrl) ?? '';
    _createControllerIfNeeded();
    _fetchVideoIntro();
    _loadQueuedUploads(); // Load any previously queued uploads
    _processPendingUploads(); // Process them in background
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        _controller?.pause();
      }
    } catch (e) {
      print('Lifecycle pause error: $e');
    }
  }

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
    final idFromWatch = YoutubePlayer.convertUrlToId(url);
    final videoId = idFromWatch;
    print('🔍 [MyInterviewVideos] Extracted YouTube video ID: $videoId');
    if (videoId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Invalid YouTube URL', style: TextStyle(fontSize: 12))),
        );
      });
    }
    return videoId;
  }

  void _createControllerIfNeeded() {
    if (_videoId.isEmpty) return;
    if (_controller != null) return;

    try {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          forceHD: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
        ),
      );
    } catch (e) {
      print('Error creating YoutubePlayerController: $e');
      _controller = null;
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

    try {
      _controller?.pause();
    } catch (e) {
      print('Pause error while disposing controller: $e');
    }

    try {
      _controller?.dispose();
    } catch (e) {
      print('Dispose error for controller: $e');
    }

    _controller = null;
  }

  Future<void> _recordVideo(String question) async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.microphone,
    ].request();

    final picker = ImagePicker();
    final XFile? recorded = await picker.pickVideo(
        source: ImageSource.camera, maxDuration: const Duration(seconds: 60));

    if (recorded == null) {
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final normalized = question.trim().toLowerCase();
      final safeFileName = "${normalized.replaceAll(RegExp(r'\s+'), "_")}.mp4";
      final newPath = path.join(appDir.path, safeFileName);

      final File newVideo = await File(recorded.path).copy(newPath);

      setState(() {
        _questionVideoPaths[normalized] = newVideo.path;
      });

      await _uploadRecordedVideoAndRegister(newVideo.path, normalized);
    } catch (e, st) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save video: $e')),
      );
    }
  }

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
    setState(() => _isUploading = true);

    try {
      await VideoUploadService.processPendingUploads(
        onProgress: (questionId, status) {
          print('📤 [MyInterviewVideos] Progress callback: $questionId -> $status');
          if (mounted) {
            setState(() {
              _uploadProgress[questionId] = status;
            });
          }
        },
        onComplete: (questionId, success) {
          print('✅ [MyInterviewVideos] Complete callback: $questionId -> ${success ? 'success' : 'failed'}');
          if (mounted) {
            if (success) {
              setState(() {
                _uploadProgress[questionId] = 'Completed ✓';
              });
            } else {
              setState(() {
                _uploadProgress[questionId] = 'Failed - Check logs';
              });
            }
          }
        },
      );

      // Refresh data
      await _fetchVideoIntro();

      print('✅ [MyInterviewVideos] All uploads processed');
    } catch (e) {
      print('❌ [MyInterviewVideos] Error in _processPendingUploads: $e');
    } finally {
      setState(() => _isUploading = false);
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
                      child: ClipRect(
                        child: SizedBox(
                          width: availableWidth,
                          height: playerHeight,
                          child: (_videoId.isNotEmpty &&
                                  _controller != null &&
                                  _showYoutube)
                              ? YoutubePlayerBuilder(
                                  player: YoutubePlayer(
                                    controller: _controller!,
                                    showVideoProgressIndicator: true,
                                    progressIndicatorColor:
                                        const Color(0xFF005E6A),
                                  ),
                                  builder: (context, player) {
                                    return FittedBox(
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: availableWidth,
                                        height: availableWidth * (9 / 16) >
                                                playerHeight
                                            ? playerHeight
                                            : availableWidth * (9 / 16),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: player,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    _videoId.isEmpty
                                        ? 'Invalid YouTube URL'
                                        : 'Player stopped',
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 12.sp),
                                  ),
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
          Text(
            "• This video will automatically stop playing after 60 seconds.",
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
          ),
          Text(
            "• Please ensure that the video and audio quality are of good standard.",
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
          ),
          Text(
            "• The Background should have no visible elements and be transparent.",
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
          ),
          Text(
            "• You can retake or check the video before uploading.",
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
          ),
          Text(
            "• Once you upload the video, it will no longer be available to re-take.",
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF003840)),
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005E6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
            icon: Icon(
              canPreview ? Icons.play_circle_fill_outlined : Icons.play_arrow,
              size: 18.w,
              color: Colors.white,
            ),
            label: Text(
              canPreview ? "Preview" : "Start",
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
            ),
            onPressed: () async {
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
                  try {
                    if (_videoId.isNotEmpty && _controller == null) {
                      _createControllerIfNeeded();
                      if (mounted) {
                        setState(() {
                          _showYoutube = true;
                        });
                      }
                    } else {
                      if (mounted) setState(() => _showYoutube = true);
                    }
                  } catch (e) {
                    print('Error recreating controller after preview pop: $e');
                  }
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
                          style:
                              TextStyle(color: Colors.black, fontSize: 12.sp),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 7.h),
                        ),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          "Proceed",
                          style:
                              TextStyle(color: Colors.white, fontSize: 12.sp),
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
