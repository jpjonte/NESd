import 'dart:typed_data';

class SampleDecimator {
  double _sum = 0;
  int _count = 0;
  int _factor = 0;

  void reset() {
    _sum = 0;
    _count = 0;
  }

  Float32List decimate(Float32List input, int factor) {
    if (factor != _factor) {
      reset();

      _factor = factor;
    }

    final output = Float32List((_count + input.length) ~/ factor);

    var outIndex = 0;

    for (var i = 0; i < input.length; i++) {
      _sum += input[i];
      _count++;

      if (_count == factor) {
        output[outIndex++] = _sum / factor;
        _sum = 0;
        _count = 0;
      }
    }

    return output;
  }
}
