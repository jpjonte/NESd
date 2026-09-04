import 'package:flutter/foundation.dart';
import 'package:nesd/nes/rewind/rewind_thumbnails.dart';

@immutable
class RewindTimeline {
  const RewindTimeline({
    required this.oldestSequence,
    required this.newestSequence,
    required this.captureInterval,
    required this.frameRate,
    required this.thumbnails,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
  });

  final int oldestSequence;
  final int newestSequence;

  final int captureInterval;
  final int frameRate;

  final List<RewindThumbnail> thumbnails;

  final int thumbnailWidth;
  final int thumbnailHeight;
}
