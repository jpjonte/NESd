import 'package:nesd/exception/nesd_exception.dart';

class InvalidSaveStateHeader extends NesdException {
  InvalidSaveStateHeader(List<int> header)
    : super(
        'Invalid Save State: Expected "NESd" as header,'
        ' got ${header[0]}${header[1]}${header[2]}${header[3]}',
      );
}
