import 'package:nes/exception/nesd_exception.dart';

class CartridgeNotLoaded extends NesdException {
  CartridgeNotLoaded()
      : super('Cannot run the NES without a cartridge loaded.');
}
