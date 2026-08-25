import 'dart:typed_data';

extension type NesBytes._(Uint8List _bytes) {
  NesBytes.fromList(List<TypedData> data) : _bytes = _concatenate(data);

  ByteBuffer materialize() => _bytes.buffer;
}

Uint8List _concatenate(List<TypedData> data) {
  var length = 0;

  for (final item in data) {
    length += item.lengthInBytes;
  }

  final result = Uint8List(length);
  var offset = 0;

  for (final item in data) {
    result.setAll(
      offset,
      item.buffer.asUint8List(item.offsetInBytes, item.lengthInBytes),
    );

    offset += item.lengthInBytes;
  }

  return result;
}
