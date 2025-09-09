import 'dart:async'; // THE FIX: Corrected the import from 'dart-async'
import 'dart:isolate';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// A custom class to hold all the data coming back from the isolate.
class IsolatePoseData {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation imageRotation;

  IsolatePoseData(this.poses, this.imageSize, this.imageRotation);
}

// This service class manages the background AI processing thread (Isolate).
class PoseDetectorService {
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;

  final StreamController<IsolatePoseData> _streamController =
      StreamController.broadcast();
  Stream<IsolatePoseData> get stream => _streamController.stream;

  // THE FIX: Use a Completer to signal when the isolate is ready.
  final Completer<void> _isolateReadyCompleter = Completer<void>();
  Future<void> get ready => _isolateReadyCompleter.future;

  PoseDetectorService() {
    _initIsolate();
  }

  void _initIsolate() async {
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _receivePort.sendPort,
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        // Signal that the service is now ready to receive images.
        if (!_isolateReadyCompleter.isCompleted) {
          _isolateReadyCompleter.complete();
        }
      } else if (message is Map<String, dynamic>) {
        // When data comes back, deserialize it into our custom class
        final posesData = message['poses'] as List<dynamic>;
        final poses = posesData
            .map((e) => _poseFromMap(e as Map<String, dynamic>))
            .toList();

        final imageSize = Size(message['imageSize']['width'],
            message['imageSize']['height']);
        final imageRotation = InputImageRotationValue.fromRawValue(
                message['imageRotation'] as int) ??
            InputImageRotation.rotation0deg;

        // Add the result to the stream for the main screen to listen to
        _streamController.add(IsolatePoseData(poses, imageSize, imageRotation));
      }
    });
  }

  // Helper function to deserialize a Pose from a map
  Pose _poseFromMap(Map<String, dynamic> map) {
    return Pose(
      landmarks: (map['landmarks'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          PoseLandmarkType.values[int.parse(key)],
          _poseLandmarkFromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  // Helper function to deserialize a PoseLandmark from a map
  PoseLandmark _poseLandmarkFromMap(Map<String, dynamic> map) {
    return PoseLandmark(
      type: PoseLandmarkType.values[map['type']],
      x: map['x'],
      y: map['y'],
      z: map['z'],
      likelihood: map['likelihood'],
    );
  }

  // This is the function that runs on the separate background thread.
  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    final poseDetector = PoseDetector(options: PoseDetectorOptions());

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final inputImage = InputImage.fromBytes(
          bytes: message['bytes'],
          metadata: _inputImageMetadataFromMap(message['metadata']),
        );
        final poses = await poseDetector.processImage(inputImage);

        // Send back the results, making sure to serialize them into a simple map
        sendPort.send({
          'poses': poses.map((pose) => pose.toMap()).toList(),
          'imageSize': {
            'width': inputImage.metadata!.size.width,
            'height': inputImage.metadata!.size.height
          },
          'imageRotation': inputImage.metadata!.rotation.rawValue
        });
      }
    });
  }

  // This is called from the main screen to start the AI processing.
  void processImage(InputImage inputImage) {
    if (_sendPort != null) {
      _sendPort!.send({
        'bytes': inputImage.bytes,
        'metadata': inputImage.metadata?.toMap(),
      });
    }
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _streamController.close();
  }
}

// Top-level function for metadata deserialization inside the isolate
InputImageMetadata _inputImageMetadataFromMap(Map<String, dynamic> map) {
  return InputImageMetadata(
    size:
        Size(map['size']['width'].toDouble(), map['size']['height'].toDouble()),
    rotation: InputImageRotationValue.fromRawValue(map['rotation']) ??
        InputImageRotation.rotation0deg,
    format: InputImageFormatValue.fromRawValue(map['format']) ??
        InputImageFormat.nv21,
    bytesPerRow: map['bytesPerRow'],
  );
}

// Helper extensions to serialize data for the isolate.
extension on InputImageMetadata {
  Map<String, dynamic> toMap() {
    return {
      'size': {'width': size.width, 'height': size.height},
      'rotation': rotation.rawValue,
      'format': format.rawValue,
      'bytesPerRow': bytesPerRow,
    };
  }
}

extension on Pose {
  Map<String, dynamic> toMap() {
    return {
      'landmarks': landmarks
          .map((key, value) => MapEntry(key.index.toString(), value.toMap())),
    };
  }
}

extension on PoseLandmark {
  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'x': x,
      'y': y,
      'z': z,
      'likelihood': likelihood,
    };
  }
}

