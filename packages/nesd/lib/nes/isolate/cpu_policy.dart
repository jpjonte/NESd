import 'dart:io';

import 'package:path/path.dart' as p;

class CpuPolicy {
  const CpuPolicy({required this.maxFrequency, required this.cpus});

  final int maxFrequency;
  final List<int> cpus;
}

List<int> fastCoresFrom(List<CpuPolicy> policies) {
  if (policies.length < 2) {
    return const [];
  }

  var slowest = policies.first.maxFrequency;
  var fastest = policies.first.maxFrequency;

  for (final policy in policies) {
    if (policy.maxFrequency < slowest) {
      slowest = policy.maxFrequency;
    }

    if (policy.maxFrequency > fastest) {
      fastest = policy.maxFrequency;
    }
  }

  if (slowest == fastest) {
    return const [];
  }

  return [
    for (final policy in policies)
      if (policy.maxFrequency > slowest) ...policy.cpus,
  ]..sort();
}

List<CpuPolicy> readCpuPolicies(Directory root) {
  if (!root.existsSync()) {
    return const [];
  }

  final policies = <CpuPolicy>[];

  for (final entry in root.listSync()) {
    if (entry is! Directory || !p.basename(entry.path).startsWith('policy')) {
      continue;
    }

    try {
      final maxFrequency = int.parse(
        File('${entry.path}/cpuinfo_max_freq').readAsStringSync().trim(),
      );
      final cpus = File(
        '${entry.path}/related_cpus',
      ).readAsStringSync().trim().split(RegExp(r'\s+')).map(int.parse).toList();

      policies.add(CpuPolicy(maxFrequency: maxFrequency, cpus: cpus));
    } on FileSystemException {
      continue;
    } on FormatException {
      continue;
    }
  }

  return policies;
}
