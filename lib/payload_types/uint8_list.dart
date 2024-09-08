import 'package:binarize/binarize.dart';

class _Uint8List extends PayloadType<Uint8List> {
  const _Uint8List();

  @override
  int length(Uint8List value) => uint32.length(1) + value.length;

  @override
  Uint8List get(ByteData data, int offset) {
    final length = uint32.get(data, offset);
    final result = Uint8List(length);

    var currentOffset = offset + uint32.length(length);

    for (var i = 0; i < length; i++) {
      result[i] = uint8.get(data, currentOffset);

      currentOffset++;
    }

    return result;
  }

  @override
  void set(Uint8List value, ByteData data, int offset) {
    uint32.set(value.length, data, offset);

    var currentOffset = offset + uint32.length(value.length);

    for (var i = 0; i < value.length; i++) {
      uint8.set(value[i], data, currentOffset);

      currentOffset++;
    }
  }
}

const uint8List = _Uint8List();
