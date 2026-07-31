import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/toast/toaster.dart';

void main() {
  group('Toast', () {
    test('strips stack trace frames from the message', () {
      final toast = Toast.error(
        'Invalid argument(s): Failed to load dynamic library'
        " 'eslz4-win64.dll': error code 126\n"
        '#0      _open (dart:ffi-patch/ffi_dynamic_library_patch.dart:11)\n'
        '#1      new DynamicLibrary.open '
        '(dart:ffi-patch/ffi_dynamic_library_patch.dart:22)\n'
        '#2      Lz4Library._instance '
        '(package:es_compression/src/lz4/ffi/library.dart:34)',
      );

      expect(
        toast.message,
        'Invalid argument(s): Failed to load dynamic library'
        " 'eslz4-win64.dll': error code 126",
      );
    });

    test('strips asynchronous suspension markers from the message', () {
      final toast = Toast.error(
        'Failed to load state: oops\n'
        '#0      RewindBuffer.add (package:nesd/nes/rewind/rewind_buffer.dart:59)\n'
        '<asynchronous suspension>\n'
        '#1      _microtaskLoop (dart:async/schedule_microtask.dart:40)',
      );

      expect(toast.message, 'Failed to load state: oops');
    });

    test('keeps messages without stack traces unchanged', () {
      final toast = Toast.info('SRAM saved');

      expect(toast.message, 'SRAM saved');
    });

    test('keeps multi-line messages without frames unchanged', () {
      final toast = Toast.warning('line one\nline two');

      expect(toast.message, 'line one\nline two');
    });

    test('strips frames between message lines', () {
      final toast = Toast.error(
        'first error\n'
        '#0      _open (dart:ffi-patch/ffi_dynamic_library_patch.dart:11)\n'
        'second error',
      );

      expect(toast.message, 'first error\nsecond error');
    });
  });
}
