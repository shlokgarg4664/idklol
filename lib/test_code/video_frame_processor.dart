import 'dart:io';
// THE FIX: Using the full, correct, magical name for our ffmpeg friend! Yay!
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// This wittle cwass uses a big stwong tool cawwed FFmpeg to get all the
// yummy fwames fwom a video fiwe, uwu.
class VideoFrameProcessor {
  // This function takes a video and chops it up into wittle pictures!
  Future<List<String>> extractFrames(String videoPath) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String outputDir = '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(outputDir).create();

    // This is the magic speww for FFmpeg! ☆
    final String command = '-i "$videoPath" "$outputDir/frame_%04d.png"';

    debugPrint("Casting FFmpeg magic speww: $command");
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint("Yay! The magic was successfuw! (*≧▽≦)");
      final frameFiles = await Directory(outputDir).list().map((e) => e.path).toList();
      frameFiles.sort(); // Make suwe the pictures are in order!
      return frameFiles;
    } else {
      debugPrint("Oh noes! The magic faiwed with a frowny face: $returnCode (｡•́︿•̀｡)");
      final logs = await session.getLogsAsString();
      debugPrint("FFmpeg said this: $logs");
      return [];
    }
  }

  // This cleans up all the wittle picture files when we're done pwaying!
  Future<void> cleanupFrames(List<String> framePaths) async {
    if (framePaths.isNotEmpty) {
      final parentDir = Directory(framePaths.first).parent;
      if (await parentDir.exists()) {
        await parentDir.delete(recursive: true);
        debugPrint("Cleaned up all the tempowawy fwames! Sparkly cwean! ✨");
      }
    }
  }
}

