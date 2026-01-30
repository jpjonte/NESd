extension BitExtension on int {
  int bit(int n) => (this >> n) & 1;

  // get bits start..end
  // shift out bits lower than start
  // mask out bits higher than end
  int bits(int start, int end) => (this >> start) & (0xff >> (7 - end));

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
