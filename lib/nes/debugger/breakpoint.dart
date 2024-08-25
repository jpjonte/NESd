import 'package:freezed_annotation/freezed_annotation.dart';

part 'breakpoint.g.dart';

@JsonSerializable()
class Breakpoint {
  Breakpoint(
    this.address, {
    this.enabled = true,
    this.hidden = false,
    this.disableOnHit = false,
    this.removeOnHit = false,
  });

  int address;
  bool enabled;
  bool hidden;
  bool disableOnHit;
  bool removeOnHit;

  factory Breakpoint.fromJson(Map<String, dynamic> json) =>
      _$BreakpointFromJson(json);

  Map<String, dynamic> toJson() => _$BreakpointToJson(this);
}
