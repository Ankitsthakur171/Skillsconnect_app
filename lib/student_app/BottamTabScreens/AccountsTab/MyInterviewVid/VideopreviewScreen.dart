import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocpage/bloc_logic.dart';
import '../../../blocpage/bloc_state.dart';
import 'package:chewie/chewie.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoUrl;
  final String question;

  const VideoPreviewScreen({
    required this.videoUrl,
    required this.question,
    super.key,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    if (widget.videoUrl.startsWith("http")) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    } else {
      _videoController = VideoPlayerController.file(File(widget.videoUrl));
    }

    _videoController.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: false,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) {
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.question)),
        body: Center(
          child: _chewieController != null &&
              _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
