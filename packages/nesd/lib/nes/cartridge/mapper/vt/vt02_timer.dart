class VT02Timer {
  int preload = 0;
  int counter = 0;

  bool running = false;
  bool enabled = false;

  void load() {
    counter = preload;
    running = true;
  }

  bool tick() {
    if (!running) {
      return false;
    }

    counter = (counter - 1) & 0xff;

    if (counter != 0) {
      return false;
    }

    counter = preload;

    return enabled;
  }

  void reset() {
    preload = 0;
    counter = 0;
    running = false;
    enabled = false;
  }
}
