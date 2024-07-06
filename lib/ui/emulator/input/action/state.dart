part of '../action.dart';

class TogglePauseAction extends NesAction {
  const TogglePauseAction({
    required super.title,
    required super.code,
  });
}

class PauseAction extends NesAction {
  const PauseAction({
    required this.paused,
    required super.title,
    required super.code,
  });

  final bool paused;
}

class StopAction extends NesAction {
  const StopAction({
    required super.title,
    required super.code,
  });
}

class DecreaseVolume extends NesAction {
  const DecreaseVolume({
    required super.title,
    required super.code,
  });
}

class IncreaseVolume extends NesAction {
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

const decreaseVolume = DecreaseVolume(
  title: 'Decrease Volume',
  code: 'state.decreaseVolume',
);

const increaseVolume = IncreaseVolume(
  title: 'Increase Volume',
  code: 'state.increaseVolume',
);
