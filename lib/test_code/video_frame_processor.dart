import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

// This wittle cwass uses a big stwong tool cawwed FFmpeg to get all the
// yummy fwames fwom a video fiwe, uwu.
// It will onwy be used when you're pwaying in debug mode!
class VideoFrameProcessor {
  // This function takes a video and chops it up into wittle pictures,
  // saving them in a secwet tempowawy pwace.
  // It gives back a wist of where all the pictures are hiding!
  Future<List<String>> extractFrames(String videoPath) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String outputDir = '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(outputDir).create();

    // This is the magic speww for FFmpeg! ☆
    // It says: "pwease take this video (-i) and make each fwame a wittle png picture fow me!"
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

  // This cleans up all the wittle picture files when we're done pwaying,
  // so we don't make a mess!
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

