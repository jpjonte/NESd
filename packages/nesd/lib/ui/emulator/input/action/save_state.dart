part of '../input_action.dart';

class SaveState extends InputAction {
  const SaveState(this.slot, {required super.title, required super.code});

  final int slot;
}

const saveState1 = SaveState(1, title: 'Save State 1', code: 'saveState1.save');

const saveState2 = SaveState(2, title: 'Save State 2', code: 'saveState2.save');

const saveState3 = SaveState(3, title: 'Save State 3', code: 'saveState3.save');

const saveState4 = SaveState(4, title: 'Save State 4', code: 'saveState4.save');

const saveState5 = SaveState(5, title: 'Save State 5', code: 'saveState5.save');

const saveState6 = SaveState(6, title: 'Save State 6', code: 'saveState6.save');

const saveState7 = SaveState(7, title: 'Save State 7', code: 'saveState7.save');

const saveState8 = SaveState(8, title: 'Save State 8', code: 'saveState8.save');

const saveState9 = SaveState(9, title: 'Save State 9', code: 'saveState9.save');
