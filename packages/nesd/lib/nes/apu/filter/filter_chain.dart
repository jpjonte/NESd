import 'package:nesd/nes/apu/filter/filter.dart';

class FilterChain {
  FilterChain(this.filters);

  final List<Filter> filters;

  bool enabled = true;

  double apply(double sample) {
    if (!enabled) {
      return sample;
    }

    return filters.fold(sample, (result, filter) => filter.apply(result));
  }
}
