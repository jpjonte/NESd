import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'overscan.freezed.dart';
part 'overscan.g.dart';

const maxOverscan = 16;

@freezed
sealed class Overscan with _$Overscan {
  const factory Overscan({
    @Default(8) int top,
    @Default(8) int bottom,
    @Default(0) int left,
    @Default(0) int right,
  }) = _Overscan;

  const Overscan._();

  factory Overscan.fromJson(Map<String, dynamic> json) =>
      _$OverscanFromJson(json);

  static const none = Overscan(top: 0, bottom: 0);

  int visibleWidth(int sourceWidth) => sourceWidth - left - right;

  int visibleHeight(int sourceHeight) => sourceHeight - top - bottom;

  Rect visibleRect(int sourceWidth, int sourceHeight) => Rect.fromLTWH(
    left.toDouble(),
    top.toDouble(),
    visibleWidth(sourceWidth).toDouble(),
    visibleHeight(sourceHeight).toDouble(),
  );
}
