part of '../input_action.dart';

class ScreenshotAction extends InputAction {
  const ScreenshotAction({required super.title, required super.code});
}

const screenshot = ScreenshotAction(
  title: 'Screenshot',
  code: 'state.screenshot',
);
