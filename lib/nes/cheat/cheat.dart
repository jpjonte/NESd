// Game Genie and Pro Action Replay cheat code types
enum CheatType {
  // Game Genie codes (6 or 8 character codes)
  gameGenie,
}

// Represents a single cheat code
class Cheat {
  Cheat({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.value,
    this.compareValue,
    this.enabled = true,
  });

  final String id;
  final String name;
  final CheatType type;
  final int address;
  final int value;
  final int? compareValue;
  bool enabled;

  Cheat copyWith({
    String? id,
    String? name,
    CheatType? type,
    int? address,
    int? value,
    int? compareValue,
    bool? enabled,
  }) => Cheat(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    address: address ?? this.address,
    value: value ?? this.value,
    compareValue: compareValue ?? this.compareValue,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'address': address,
    'value': value,
    if (compareValue != null) 'compareValue': compareValue,
    'enabled': enabled,
  };

  factory Cheat.fromJson(Map<String, dynamic> json) => Cheat(
    id: json['id'] as String,
    name: json['name'] as String,
    type: CheatType.values.firstWhere((e) => e.name == json['type']),
    address: json['address'] as int,
    value: json['value'] as int,
    compareValue: json['compareValue'] as int?,
    enabled: json['enabled'] as bool? ?? true,
  );

  @override
  String toString() {
    final addressHex = address.toRadixString(16).toUpperCase();
    final valueHex = value.toRadixString(16).toUpperCase();

    return 'Cheat($name, $addressHex: $valueHex, enabled: $enabled)';
  }
}
