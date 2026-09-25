import 'package:nesd/exception/nesd_exception.dart';

class RomTooLarge extends NesdException {
  RomTooLarge({required Uri url, required int maxBytes})
    : super('$url is larger than ${maxBytes ~/ (1024 * 1024)} MiB');
}
