final _wordCharacter = RegExp('[a-z0-9]');

double? fuzzyScore(String query, String target) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty);

  final lowerTarget = target.toLowerCase();

  var total = 0.0;

  for (final token in tokens) {
    final score = _tokenScore(token, lowerTarget);

    if (score == null) {
      return null;
    }

    total += score;
  }

  return total;
}

double? _tokenScore(String token, String target) {
  double? best;

  for (var start = 0; start < target.length; start++) {
    if (target[start] != token[0]) {
      continue;
    }

    final score = _scoreFrom(token, target, start);

    if (score != null && (best == null || score > best)) {
      best = score;
    }
  }

  return best;
}

double? _scoreFrom(String token, String target, int start) {
  var score = 0.0;
  var previous = -2;
  var index = start;

  for (var i = 0; i < token.length; i++) {
    final found = target.indexOf(token[i], index);

    if (found < 0) {
      return null;
    }

    score += 1;

    if (found == previous + 1) {
      score += 2;
    }

    if (_isWordStart(target, found)) {
      score += 3;
    }

    previous = found;
    index = found + 1;
  }

  return score - start * 0.01;
}

bool _isWordStart(String target, int index) {
  return index == 0 || !_wordCharacter.hasMatch(target[index - 1]);
}
