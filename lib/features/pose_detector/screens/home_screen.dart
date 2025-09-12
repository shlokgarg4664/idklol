import 'dart:async';
import 'package:camera/camera.dart';
// Removed foundation import as dev-only UI is no longer present.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:sports_app/features/pose_detector/services/pose_detector_service.dart';
import 'package:sports_app/features/pose_detector/widgets/camera_view.dart';
import 'package:sports_app/features/pose_detector/painters/keypoint_painter.dart';
import 'package:sports_app/features/pose_detector/utils/angle_calculator.dart';
import 'package:sports_app/features/pose_detector/utils/distance_calculator.dart';
import 'package:sports_app/core/user_service.dart';
// Dev-only video tester removed from runtime build.

enum ExerciseState { initializing, notReady, inProgress }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  final UserService _userService = UserService();
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
  bool _showDemoOverlay = false;
  
  // Workout tracking
  DateTime? _workoutStartTime;
  int _totalReps = 0;

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
                _totalReps++;
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
                _workoutStartTime = DateTime.now();
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
        // Save workout if we were in progress
        if (_exerciseState == ExerciseState.inProgress && _totalReps > 0) {
          _saveWorkout();
        }
        
        setState(() {
          _exerciseState = ExerciseState.notReady;
          _lockedOnPose = null;
          _repCounter = 0;
          _currentStage = 'UP';
          _inPositionCounter = 0;
          _workoutStartTime = null;
        });
      }
    }

    // Use demo pose if no real pose detected and demo overlay is enabled
    final List<Pose> posesToShow = _lockedOnPose != null 
        ? [_lockedOnPose!] 
        : (_showDemoOverlay ? [_createDemoPose(data.imageSize)] : <Pose>[]);
    
    final painter = KeypointPainter(
      posesToShow,
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
                color: Colors.black.withValues(alpha: 0.6),
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
        // Demo overlay toggle
        Positioned(
          top: 50,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                _showDemoOverlay ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showDemoOverlay = !_showDemoOverlay;
                });
              },
            ),
          ),
        ),
        
        // Finish workout button (only show during workout)
        if (_exerciseState == ExerciseState.inProgress)
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () async {
                  await _saveWorkout();
                  setState(() {
                    _exerciseState = ExerciseState.notReady;
                    _repCounter = 0;
                    _currentStage = 'UP';
                    _inPositionCounter = 0;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Workout saved! Total reps: $_totalReps'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _saveWorkout() async {
    if (_workoutStartTime == null || _totalReps == 0) return;
    
    final duration = DateTime.now().difference(_workoutStartTime!).inSeconds;
    final calories = _totalReps * 0.5; // Rough estimate: 0.5 calories per pushup
    
    final workoutData = {
      'type': 'pushups',
      'count': _totalReps,
      'duration': duration,
      'calories': calories,
      'notes': 'AI-detected pushup workout',
    };
    
    await _userService.createWorkout(workoutData);
    
    // Reset counters
    _totalReps = 0;
    _workoutStartTime = null;
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

  Pose _createDemoPose(Size imageSize) {
    // Create a simple demo pose for testing when no person is detected
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;
    
    // Create mock landmarks for a basic pose
    final landmarks = <PoseLandmarkType, PoseLandmark>{};
    
    // Head
    landmarks[PoseLandmarkType.nose] = PoseLandmark(
      type: PoseLandmarkType.nose,
      x: centerX,
      y: centerY - 100,
      z: 0.0,
      likelihood: 0.9,
    );
    
    // Shoulders
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: centerX - 50,
      y: centerY - 50,
      z: 0.0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: centerX + 50,
      y: centerY - 50,
      z: 0.0,
      likelihood: 0.9,
    );
    
    // Elbows
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: centerX - 80,
      y: centerY,
      z: 0.0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: centerX + 80,
      y: centerY,
      z: 0.0,
      likelihood: 0.9,
    );
    
    // Wrists
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: centerX - 100,
      y: centerY + 30,
      z: 0.0,
      likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: centerX + 100,
      y: centerY + 30,
      z: 0.0,
      likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
}

