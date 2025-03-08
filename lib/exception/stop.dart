import 'package:nesd/exception/nesd_exception.dart';

class Stop extends NesdException {
  Stop() : super('ROM ran into a STP instruction');
}
