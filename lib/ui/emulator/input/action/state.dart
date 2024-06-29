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
