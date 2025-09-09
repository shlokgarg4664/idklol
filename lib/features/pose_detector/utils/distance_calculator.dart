import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

double calculateDistance(PoseLandmark p1, PoseLandmark p2) {
  final dx = p1.x - p2.x;
  final dy = p1.y - p2.y;
  return sqrt(dx * dx + dy * dy);
}

