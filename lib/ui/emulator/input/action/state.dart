part of '../input_action.dart';

class PauseAction extends InputAction {
  const PauseAction({
    required this.paused,
    required super.title,
    required super.code,
    super.toggleable,
  });

  final bool paused;
}

class StopAction extends InputAction {
  const StopAction({required super.title, required super.code});
}

class FastForward extends InputAction {
  const FastForward({required super.title, required super.code})
    : super(toggleable: true);
}

class Rewind extends InputAction {
  const Rewind({required super.title, required super.code})
    : super(toggleable: true);
}

class DecreaseVolume extends InputAction {
  const DecreaseVolume({required super.title, required super.code});
}

class IncreaseVolume extends InputAction {
  const IncreaseVolume({required super.title, required super.code});
}

const pause = PauseAction(
  paused: true,
  title: 'Pause',
  code: 'state.pause',
  toggleable: true,
);

const unpause = PauseAction(
  paused: false,
  title: 'Unpause',
  code: 'state.unpause',
);

const stop = StopAction(title: 'Stop Game', code: 'state.stop');

const fastForward = FastForward(
  title: 'Fast Forward',
  code: 'state.fastForward',
);

const rewind = Rewind(title: 'Rewind', code: 'state.rewind');

const decreaseVolume = DecreaseVolume(
  title: 'Decrease Volume',
  code: 'state.decreaseVolume',
);

const increaseVolume = IncreaseVolume(
  title: 'Increase Volume',
  code: 'state.increaseVolume',
);
