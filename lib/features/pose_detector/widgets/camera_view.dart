import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraView extends StatefulWidget {
  const CameraView({
    super.key,
    this.customPaint,
    required this.onImage,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.onCameraLensDirectionChanged,
    this.overlayWidget,
  });

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraLensDirection newDirection) onCameraLensDirectionChanged;
  final Widget? overlayWidget;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _isPermissionGranted = false;
  bool _isChangingCameraLens = false;

  final _stopwatch = Stopwatch();
  final _frameTimes = <int>[];
  static const int _profilingSampleCount = 30;
  static const int _targetFrameTimeMs = 33;
  ResolutionPreset? _currentResolution;
  bool _isProfiling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndStart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopLiveFeed();
    } else if (state == AppLifecycleState.resumed) {
      // Longer delay to prevent screenshot buffering issues
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _controller != null && !_controller!.value.isInitialized) {
          _startLiveFeed();
        }
      });
    }
  }

  Future<void> _loadSettingsAndStart() async {
    await _loadResolutionPreference();
    _requestPermission();
  }

  Future<void> _loadResolutionPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedResolution = prefs.getString('resolution');
    if (savedResolution == 'low') {
      _currentResolution = ResolutionPreset.low;
    } else if (savedResolution == 'medium') {
      _currentResolution = ResolutionPreset.medium;
    } else {
      _currentResolution = ResolutionPreset.medium;
      _isProfiling = true;
    }
  }

  void _requestPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
    if (_isPermissionGranted) {
      _startLiveFeed();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    if (_currentResolution == null || _isChangingCameraLens) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isPermissionGranted) {
      return const Center(child: Text('Camera permission not granted'));
    }
    if (_cameras.isEmpty) {
      return const Center(
          child: Text('No cameras found. Run on a physical device.'));
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: CameraPreview(_controller!),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          if (widget.overlayWidget != null) widget.overlayWidget!,
          _buildSwitchLiveCameraLensButton(),
        ],
      ),
    );
  }

  Widget _buildSwitchLiveCameraLensButton() => Positioned(
        top: 40,
        right: 20,
        child: IconButton(
          onPressed: _switchLiveCameraLens,
          icon: Icon(
            Platform.isIOS
                ? Icons.flip_camera_ios_outlined
                : Icons.flip_camera_android_outlined,
            size: 30,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      );

  Future<void> _startLiveFeed() async {
    if (_controller != null) return;

    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } on CameraException catch (e) {
        debugPrint('Error: ${e.code}\n${e.description}');
      }
    }
    if (_cameras.isEmpty) return;

    if (_cameraIndex == -1) {
      _cameraIndex = _cameras.indexWhere(
          (c) => c.lensDirection == widget.initialCameraLensDirection);
      if (_cameraIndex == -1) {
        _cameraIndex = 0;
      }
    }

    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      _currentResolution!,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await _controller!.initialize();
      if (_controller != null) {
        _controller!.startImageStream(_processCameraImage);
      }
    } on CameraException catch (e) {
      debugPrint("Error initializing camera: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopLiveFeed() async {
    if (_controller == null) return;
    try {
      await _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;
    } on CameraException catch (e) {
      debugPrint("Error stopping camera: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isChangingCameraLens || _controller == null) return;

    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            InputImageRotationValue.fromRawValue(
                    _cameras[_cameraIndex].sensorOrientation) ??
                InputImageRotation.rotation0deg,
        format:
            InputImageFormatValue.fromRawValue(image.format.raw) ??
                InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    if (_isProfiling) {
      _stopwatch.reset();
      _stopwatch.start();
      widget.onImage(inputImage);
      _stopwatch.stop();
      _frameTimes.add(_stopwatch.elapsedMilliseconds);

      if (_frameTimes.length >= _profilingSampleCount) {
        final avgTime =
            _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
        _isProfiling = false;
        _frameTimes.clear();

        SharedPreferences.getInstance().then((prefs) {
          if (avgTime > _targetFrameTimeMs) {
            prefs.setString('resolution', 'low');
            if (_currentResolution != ResolutionPreset.low) {
              _currentResolution = ResolutionPreset.low;
              _stopLiveFeed().then((_) => _startLiveFeed());
            }
          } else {
            prefs.setString('resolution', 'medium');
          }
        });
      }
    } else {
      widget.onImage(inputImage);
    }
  }

  Future<void> _switchLiveCameraLens() async {
    if (_cameras.length < 2 || _isChangingCameraLens) return;

    setState(() {
      _isChangingCameraLens = true;
    });

    await _stopLiveFeed();

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startLiveFeed();

    widget.onCameraLensDirectionChanged(_cameras[_cameraIndex].lensDirection);

    setState(() {
      _isChangingCameraLens = false;
    });
  }
}

