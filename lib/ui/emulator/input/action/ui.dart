part of '../action.dart';

class OpenMenu extends NesAction {
  const OpenMenu({
    required super.title,
    required super.code,
  });
}

class PreviousInput extends NesAction {
  const PreviousInput({
    required super.title,
    required super.code,
  });
}

class NextInput extends NesAction {
  const NextInput({
    required super.title,
    required super.code,
  });
}

class Confirm extends NesAction {
  const Confirm({
    required super.title,
    required super.code,
  });
}

class SecondaryAction extends NesAction {
  const SecondaryAction({
    required super.title,
    required super.code,
  });
}

class Cancel extends NesAction {
  const Cancel({
    required super.title,
    required super.code,
  });
}

class PreviousTab extends NesAction {
  const PreviousTab({
    required super.title,
    required super.code,
  });
}

class NextTab extends NesAction {
  const NextTab({
    required super.title,
    required super.code,
  });
}

class MenuDecrease extends NesAction {
  const MenuDecrease({
    required super.title,
    required super.code,
  });
}

class MenuIncrease extends NesAction {
  const MenuIncrease({
    required super.title,
    required super.code,
  });
}

const openMenu = OpenMenu(
  title: 'Open Menu',
  code: 'ui.openMenu',
);

const previousInput = PreviousInput(
  title: 'Previous Input',
  code: 'ui.previousInput',
);

const nextInput = NextInput(
  title: 'Next Input',
  code: 'ui.nextInput',
);

const confirm = Confirm(
  title: 'Confirm',
  code: 'ui.confirm',
);

const secondaryAction = SecondaryAction(
  title: 'Secondary Action',
  code: 'ui.secondaryAction',
);

const cancel = Cancel(
  title: 'Cancel',
  code: 'ui.cancel',
);

const previousTab = PreviousTab(
  title: 'Previous Tab',
  code: 'ui.previousTab',
);

const nextTab = NextTab(
  title: 'Next Tab',
  code: 'ui.nextTab',
);

const menuDecrease = MenuDecrease(
  title: 'Menu Decrease',
  code: 'ui.menuDecrease',
);

const menuIncrease = MenuIncrease(
  title: 'Menu Increase',
  code: 'ui.menuIncrease',
);
