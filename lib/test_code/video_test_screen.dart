import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
// These are our super special helpers!
import 'package:sports_app/features/pose_detector/services/pose_detector_service.dart';
import 'package:sports_app/features/pose_detector/painters/keypoint_painter.dart';
import 'package:sports_app/features/pose_detector/utils/angle_calculator.dart';
import 'video_frame_processor.dart'; // Our new magical friend!

// This whole screen is our little secret, only for debug mode!
class VideoTestScreen extends StatefulWidget {
  VideoTestScreen({super.key});

  @override
  State<VideoTestScreen> createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen> {
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  final VideoFrameProcessor _frameProcessor = VideoFrameProcessor();
  StreamSubscription<IsolatePoseData>? _poseSubscription;

  VideoPlayerController? _controller;
  CustomPaint? _customPaint;
  List<String> _framePaths = [];
  Timer? _frameTimer;

  String _currentStage = 'UP';
  int _repCounter = 0;
  String _feedback = "Select a video to begin analysis, master! uwu";
  bool _isProcessingVideo = false;
  int _currentFrameIndex = 0;

  @override
  void initState() {
    super.initState();
    _poseSubscription = _poseDetectorService.stream.listen(_onPoseDataReceived);
  }

  @override
  void dispose() {
    _poseSubscription?.cancel();
    _poseDetectorService.dispose();
    _controller?.dispose();
    _frameTimer?.cancel();
    _frameProcessor.cleanupFrames(_framePaths); // Clean up our toys!
    super.dispose();
  }

  void _onPoseDataReceived(IsolatePoseData data) {
    if (data.poses.isNotEmpty) {
      _updateRepCounter(data.poses.first);
    }
    final painter = KeypointPainter(
        data.poses, data.imageSize, data.imageRotation, CameraLensDirection.back);
    if (mounted) {
      setState(() => _customPaint = CustomPaint(painter: painter));
    }
  }

  void _updateRepCounter(Pose pose) {
     final landmarks = pose.landmarks;
      if (landmarks.containsKey(PoseLandmarkType.leftShoulder) &&
          landmarks.containsKey(PoseLandmarkType.leftElbow) &&
          landmarks.containsKey(PoseLandmarkType.leftWrist)) {
        final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
        final leftElbow = landmarks[PoseLandmarkType.leftElbow]!;
        final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
        final angle = calculateAngle(leftShoulder, leftElbow, leftWrist);

        if (angle > 160) {
          if (_currentStage == 'DOWN') {
            if (mounted) setState(() => _repCounter++);
            _currentStage = 'UP';
          }
        } else if (angle < 90) {
          _currentStage = 'DOWN';
        }
      }
  }

  Future<void> _pickAndAnalyzeVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      final videoFile = File(result.files.single.path!);

      setState(() {
        _isProcessingVideo = true;
        _feedback = "Chopping up the video... this might take a moment, uwu";
        _customPaint = null;
        _repCounter = 0;
      });

      await _controller?.dispose();
      _frameTimer?.cancel();
      await _frameProcessor.cleanupFrames(_framePaths);

      _framePaths = await _frameProcessor.extractFrames(videoFile.path);

      if (_framePaths.isEmpty && mounted) {
        setState(() {
          _isProcessingVideo = false;
          _feedback = "Oh noes! Failed to process video. T_T";
        });
        return;
      }

      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      await _controller!.setLooping(true);

      setState(() {
        _isProcessingVideo = false;
        _feedback = "Ready! Press play to analyze.";
      });
    }
  }

  void _startAnalysis() {
    if (_controller == null || _framePaths.isEmpty) return;

    // We use a standard 30fps timer and sync to the video's position.
    const frameDuration = Duration(milliseconds: 33);
    _currentFrameIndex = 0;

    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(frameDuration, (timer) async {
        if (!(_controller?.value.isPlaying ?? false)) {
            timer.cancel();
            return;
        }

        // Sync the data frame to the video's actual playtime!
        final currentPosition = _controller!.value.position.inMilliseconds;
        final totalDuration = _controller!.value.duration.inMilliseconds;
        if (totalDuration > 0) {
            _currentFrameIndex = ((currentPosition / totalDuration) * _framePaths.length).floor();
        }

        if(_currentFrameIndex >= _framePaths.length) {
            _currentFrameIndex = _framePaths.length - 1; // Stay on the last frame
        }

        final frameFile = File(_framePaths[_currentFrameIndex]);
        final imageBytes = await frameFile.readAsBytes();
        final imageSize = _controller!.value.size;

        final inputImage = InputImage.fromBytes(
            bytes: imageBytes,
            metadata: InputImageMetadata(
                size: imageSize,
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888, // PNGs are yummy BGRA
                bytesPerRow: imageSize.width.toInt() * 4,
            ),
        );

        _poseDetectorService.processImage(inputImage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("// Real Video Test Mode!", style: GoogleFonts.firaCode()),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: _isProcessingVideo
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.yellowAccent),
                      const SizedBox(height: 20),
                      Text(_feedback, style: GoogleFonts.firaCode(color: Colors.white)),
                    ],
                  )
                )
              : _controller != null && _controller!.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),
                          if (_customPaint != null) _customPaint!,
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _feedback,
                      style: GoogleFonts.firaCode(color: Colors.white),
                    ),
                  ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessingVideo ? null : _pickAndAnalyzeVideo,
                icon: const Icon(Icons.video_library),
                label: const Text("Select Video"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellowAccent,
                  disabledBackgroundColor: Colors.grey[700],
                ),
              ),
              if (_controller != null)
                IconButton(
                  icon: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    if (_controller == null) return;
                    setState(() {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                        _frameTimer?.cancel();
                      } else {
                        // Reset for a fresh test run!
                        _repCounter = 0;
                        _currentFrameIndex = 0;
                        _controller!.seekTo(Duration.zero);
                        _controller!.play();
                        _startAnalysis();
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "DETECTED REPS: $_repCounter",
            style: GoogleFonts.firaCode(
              color: Colors.yellowAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

