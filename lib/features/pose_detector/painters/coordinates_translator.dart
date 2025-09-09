import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      // In landscape mode, width and height are swapped relative to the canvas
      return canvasSize.width -
          x * canvasSize.width / imageSize.height;
    default:
      // For front camera, we need to mirror the X-axis
      if (cameraLensDirection == CameraLensDirection.front) {
        return canvasSize.width -
            x * canvasSize.width / imageSize.width;
      } else {
        return x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      // In landscape mode, width and height are swapped relative to the canvas
      return y * canvasSize.height / imageSize.width;
    default:
      return y * canvasSize.height / imageSize.height;
  }
}

