import 'package:json_annotation/json_annotation.dart';

part 'cheat.g.dart';

// Game Genie and Pro Action Replay cheat code types
enum CheatType {
  // Game Genie codes (6 or 8 character codes)
  // Format: [APZLGITYEOXUKSVN]{6,8}
  // Example: SLXPLOVS (Infinite Lives in SMB)
  gameGenie,
}

// Represents a single cheat code
@JsonSerializable()
class Cheat {
  Cheat({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.value,
    required this.code,
    this.compareValue,
    this.enabled = true,
  });

  final String id;
  final String name;
  final CheatType type;
  final int address;
  final int value;
  final String code;
  final int? compareValue;
  final bool enabled;

  Cheat copyWith({
    String? id,
    String? name,
    CheatType? type,
    int? address,
    int? value,
    String? code,
    int? compareValue,
    bool? enabled,
  }) => Cheat(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    address: address ?? this.address,
    value: value ?? this.value,
    code: code ?? this.code,
    compareValue: compareValue ?? this.compareValue,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => _$CheatToJson(this);

  factory Cheat.fromJson(Map<String, dynamic> json) => _$CheatFromJson(json);

  @override
  String toString() {
    final addressHex = address.toRadixString(16).toUpperCase();
    final valueHex = value.toRadixString(16).toUpperCase();

    return 'Cheat($name, $addressHex: $valueHex, enabled: $enabled)';
  }
}
