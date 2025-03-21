part of '../input_action.dart';

class OpenMenu extends InputAction {
  const OpenMenu({required super.title, required super.code});
}

class PreviousInput extends InputAction {
  const PreviousInput({required super.title, required super.code});
}

class NextInput extends InputAction {
  const NextInput({required super.title, required super.code});
}

class InputUp extends InputAction {
  const InputUp({required super.title, required super.code});
}

class InputDown extends InputAction {
  const InputDown({required super.title, required super.code});
}

class InputLeft extends InputAction {
  const InputLeft({required super.title, required super.code});
}

class InputRight extends InputAction {
  const InputRight({required super.title, required super.code});
}

class Confirm extends InputAction {
  const Confirm({required super.title, required super.code});
}

class SecondaryAction extends InputAction {
  const SecondaryAction({required super.title, required super.code});
}

class Cancel extends InputAction {
  const Cancel({required super.title, required super.code});
}

class PreviousTab extends InputAction {
  const PreviousTab({required super.title, required super.code});
}

class NextTab extends InputAction {
  const NextTab({required super.title, required super.code});
}

class MenuDecrease extends InputAction {
  const MenuDecrease({required super.title, required super.code});
}

class MenuIncrease extends InputAction {
  const MenuIncrease({required super.title, required super.code});
}

const openMenu = OpenMenu(title: 'Open Menu', code: 'ui.openMenu');

const previousInput = PreviousInput(
  title: 'Previous Input',
  code: 'ui.previousInput',
);

const nextInput = NextInput(title: 'Next Input', code: 'ui.nextInput');

const inputUp = InputUp(title: 'Input Up', code: 'ui.inputUp');

const inputDown = InputDown(title: 'Input Down', code: 'ui.inputDown');

const inputLeft = InputLeft(title: 'Input Left', code: 'ui.inputLeft');

const inputRight = InputRight(title: 'Input Right', code: 'ui.inputRight');

const confirm = Confirm(title: 'Confirm', code: 'ui.confirm');

const secondaryAction = SecondaryAction(
  title: 'Secondary Action',
  code: 'ui.secondaryAction',
);

const cancel = Cancel(title: 'Cancel', code: 'ui.cancel');

const previousTab = PreviousTab(title: 'Previous Tab', code: 'ui.previousTab');

const nextTab = NextTab(title: 'Next Tab', code: 'ui.nextTab');

const menuDecrease = MenuDecrease(
  title: 'Menu Decrease',
  code: 'ui.menuDecrease',
);

const menuIncrease = MenuIncrease(
  title: 'Menu Increase',
  code: 'ui.menuIncrease',
);
