import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

class RawUint8List implements List<int> {
  RawUint8List(this.length) : _data = malloc<Uint8>(length);

  RawUint8List.fromList(List<int> list)
    : length = list.length,
      _data = malloc<Uint8>(list.length) {
    _data.asTypedList(list.length).setAll(0, list);
  }

  @override
  final int length;

  @override
  set length(int newLength) {
    throw UnimplementedError();
  }

  final Pointer<Uint8> _data;

  Uint8List get bytes => _data.asTypedList(length);

  void free() => malloc.free(_data);

  @override
  int operator [](int index) => _data[index];

  @override
  void operator []=(int index, int value) => _data[index] = value;

  @override
  int get first => _data[0];

  @override
  set first(int value) => _data[0] = value;

  @override
  int get last => _data[length - 1];

  @override
  set last(int value) => _data[length - 1] = value;

  @override
  List<int> operator +(List<int> other) {
    throw UnimplementedError();
  }

  @override
  void add(int value) {
    throw UnimplementedError();
  }

  @override
  void addAll(Iterable<int> iterable) {
    throw UnimplementedError();
  }

  @override
  bool any(bool Function(int element) test) {
    throw UnimplementedError();
  }

  @override
  Map<int, int> asMap() {
    throw UnimplementedError();
  }

  @override
  List<R> cast<R>() {
    throw UnimplementedError();
  }

  @override
  void clear() {}

  @override
  bool contains(Object? element) {
    throw UnimplementedError();
  }

  @override
  int elementAt(int index) {
    throw UnimplementedError();
  }

  @override
  bool every(bool Function(int element) test) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(int element) toElements) {
    throw UnimplementedError();
  }

  @override
  void fillRange(int start, int end, [int? fillValue]) {}

  @override
  int firstWhere(bool Function(int element) test, {int Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, int element) combine) {
    throw UnimplementedError();
  }

  @override
  Iterable<int> followedBy(Iterable<int> other) {
    throw UnimplementedError();
  }

  @override
  void forEach(void Function(int element) action) {}

  @override
  Iterable<int> getRange(int start, int end) {
    throw UnimplementedError();
  }

  @override
  int indexOf(int element, [int start = 0]) {
    throw UnimplementedError();
  }

  @override
  int indexWhere(bool Function(int element) test, [int start = 0]) {
    throw UnimplementedError();
  }

  @override
  void insert(int index, int element) {}

  @override
  void insertAll(int index, Iterable<int> iterable) {}

  @override
  bool get isEmpty => throw UnimplementedError();

  @override
  bool get isNotEmpty => throw UnimplementedError();

  @override
  Iterator<int> get iterator => throw UnimplementedError();

  @override
  String join([String separator = ""]) {
    throw UnimplementedError();
  }

  @override
  int lastIndexOf(int element, [int? start]) {
    throw UnimplementedError();
  }

  @override
  int lastIndexWhere(bool Function(int element) test, [int? start]) {
    throw UnimplementedError();
  }

  @override
  int lastWhere(bool Function(int element) test, {int Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> map<T>(T Function(int e) toElement) {
    throw UnimplementedError();
  }

  @override
  int reduce(int Function(int value, int element) combine) {
    throw UnimplementedError();
  }

  @override
  bool remove(Object? value) {
    throw UnimplementedError();
  }

  @override
  int removeAt(int index) {
    throw UnimplementedError();
  }

  @override
  int removeLast() {
    throw UnimplementedError();
  }

  @override
  void removeRange(int start, int end) {}

  @override
  void removeWhere(bool Function(int element) test) {}

  @override
  void replaceRange(int start, int end, Iterable<int> replacements) {}

  @override
  void retainWhere(bool Function(int element) test) {}

  @override
  Iterable<int> get reversed => throw UnimplementedError();

  @override
  void setAll(int index, Iterable<int> iterable) {}

  @override
  void setRange(
    int start,
    int end,
    Iterable<int> iterable, [
    int skipCount = 0,
  ]) {}

  @override
  void shuffle([Random? random]) {}

  @override
  int get single => throw UnimplementedError();

  @override
  int singleWhere(bool Function(int element) test, {int Function()? orElse}) {
    throw UnimplementedError();
  }

  @override
  Iterable<int> skip(int count) {
    throw UnimplementedError();
  }

  @override
  Iterable<int> skipWhile(bool Function(int value) test) {
    throw UnimplementedError();
  }

  @override
  void sort([int Function(int a, int b)? compare]) {}

  @override
  List<int> sublist(int start, [int? end]) {
    throw UnimplementedError();
  }

  @override
  Iterable<int> take(int count) {
    throw UnimplementedError();
  }

  @override
  Iterable<int> takeWhile(bool Function(int value) test) {
    throw UnimplementedError();
  }

  @override
  List<int> toList({bool growable = true}) => bytes.toList();

  @override
  Set<int> toSet() {
    throw UnimplementedError();
  }

  @override
  Iterable<int> where(bool Function(int element) test) {
    throw UnimplementedError();
  }

  @override
  Iterable<T> whereType<T>() {
    throw UnimplementedError();
  }
}
