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
import 'package:pushup_app/features/pose_detector/painters/keypoint_painter.dart';
import 'package:pushup_app/features/pose_detector/utils/angle_calculator.dart';

// This whole screen is our wittle secret, onwy for debug mode!
class VideoTestScreen extends StatefulWidget {
  const VideoTestScreen({super.key});

  @override
  State<VideoTestScreen> createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends State<VideoTestScreen> {
  VideoPlayerController? _controller;
  CustomPaint? _customPaint;
  Timer? _frameTimer;
  List<dynamic> _allFramesData = [];
  int _currentFrameIndex = 0;

  String _currentStage = 'UP';
  int _repCounter = 0;
  String _feedback = "Select a video and its pose data to begin, master! uwu";

  @override
  void dispose() {
    _frameTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<bool> _loadPoseData() async {
    try {
      final String response =
          await rootBundle.loadString('test_assets/real_pushup_data.json');
      _allFramesData = await json.decode(response);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedback = "Oh noes! I couldn't find real_pushup_data.json T_T";
        });
      }
      return false;
    }
  }

  void _startFrameProcessing() {
    if (_controller == null) return;
    // THE FIX: The video_player doesn't give us frameRate, so we'll use a standard
    // 30fps timer. The sync logic below is more important!
    const frameDuration = Duration(milliseconds: 33);

    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(frameDuration, (timer) {
      if (!(_controller?.value.isPlaying ?? false)) {
        timer.cancel();
        return;
      }
      
      // THE REAL FIX: Sync the data frame to the video's actual playtime!
      // This keeps the skeleton and video pewfectly together! (* ^ ω ^)
      final currentPosition = _controller!.value.position.inMilliseconds;
      final totalDuration = _controller!.value.duration.inMilliseconds;
      if (totalDuration > 0) {
        _currentFrameIndex =
            ((currentPosition / totalDuration) * _allFramesData.length)
                .floor();
      }

      _processCurrentFrame();
    });
  }

  void _processCurrentFrame() {
    if (_allFramesData.isEmpty || _currentFrameIndex >= _allFramesData.length) {
      return;
    }

    final frameData = _allFramesData[_currentFrameIndex];
    final landmarksData = frameData['landmarks'] as List<dynamic>;

    final List<Pose> poses = [];
    if (landmarksData.isNotEmpty) {
      final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
      for (var lm in landmarksData) {
        final type = PoseLandmarkType.values[lm['type']];
        landmarks[type] = PoseLandmark(
          type: type,
          x: (lm['x'] as num).toDouble() * _controller!.value.size.width,
          y: (lm['y'] as num).toDouble() * _controller!.value.size.height,
          z: (lm['z'] as num).toDouble(),
          likelihood: (lm['likelihood'] as num).toDouble(),
        );
      }
      poses.add(Pose(landmarks: landmarks));
    }

    _onPoseDataReceived(poses);

    final painter = KeypointPainter(poses, _controller!.value.size,
        InputImageRotation.rotation0deg, CameraLensDirection.back);

    if (mounted) {
      setState(() {
        _customPaint = CustomPaint(painter: painter);
      });
    }
  }

  void _onPoseDataReceived(List<Pose> poses) {
    if (poses.isNotEmpty) {
      final landmarks = poses.first.landmarks;

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
  }

  Future<void> _pickAndPlayVideo() async {
    final hasPoseData = await _loadPoseData();
    if (!hasPoseData) return;

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      final file = File(result.files.single.path!);
      await _controller?.dispose();
      _frameTimer?.cancel();
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      await _controller!.setLooping(true);

      setState(() {
        _feedback = "Video loaded! Press play, master!";
        _repCounter = 0;
        _currentFrameIndex = 0;
      });
    }
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
            child: _controller != null && _controller!.value.isInitialized
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
                onPressed: _pickAndPlayVideo,
                icon: const Icon(Icons.video_library),
                label: const Text("Select Video"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellowAccent,
                ),
              ),
              if (_controller != null)
                IconButton(
                  icon: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
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
                        // Reset for a fresh test!
                        _repCounter = 0;
                        _currentFrameIndex = 0;
                        _controller!.seekTo(Duration.zero);
                        _controller!.play();
                        _startFrameProcessing();
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

