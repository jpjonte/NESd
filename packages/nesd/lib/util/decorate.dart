U? decorate<T, U>(T? value, U Function(T) decorator) {
  if (value == null) {
    return null;
  }

  return decorator(value);
}
