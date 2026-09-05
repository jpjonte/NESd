class VT02Timer {
  int preload = 0;
  int counter = 0;

  bool running = false;
  bool enabled = false;

  void load() {
    counter = 0;
    running = true;
  }

  bool tick() {
    if (!running) {
      return false;
    }

    if (counter == 0) {
      counter = preload;
    } else {
      counter--;
    }

    return counter == 0 && enabled;
  }

  void reset() {
    preload = 0;
    counter = 0;
    running = false;
    enabled = false;
  }
}
