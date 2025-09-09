import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'coordinates_translator.dart';

class KeypointPainter extends CustomPainter {
  KeypointPainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    // --- MODIFIED: Use the new UI accent color for the skeleton ---
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xff00ffc3); // Neon accent color

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xff00ffc3);

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xff00ffc3);
    // -------------------------------------------------------------

    for (final pose in poses) {
      /*
      // This block is commented out to hide the individual keypoint dots
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            1,
            paint);
      });
      */

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
              Offset(
                  translateX(
                    joint1.x,
                    size,
                    absoluteImageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    joint1.y,
                    size,
                    absoluteImageSize,
                    rotation,
                    cameraLensDirection,
                  )),
              Offset(
                  translateX(
                    joint2.x,
                    size,
                    absoluteImageSize,
                    rotation,
                    cameraLensDirection,
                  ),
                  translateY(
                    joint2.y,
                    size,
                    absoluteImageSize,
                    rotation,
                    cameraLensDirection,
                  )),
              paintType);
        }
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
          paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);

      //Draw legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant KeypointPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}

