part of '../input_action.dart';

class TogglePauseAction extends InputAction {
  const TogglePauseAction({
    required super.title,
    required super.code,
  });
}

class PauseAction extends InputAction {
  const PauseAction({
    required this.paused,
    required super.title,
    required super.code,
  });

  final bool paused;
}

class StopAction extends InputAction {
  const StopAction({
    required super.title,
    required super.code,
  });
}

class ToggleFastForward extends InputAction {
  const ToggleFastForward({
    required super.title,
    required super.code,
  });
}

class DecreaseVolume extends InputAction {
  const DecreaseVolume({
    required super.title,
    required super.code,
  });
}

class IncreaseVolume extends InputAction {
  const IncreaseVolume({
    required super.title,
    required super.code,
  });
}

const togglePause = TogglePauseAction(
  title: 'Toggle Pause',
  code: 'state.togglePause',
);

const pause = PauseAction(
  paused: true,
  title: 'Pause',
  code: 'state.pause',
);

const unpause = PauseAction(
  paused: false,
  title: 'Unpause',
  code: 'state.unpause',
);

const stop = StopAction(
  title: 'Stop Game',
  code: 'state.stop',
);

const toggleFastForward = ToggleFastForward(
  title: 'Toggle Fast Forward',
  code: 'state.toggleFastForward',
);

const decreaseVolume = DecreaseVolume(
  title: 'Decrease Volume',
  code: 'state.decreaseVolume',
);

const increaseVolume = IncreaseVolume(
  title: 'Increase Volume',
  code: 'state.increaseVolume',
);
