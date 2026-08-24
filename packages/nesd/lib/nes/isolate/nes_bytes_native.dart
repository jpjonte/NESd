import 'dart:isolate';
import 'dart:typed_data';

extension type NesBytes._(TransferableTypedData _data) {
  NesBytes.fromList(List<TypedData> data)
    : _data = TransferableTypedData.fromList(data);

  ByteBuffer materialize() => _data.materialize();
}
