extension BitExtension on int {
  int bit(int n) {
    return (this >> n) & 1;
  }

  int setBit(int n, int value) {
    var object = this;

    if (value == 0) {
      object &= ~(1 << n);
    } else {
      object |= 1 << n;
    }

    return object;
  }
}
