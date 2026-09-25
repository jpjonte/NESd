import 'package:nesd/exception/nesd_exception.dart';

class RomDownloadFailed extends NesdException {
  RomDownloadFailed(super.message, {super.previous});
}
