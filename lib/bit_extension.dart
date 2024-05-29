extension BitExtension on int {
  int bit(int n) {
    return (this >> n) & 1;
  }

  int setBit(int n, int value) {
    var value = this;

    if (value == 0) {
      value &= ~(1 << n);
    } else {
      value |= 1 << n;
    }

    return value;
  }
}
