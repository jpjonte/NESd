import 'dart:typed_data';

import 'package:nesd/extension/bit_extension.dart';
import 'package:nesd/nes/cartridge/mapper/chip/eeprom_24c02_state.dart';

// DO NOT REORDER: The order is part of the serialization format
enum Eeprom24C02Mode { idle, control, address, read, write }

class Eeprom24C02 {
  int _previousScl = 0;
  int _previousSda = 0;

  int _address = 0;
  int _bit = 0;
  int _control = 0;
  int _shift = 0;

  bool _flush = false;

  Eeprom24C02Mode _mode = .idle;

  final _buffer = Uint8List(16);

  final data = Uint8List(256);

  int output = 1;

  Eeprom24C02State get state => Eeprom24C02State(
    previousScl: _previousScl,
    previousSda: _previousSda,
    address: _address,
    bit: _bit,
    control: _control,
    shift: _shift,
    flush: _flush,
    mode: _mode,
    buffer: _buffer,
    data: data,
    output: output,
  );

  set state(Eeprom24C02State state) {
    _previousScl = state.previousScl;
    _previousSda = state.previousSda;

    _address = state.address;
    _bit = state.bit;
    _control = state.control;
    _shift = state.shift;

    _flush = state.flush;

    _mode = state.mode;

    _buffer.setAll(0, state.buffer);
    data.setAll(0, state.data);

    output = state.output;
  }

  void reset() {
    _previousScl = 0;
    _previousSda = 0;

    _address = 0;
    _bit = 0;
    _control = 0;
    _shift = 0;

    _buffer.fillRange(0, _buffer.length, 0);

    _flush = false;

    _mode = .idle;

    output = 1;
  }

  void input(int scl, int sda) {
    try {
      if (_start(scl, sda)) {
        _control = 0;
        _bit = 0;
        _mode = .control;

        // make sure the current buffer contents won't get flushed
        _flush = false;

        output = 1;
      }

      if (_stop(scl, sda)) {
        if (_flush) {
          _commitBuffer();
        }

        _mode = .idle;

        output = 1;

        return;
      }

      switch (_mode) {
        case .idle:
          _handleIdle(scl, sda);
        case .control:
          _handleControl(scl, sda);
        case .address:
          _handleAddress(scl, sda);
        case .read:
          _handleRead(scl, sda);
        case .write:
          _handleWrite(scl, sda);
      }
    } finally {
      _previousScl = scl;
      _previousSda = sda;
    }
  }

  void _handleIdle(int scl, int sda) {}

  void _handleControl(int scl, int sda) {
    if (_rising(scl)) {
      if (_bit < 8) {
        _control = _control.setBit(7 - _bit++, sda);
      }

      return;
    }

    if (_falling(scl)) {
      if (_bit == 8) {
        if (output == 0) {
          // end of ACK, move to next mode

          _bit = 0;
          _mode = (_control & 1) == 1 ? .read : .address;

          output = 1;

          return;
        }

        if ((_control & 0xf0) != 0xa0) {
          _mode = .idle;

          return;
        }

        // send ACK
        output = 0;
      }
    }
  }

  void _handleAddress(int scl, int sda) {
    if (_rising(scl)) {
      if (_bit < 8) {
        _address = _address.setBit(7 - _bit++, sda);
      }

      return;
    }

    if (_falling(scl)) {
      if (_bit == 8) {
        if (output == 0) {
          // end of ACK, move to write

          _bit = 0;
          _mode = .write;

          // copy current data as a basis for the write
          _buffer.setRange(0, _buffer.length, data, _address & 0xf0);

          output = 1;

          return;
        }

        // send ACK
        output = 0;
      }
    }
  }

  void _handleRead(int scl, int sda) {
    if (_rising(scl)) {
      if (_bit < 8) {
        output = data[_address].bit(7 - _bit++);
      }

      return;
    }

    if (_falling(scl)) {
      if (_bit == 8) {
        if (sda == 0) {
          // ACK, send next byte

          _bit = 0;

          _address = (_address + 1) & 0xff;
        }

        // otherwise, wait for ACK
      }
    }
  }

  void _handleWrite(int scl, int sda) {
    if (_rising(scl)) {
      if (_bit < 8) {
        _shift = _shift.setBit(7 - _bit++, sda);
      }

      return;
    }

    if (_falling(scl)) {
      if (_bit == 8) {
        if (output == 0) {
          // end of ACK, receive next byte

          _bit = 0;

          output = 1;

          return;
        }

        _buffer[_address & 0xf] = _shift;

        _flush = true;

        _address = (_address & 0xf0) | ((_address + 1) & 0xf);

        // send ACK
        output = 0;
      }
    }
  }

  void _commitBuffer() {
    final page = _address & 0xf0;

    data.setRange(page, page + _buffer.length, _buffer);

    _flush = false;
  }

  bool _start(int scl, int sda) =>
      _previousScl == 1 && scl == 1 && _previousSda > sda;

  bool _stop(int scl, int sda) =>
      _previousScl == 1 && scl == 1 && _previousSda < sda;

  bool _rising(int scl) => _previousScl < scl;

  bool _falling(int scl) => _previousScl > scl;
}
