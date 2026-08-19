import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/ui/log/log_actions.dart';

void main() {
  test('the export filename stamps the given time', () {
    expect(
      logExportFileName(DateTime(2026, 8, 19, 14, 3, 22)),
      'nesd-log-20260819-140322.log',
    );
  });

  test('the export filename zero-pads single-digit components', () {
    expect(
      logExportFileName(DateTime(2026, 1, 2, 3, 4, 5)),
      'nesd-log-20260102-030405.log',
      reason: 'an unpadded stamp would sort wrongly and read ambiguously',
    );
  });

  test('the export filename is distinct from the execution log dump', () {
    expect(
      logExportFileName(DateTime(2026, 8, 19)),
      isNot('nesd.log'),
      reason:
          'the execution log writes a plain nesd.log; a bug report may '
          'carry both, so these must not collide',
    );
  });
}
