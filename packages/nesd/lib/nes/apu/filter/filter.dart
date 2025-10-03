import 'dart:math';

class Filter {
  Filter(this.b0, this.b1, this.a1);

  factory Filter.lowPass(double sampleRate, double cutoffFreq) {
    final c = sampleRate / pi / cutoffFreq;
    final a0i = 1 / (1 + c);

    return Filter(a0i, a0i, (1 - c) * a0i);
  }

  factory Filter.highPass(double sampleRate, double cutoffFreq) {
    final c = sampleRate / pi / cutoffFreq;
    final a0i = 1 / (1 + c);

    return Filter(c * a0i, -c * a0i, (1 - c) * a0i);
  }

  final double b0;
  final double b1;
  final double a1;

  double prevX = 0;
  double prevY = 0;

  // y[n] = B0*x[n] + B1*x[n-1] - A1*y[n-1]
  double apply(double x) {
    final y = b0 * x + b1 * prevX - a1 * prevY;

    prevY = y;
    prevX = x;

    return y;
  }
}
