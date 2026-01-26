import 'package:flutter/material.dart';
import 'package:skillsconnect/TPO/Model/tpo_applicant_details_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; // Add this in pubspec.yaml
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';


/// 🔹 Manager to ensure only one video plays at a time
class VideoManager {
  static VideoPlayerController? _current;

  static Future<void> play(VideoPlayerController controller) async {
    if (_current != null && _current != controller) {
      try {
        await _current!.pause();
      } catch (_) {}
    }
    _current = controller;
    await controller.play();
  }

  static void dispose(VideoPlayerController controller) {
    if (_current == controller) {
      _current = null;
    }
  }
}

class InterviewVideos extends StatelessWidget {
  final List<TpoVideoIntroduction> videoList;

  const InterviewVideos({super.key, required this.videoList});

  @override
  Widget build(BuildContext context) {
    if (videoList.isEmpty) return const SizedBox.shrink();

    final videos = videoList.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFFEAF6F7),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildVideoTiles(videos),
        ),
      ),
    );
  }

  List<Widget> _buildVideoTiles(TpoVideoIntroduction video) {
    final List<Map<String, String?>> items = [
      {'title': 'About Yourself', 'url': video.aboutYourself},
      {'title': 'Organize Your Day', 'url': video.organizeYourDay},
      {'title': 'Your Strength', 'url': video.yourStrength},
      {'title': 'Taught Yourself Lately', 'url': video.taughtYourselfLately},
    ];

    return items
        .where((item) => item['url'] != null && item['url']!.isNotEmpty)
        .map(
          (item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/videocam.png', height: 16, width: 16),
                const SizedBox(width: 6),
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _VideoItem(
              url: item['url']!,
              width: 285,
              height: 161,
              playIconAsset: 'assets/play_button.png',
            ),
          ],
        ),
      ),
    )
        .toList();
  }
}

class _VideoItem extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final String playIconAsset;

  const _VideoItem({
    required this.url,
    required this.width,
    required this.height,
    required this.playIconAsset,
  });

  @override
  State<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<_VideoItem> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _hadError = false;
  Uint8List? _thumbnail;


  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: widget.url,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (mounted) {
        setState(() {
          // ✅ Always create a clean Uint8List from returned bytes
          _thumbnail = thumb != null ? Uint8List.fromList(thumb) : null;
        });
      }
    } catch (e) {
      debugPrint("Thumbnail error: $e");
    }
  }

  void _addListener(VideoPlayerController c) {
    c.addListener(() {
      if (mounted) setState(() {}); // ✅ force rebuild when play/pause changes
    });
  }

  Future<void> _ensureInitialized() async {
    if (_controller != null || _initializing) return;
    setState(() {
      _initializing = true;
      _hadError = false;
    });
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      c.setLooping(false);
      _addListener(c); // ✅ add listener
      setState(() {
        _controller = c;
      });
    } catch (_) {
      setState(() {
        _hadError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  void _onTap() async {
    if (_controller == null) {
      await _ensureInitialized();
      if (!mounted || _controller == null) return;
      await VideoManager.play(_controller!);
      return;
    }

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      final v = _controller!.value;
      if (v.position >= (v.duration - const Duration(milliseconds: 300))) {
        await _controller!.seekTo(Duration.zero);
      }
      await VideoManager.play(_controller!);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      VideoManager.dispose(_controller!);
      _controller!.dispose();
    }
    super.dispose();
  }

  Widget _buildOverlay() {
    final showPlay =
        _controller == null || _hadError || !_controller!.value.isPlaying;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_controller == null)
                _thumbnail != null
                    ? Image.memory(
                  _thumbnail!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Container(color: const Color(0xFFCCCCCC).withOpacity(0.3)),

              // if (_controller == null)
              //   Container(color: const Color(0xFFCCCCCC).withOpacity(0.3)),

              if (_controller != null && !_hadError)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),

              if (_hadError)
                const Padding(
                  padding: EdgeInsets.fromLTRB(0,54,0,0),
                  child: Text(
                    'No Video',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_initializing)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

              if (showPlay && !_initializing)
                Image.asset(widget.playIconAsset, height: 40, width: 40),

              // if (_controller != null && !_hadError)
              //   Positioned(
              //     right: 6,
              //     bottom: 6,
              //     child: Container(
              //       padding: const EdgeInsets.all(6),
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.35),
              //         shape: BoxShape.circle,
              //       ),
              //       // child: Icon(
              //       //   _controller!.value.isPlaying
              //       //       ? Icons.pause
              //       //       : Icons.play_arrow,
              //       //   size: 16,
              //       //   color: Colors.white,
              //       // ),
              //     ),
              //   ),
            ],
          ),
        ),

        // 🔹 Seekbar
        if (_controller != null && !_hadError)
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: const EdgeInsets.only(top: 4),
            colors: VideoProgressColors(
              playedColor: Color(0xff005e6a),
              bufferedColor: Colors.grey.shade400,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
      ],
    );
  }

  // Widget _buildOverlay() {
  //   final showPlay =
  //       _controller == null || _hadError || !_controller!.value.isPlaying;
  //
  //   return Column(
  //     children: [
  //       Expanded(
  //         child: Stack(
  //           alignment: Alignment.center,
  //           children: [
  //             if (_controller == null)
  //               Container(color: const Color(0xFFCCCCCC)),
  //
  //             if (_controller != null && !_hadError)
  //               FittedBox(
  //                 fit: BoxFit.cover,
  //                 child: SizedBox(
  //                   width: _controller!.value.size.width,
  //                   height: _controller!.value.size.height,
  //                   child: VideoPlayer(_controller!),
  //                 ),
  //               ),
  //
  //             if (_hadError)
  //               const Padding(
  //                 padding: EdgeInsets.fromLTRB(0,54,0,0),
  //                 child: Text(
  //                   'No video',
  //                   style: TextStyle(color: Colors.black54, fontSize: 12),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ),
  //
  //             if (_initializing)
  //               const SizedBox(
  //                 width: 28,
  //                 height: 28,
  //                 child: CircularProgressIndicator(strokeWidth: 2),
  //               ),
  //
  //             if (showPlay && !_initializing)
  //               Image.asset(widget.playIconAsset, height: 40, width: 40),
  //
  //             if (_controller != null && !_hadError)
  //               Positioned(
  //                 right: 6,
  //                 bottom: 6,
  //                 child: Container(
  //                   padding: const EdgeInsets.all(6),
  //                   decoration: BoxDecoration(
  //                     color: Colors.black.withOpacity(0.35),
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     _controller!.value.isPlaying
  //                         ? Icons.pause
  //                         : Icons.play_arrow,
  //                     size: 16,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //
  //       // 🔹 Seekbar
  //       if (_controller != null && !_hadError)
  //         VideoProgressIndicator(
  //           _controller!,
  //           allowScrubbing: true,
  //           padding: const EdgeInsets.only(top: 4),
  //           colors: VideoProgressColors(
  //             playedColor: Color(0xff005e6a),
  //             bufferedColor: Colors.grey.shade400,
  //             backgroundColor: Colors.grey.shade300,
  //           ),
  //         ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildOverlay(),
      ),
    );
  }
}