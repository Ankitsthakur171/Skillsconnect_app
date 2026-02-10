import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CameraRecordScreen extends StatefulWidget {
  final String question;
  const CameraRecordScreen({super.key, required this.question});

  @override
  State<CameraRecordScreen> createState() => _CameraRecordScreenState();
}

class _CameraRecordScreenState extends State<CameraRecordScreen> {
  CameraController? _controller;
  VideoPlayerController? _videoController;

  bool _recording = false;
  bool _isPreparingPreview = false;

  File? _recordedFile;
  Timer? _recordTimer;

  int _elapsedSeconds = 0;
  static const int _maxSeconds = 60;

  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    final frontIndex =
        _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);

    _cameraIndex = frontIndex == -1 ? 0 : frontIndex;
    await _initializeCamera(_cameras[_cameraIndex]);
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.medium, // 720p
      enableAudio: true,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _flipCamera() async {
    if (_recording || _recordedFile != null) return;
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initializeCamera(_cameras[_cameraIndex]);
  }

  Future<void> _startRecord() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    await _controller!.startVideoRecording();
    _elapsedSeconds = 0;
    _recording = true;

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _elapsedSeconds++;
      if (_elapsedSeconds >= _maxSeconds) {
        await _stopRecord();
      } else if (mounted) {
        setState(() {});
      }
    });

    Future.delayed(const Duration(seconds: _maxSeconds + 1), () async {
      if (_recording) await _stopRecord();
    });

    if (mounted) setState(() {});
  }

  Future<void> _stopRecord() async {
    if (!_recording || _controller == null) return;

    _recordTimer?.cancel();
    _recording = false;
    _isPreparingPreview = true;

    XFile file;
    try {
      file = await _controller!.stopVideoRecording();
    } catch (_) {
      _isPreparingPreview = false;
      return;
    }

    final recorded = File(file.path);

    // Prepare preview FIRST
    await _videoController?.dispose();
    _videoController = VideoPlayerController.file(recorded);
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();

    _recordedFile = recorded;
    _isPreparingPreview = false;

    // Dispose camera LAST
    await _controller?.dispose();
    _controller = null;

    if (mounted) setState(() {});
  }

  Future<void> _toggleRecord() async {
    _recording ? await _stopRecord() : await _startRecord();
  }

  void _retake() {
    _videoController?.dispose();
    _videoController = null;
    _recordedFile = null;
    _elapsedSeconds = 0;
    _initializeCamera(_cameras[_cameraIndex]);
    if (mounted) setState(() {});
  }

  void _confirm() {
    if (_recordedFile == null) return;
    Navigator.pop(context, _recordedFile);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // 🔥 FULL-SCREEN CAMERA (NO BLACK BARS)
  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final previewRatio = _controller!.value.aspectRatio;

    return Center(
      child: OverflowBox(
        maxHeight: size.width * previewRatio,
        maxWidth: size.height / previewRatio,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * previewRatio,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

Widget _buildVideoPreview() {
  final size = MediaQuery.of(context).size;
  final videoRatio = _videoController!.value.aspectRatio;

  return SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.width / videoRatio,
        child: VideoPlayer(_videoController!),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    if ((_controller == null || !_controller!.value.isInitialized) &&
        _recordedFile == null &&
        !_isPreparingPreview) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null && !_isPreparingPreview)
            _buildCameraPreview()
       else if (_videoController != null &&
    _videoController!.value.isInitialized)
  _buildVideoPreview(),


          // TIMER
          if (_recordedFile == null)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

          // FLIP CAMERA
          if (_recordedFile == null)
            Positioned(
              top: 48,
              right: 16,
              child: IconButton(
                onPressed: _flipCamera,
                icon: const Icon(Icons.cameraswitch,
                    color: Colors.white, size: 28),
              ),
            ),

          // CONTROLS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _recordedFile == null
                  ? FloatingActionButton(
                      backgroundColor:
                          _recording ? Colors.red : Colors.white,
                      elevation: 6,
                      onPressed: _toggleRecord,
                      child: Icon(
                        _recording
                            ? Icons.stop
                            : Icons.fiber_manual_record,
                        size: 34,
                        color: _recording ? Colors.white : Colors.red,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'retake',
                          backgroundColor: Colors.white,
                          onPressed: _retake,
                          child:
                              const Icon(Icons.close, color: Colors.red),
                        ),
                        const SizedBox(width: 28),
                        FloatingActionButton(
                          heroTag: 'confirm',
                          backgroundColor: Colors.green,
                          onPressed: _confirm,
                          child:
                              const Icon(Icons.check, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}
