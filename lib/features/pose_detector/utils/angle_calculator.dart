import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

double calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
  // Calculate the angle using the dot product formula
  final radians =
      atan2(last.y - mid.y, last.x - mid.x) -
      atan2(first.y - mid.y, first.x - mid.x);
  
  double degrees = radians * 180.0 / pi;
  
  // Ensure the angle is positive
  if (degrees < 0) {
    degrees += 360.0;
  }
  
  return degrees > 180 ? 360 - degrees : degrees;
}

