import 'dart:ffi';

String hostArch() => Abi.current() == Abi.linuxArm64 ? 'arm64' : 'x64';
