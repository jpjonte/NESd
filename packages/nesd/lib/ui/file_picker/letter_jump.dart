typedef LetterJumpEntry = ({String name, bool isDirectory, bool focusable});

typedef LetterJumpTarget = ({int index, String group});

typedef _GroupKey = ({bool isDirectory, String group});

LetterJumpTarget? letterJump(
  List<LetterJumpEntry> entries, {
  required int currentIndex,
  required bool forward,
}) {
  if (entries.isEmpty) {
    return null;
  }

  final keys = _groupKeys(entries);
  final index = currentIndex.clamp(-1, entries.length - 1);

  if (forward) {
    return _jumpForward(entries, keys, index);
  }

  return _jumpBackward(entries, keys, index);
}

int? nearestFocusable(
  List<LetterJumpEntry> entries,
  int start, {
  required int direction,
}) {
  assert(direction == 1 || direction == -1);

  for (var i = start; i >= 0 && i < entries.length; i += direction) {
    if (entries[i].focusable) {
      return i;
    }
  }

  return null;
}

LetterJumpTarget? _jumpForward(
  List<LetterJumpEntry> entries,
  List<_GroupKey> keys,
  int index,
) {
  final currentKey = index >= 0 ? keys[index] : null;

  for (var i = index + 1; i < entries.length; i++) {
    if (keys[i] != currentKey && entries[i].focusable) {
      return (index: i, group: keys[i].group.toUpperCase());
    }
  }

  return null;
}

LetterJumpTarget? _jumpBackward(
  List<LetterJumpEntry> entries,
  List<_GroupKey> keys,
  int index,
) {
  if (index < 0) {
    return null;
  }

  var groupEnd = index;

  while (groupEnd >= 0) {
    final key = keys[groupEnd];

    var groupStart = groupEnd;

    while (groupStart > 0 && keys[groupStart - 1] == key) {
      groupStart--;
    }

    for (var i = groupStart; i < index; i++) {
      if (keys[i] == key && entries[i].focusable) {
        return (index: i, group: key.group.toUpperCase());
      }
    }

    groupEnd = groupStart - 1;
  }

  return null;
}

List<_GroupKey> _groupKeys(List<LetterJumpEntry> entries) {
  final names = [for (final entry in entries) entry.name.toLowerCase()];

  final prefixLength = _commonPrefixLength(names);

  return [
    for (var i = 0; i < entries.length; i++)
      (
        isDirectory: entries[i].isDirectory,
        group: names[i].length > prefixLength
            ? names[i].substring(0, prefixLength + 1)
            : '',
      ),
  ];
}

int _commonPrefixLength(List<String> names) {
  var length = names.first.length;

  for (final name in names.skip(1)) {
    var i = 0;

    while (i < length && i < name.length && name[i] == names.first[i]) {
      i++;
    }

    length = i;

    if (length == 0) {
      break;
    }
  }

  return length;
}
