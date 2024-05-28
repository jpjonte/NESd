extension BitExtension on int {
  int bit(int n) {
    return (this >> n) & 1;
  }
}
