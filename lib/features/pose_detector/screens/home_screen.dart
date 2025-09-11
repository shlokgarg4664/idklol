import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // <-- Our little secret helper for debug mode!
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sports_app/features/pose_detector/services/pose_detector_service.dart';
import 'package:sports_app/features/pose_detector/widgets/camera_view.dart';
import 'package:sports_app/features/pose_detector/painters/keypoint_painter.dart';
import 'package:sports_app/features/pose_detector/utils/angle_calculator.dart';
import 'package:sports_app/features/pose_detector/utils/distance_calculator.dart';
import 'package:sports_app/test_code/video_test_screen.dart'; // It knows where to find our new friend!

enum ExerciseState { initializing, notReady, inProgress }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  StreamSubscription<IsolatePoseData>? _poseSubscription;

  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;
  bool _isServiceReady = false;

  Pose? _lockedOnPose;
  int _lostLockCounter = 0;
  static const int _lostLockThreshold = 30;

  String _currentStage = 'UP';
  int _repCounter = 0;
  ExerciseState _exerciseState = ExerciseState.initializing;
  int _inPositionCounter = 0;
  static const int _inPositionThreshold = 50;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() async {
    await _poseDetectorService.ready;
    _poseSubscription = _poseDetectorService.stream.listen(_onPoseDataReceived);
    if (mounted) {
      setState(() {
        _isServiceReady = true;
        _exerciseState = ExerciseState.notReady;
      });
    }
  }

  @override
  void dispose() {
    _poseSubscription?.cancel();
    _poseDetectorService.dispose();
    super.dispose();
  }

  void _onPoseDataReceived(IsolatePoseData data) {
    final poses = data.poses;

    if (poses.isNotEmpty) {
      _lostLockCounter = 0;
      if (_lockedOnPose == null) {
        _lockedOnPose = poses.first;
      } else {
        Pose closestPose = poses.first;
        double minDistance = double.infinity;
        final lockedOnNose = _lockedOnPose!.landmarks[PoseLandmarkType.nose]!;
        for (final pose in poses) {
          final currentNose = pose.landmarks[PoseLandmarkType.nose]!;
          final distance = calculateDistance(lockedOnNose, currentNose);
          if (distance < minDistance) {
            minDistance = distance;
            closestPose = pose;
          }
        }
        _lockedOnPose = closestPose;
      }

      final landmarks = _lockedOnPose!.landmarks;
      if (landmarks.isNotEmpty) {
        final leftShoulder = landmarks[PoseLandmarkType.leftShoulder]!;
        final leftElbow = landmarks[PoseLandmarkType.leftElbow]!;
        final leftWrist = landmarks[PoseLandmarkType.leftWrist]!;
        final rightShoulder = landmarks[PoseLandmarkType.rightShoulder]!;
        final rightElbow = landmarks[PoseLandmarkType.rightElbow]!;
        final rightWrist = landmarks[PoseLandmarkType.rightWrist]!;

        final double leftAngle =
            calculateAngle(leftShoulder, leftElbow, leftWrist);
        final double rightAngle =
            calculateAngle(rightShoulder, rightElbow, rightWrist);

        final isUp = leftAngle > 160 || rightAngle > 160;
        final isDown = leftAngle < 90 || rightAngle < 90;

        if (_exerciseState == ExerciseState.inProgress) {
          if (isUp) {
            if (_currentStage == 'DOWN') {
              setState(() {
                _repCounter++;
                _currentStage = 'UP';
              });
            }
          } else if (isDown) {
            _currentStage = 'DOWN';
          }
        } else if (_exerciseState == ExerciseState.notReady) {
          if (isUp) {
            _inPositionCounter++;
            if (_inPositionCounter >= _inPositionThreshold) {
              setState(() {
                _exerciseState = ExerciseState.inProgress;
              });
            }
          } else {
            _inPositionCounter = 0;
          }
        }
      }
    } else {
      _lostLockCounter++;
      if (_lostLockCounter > _lostLockThreshold) {
        setState(() {
          _exerciseState = ExerciseState.notReady;
          _lockedOnPose = null;
          _repCounter = 0;
          _currentStage = 'UP';
          _inPositionCounter = 0;
        });
      }
    }

    final painter = KeypointPainter(
      _lockedOnPose != null ? [_lockedOnPose!] : [],
      data.imageSize,
      data.imageRotation,
      _cameraLensDirection,
    );
    
    if (mounted) {
      setState(() {
        _customPaint = CustomPaint(painter: painter);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isServiceReady
          ? CameraView(
              customPaint: _customPaint,
              onImage: (inputImage) {
                _poseDetectorService.processImage(inputImage);
              },
              initialCameraLensDirection: _cameraLensDirection,
              onCameraLensDirectionChanged: (value) => setState(() {
                _cameraLensDirection = value;
                _lockedOnPose = null;
                _exerciseState = ExerciseState.notReady;
              }),
              overlayWidget: _buildOverlay(),
            )
          : _buildInitializingUI(),
    );
  }

  Widget _buildInitializingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.yellowAccent),
          const SizedBox(height: 20),
          Text(
            "Initializing AI...",
            style: GoogleFonts.firaCode(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getInstructionText(),
                style: GoogleFonts.firaCode(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        // This is our wittle secret button! Only for you, master!
        if (kDebugMode)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: Colors.yellow,
                ),
                child: const Text('// Open Video Tester'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VideoTestScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  String _getInstructionText() {
    switch (_exerciseState) {
      case ExerciseState.initializing:
        return "Please wait...";
      case ExerciseState.notReady:
        return "Get into plank position to start";
      case ExerciseState.inProgress:
        return "REPS: $_repCounter";
    }
  }
}

