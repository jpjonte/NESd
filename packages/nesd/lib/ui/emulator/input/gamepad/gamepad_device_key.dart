import 'package:flutter/foundation.dart';

const unknownGamepadName = 'Unknown';

@immutable
class GamepadDeviceKey {
  const GamepadDeviceKey({required this.name, this.vendorId, this.productId});

  static GamepadDeviceKey? tryFromJson(Object? json) {
    if (json is! Map || json['name'] is! String) {
      return null;
    }

    return GamepadDeviceKey(
      name: json['name']! as String,
      vendorId: _idFromJson(json['vendorId']),
      productId: _idFromJson(json['productId']),
    );
  }

  static int? _idFromJson(Object? value) => value is num ? value.toInt() : null;

  final String name;
  final int? vendorId;
  final int? productId;

  bool get _hasIds => vendorId != null && productId != null;

  bool get isPlaceholder => name == unknownGamepadName;

  bool improvesOn(GamepadDeviceKey other) =>
      !isPlaceholder && ((_hasIds && !other._hasIds) || other.isPlaceholder);

  bool matches(GamepadDeviceKey other) {
    if (_hasIds && other._hasIds) {
      return vendorId == other.vendorId && productId == other.productId;
    }

    return name == other.name;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (vendorId != null) 'vendorId': vendorId,
    if (productId != null) 'productId': productId,
  };

  @override
  bool operator ==(Object other) =>
      other is GamepadDeviceKey &&
      name == other.name &&
      vendorId == other.vendorId &&
      productId == other.productId;

  @override
  int get hashCode => Object.hash(name, vendorId, productId);

  @override
  String toString() =>
      'GamepadDeviceKey($name, vendorId: $vendorId, productId: $productId)';
}
