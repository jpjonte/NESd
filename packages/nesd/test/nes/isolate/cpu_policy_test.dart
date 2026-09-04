import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesd/nes/isolate/cpu_policy.dart';

void main() {
  group('fastCoresFrom', () {
    test('keeps only the big cluster on a 6+2 layout', () {
      final cores = fastCoresFrom(const [
        CpuPolicy(maxFrequency: 1708800, cpus: [0, 1, 2, 3, 4, 5]),
        CpuPolicy(maxFrequency: 1996800, cpus: [6, 7]),
      ]);

      expect(cores, [6, 7]);
    });

    test('keeps prime and mid cores on a 4+3+1 layout', () {
      final cores = fastCoresFrom(const [
        CpuPolicy(maxFrequency: 2000000, cpus: [0, 1, 2, 3]),
        CpuPolicy(maxFrequency: 2800000, cpus: [4, 5, 6]),
        CpuPolicy(maxFrequency: 3300000, cpus: [7]),
      ]);

      expect(cores, [4, 5, 6, 7]);
    });

    test('pins nothing with a single policy', () {
      expect(
        fastCoresFrom(const [
          CpuPolicy(maxFrequency: 3000000, cpus: [0, 1, 2, 3]),
        ]),
        isEmpty,
      );
    });

    test('pins nothing when every policy has the same maximum', () {
      expect(
        fastCoresFrom(const [
          CpuPolicy(maxFrequency: 2400000, cpus: [0, 1]),
          CpuPolicy(maxFrequency: 2400000, cpus: [2, 3]),
        ]),
        isEmpty,
      );
    });

    test('drops every policy that shares the lowest maximum', () {
      final cores = fastCoresFrom(const [
        CpuPolicy(maxFrequency: 1800000, cpus: [0, 1]),
        CpuPolicy(maxFrequency: 1800000, cpus: [2, 3]),
        CpuPolicy(maxFrequency: 2600000, cpus: [4, 5, 6, 7]),
      ]);

      expect(cores, [4, 5, 6, 7]);
    });
  });

  group('readCpuPolicies', () {
    test('parses cpufreq policy directories', () async {
      final root = await Directory.systemTemp.createTemp('cpufreq');

      addTearDown(() => root.delete(recursive: true));

      for (final (name, freq, cpus) in [
        ('policy0', '1708800', '0 1 2 3 4 5'),
        ('policy6', '1996800', '6 7'),
      ]) {
        final dir = Directory('${root.path}/$name')..createSync();

        File('${dir.path}/cpuinfo_max_freq').writeAsStringSync('$freq\n');
        File('${dir.path}/related_cpus').writeAsStringSync('$cpus\n');
      }

      final policies = readCpuPolicies(root);

      expect(policies, hasLength(2));
      expect(
        policies.map((p) => p.maxFrequency),
        containsAll([1708800, 1996800]),
      );
      expect(fastCoresFrom(policies), [6, 7]);
    });

    test('returns nothing for a missing directory', () {
      expect(readCpuPolicies(Directory('/nonexistent/cpufreq')), isEmpty);
    });

    test('skips a policy with unreadable files', () async {
      final root = await Directory.systemTemp.createTemp('cpufreq');

      addTearDown(() => root.delete(recursive: true));

      Directory('${root.path}/policy0').createSync();

      final good = Directory('${root.path}/policy4')..createSync();

      File('${good.path}/cpuinfo_max_freq').writeAsStringSync('2000000');
      File('${good.path}/related_cpus').writeAsStringSync('4 5');

      final policies = readCpuPolicies(root);

      expect(policies, hasLength(1));
      expect(policies.single.cpus, [4, 5]);
    });
  });
}
