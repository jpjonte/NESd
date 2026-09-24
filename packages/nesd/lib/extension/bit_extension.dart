extension BitExtension on int {
  @pragma('vm:prefer-inline')
  int bit(int n) => (this >> n) & 1;

  // get bits start..end
  // shift out bits lower than start
  // mask out bits higher than end
  @pragma('vm:prefer-inline')
  int bits(int start, int end) => (this >> start) & (0xff >> (7 - end));

  @pragma('vm:prefer-inline')
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
