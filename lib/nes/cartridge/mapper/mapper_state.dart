import 'package:binarize/binarize.dart';
import 'package:nes/exception/unsupported_mapper.dart';
import 'package:nes/nes/cartridge/mapper/mmc1_state.dart';

class MapperState {
  const MapperState({required this.id});

  const MapperState.dummy() : id = 0;

  final int id;
}

class _MapperState extends PayloadType<MapperState> {
  const _MapperState();

  @override
  int length(MapperState value) => _getLength(value.id);

  @override
  MapperState get(ByteData data, int offset) {
    final id = data.getUint8(offset);

    return switch (id) {
      0 => _getNrom(data, offset + 1),
      1 => _getMMC1(data, offset + 1),
      _ => throw UnsupportedMapper(id),
    };
  }

  @override
  void set(MapperState value, ByteData data, int offset) {
    data.setUint8(offset, value.id);

    switch (value.id) {
      case 0:
        _setNrom(value, data, offset + 1);
      case 1:
        _setMMC1(value, data, offset + 1);
      default:
        throw UnsupportedMapper(value.id);
    }
  }

  MapperState _getNrom(ByteData data, int offset) {
    return const MapperState(id: 0);
  }

  void _setNrom(MapperState value, ByteData data, int offset) {
    // No-op
  }

  MMC1State _getMMC1(ByteData data, int offset) {
    return MMC1State(
      shift: data.getUint8(offset),
      control: data.getUint8(offset + 1),
      chrBank0: data.getUint8(offset + 2),
      chrBank1: data.getUint8(offset + 3),
      prgBank: data.getUint8(offset + 4),
    );
  }

  void _setMMC1(MapperState value, ByteData data, int offset) {
    final castValue = value as MMC1State;

    data
      ..setUint8(offset, castValue.shift)
      ..setUint8(offset + 1, castValue.control)
      ..setUint8(offset + 2, castValue.chrBank0)
      ..setUint8(offset + 3, castValue.chrBank1)
      ..setUint8(offset + 4, castValue.prgBank);
  }

  int _getLength(int id) {
    return switch (id) {
      0 => 1,
      1 => 6,
      _ => throw UnsupportedMapper(id),
    };
  }
}

const mapperStateType = _MapperState();
