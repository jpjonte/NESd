part of '../action.dart';

class OpenSettings extends NesAction {
  const OpenSettings({
    required super.title,
    required super.code,
  });
}

const openSettings = OpenSettings(
  title: 'Open Settings',
  code: 'ui.openSettings',
);
