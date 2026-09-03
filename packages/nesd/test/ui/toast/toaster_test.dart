import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/toast/toaster.dart';

void main() {
  group('Toaster', () {
    late ProviderContainer container;
    late Toaster toaster;

    setUp(() {
      container = ProviderContainer()
        ..listen(toastStateProvider, (_, _) {})
        ..listen(toasterProvider, (_, _) {});

      toaster = container.read(toasterProvider);
    });

    tearDown(() => container.dispose());

    List<Toast> toasts() => container.read(toastStateProvider);

    test('ignores a toast identical to one already queued', () {
      toaster
        ..send(Toast.error('boom'))
        ..send(Toast.error('boom'));

      expect(toasts(), hasLength(1));
    });

    test('queues toasts with different messages separately', () {
      toaster
        ..send(Toast.error('boom'))
        ..send(Toast.error('bang'));

      expect(toasts(), hasLength(2));
    });

    test('queues toasts with the same message but different types', () {
      toaster
        ..send(Toast.error('boom'))
        ..send(Toast.warning('boom'));

      expect(toasts(), hasLength(2));
    });

    test('drops the oldest toast when the queue is full', () {
      for (var i = 0; i < 7; i++) {
        toaster.send(Toast.info('toast $i'));
      }

      expect(toasts(), hasLength(5));
      expect(toasts().first.message, 'toast 2');
      expect(toasts().last.message, 'toast 6');
    });
  });

  group('Toast', () {
    test('strips stack trace frames from the message', () {
      final toast = Toast.error(
        'Invalid argument(s): Failed to load dynamic library'
        " 'eslz4-win64.dll': error code 126\n"
        '#0      _open (dart:ffi-patch/ffi_dynamic_library_patch.dart:11)\n'
        '#1      new DynamicLibrary.open '
        '(dart:ffi-patch/ffi_dynamic_library_patch.dart:22)\n'
        '#2      Lz4.instance '
        '(package:nesd/nes/rewind/lz4_native.dart:34)',
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
