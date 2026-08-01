/// An expansion sound chip on the cartridge, mixed into the APU's output.
///
/// [debugOutputs]'s length is fixed for the chip's lifetime, because the APU
/// allocates its debug capture lanes from it once.
/// The owning mapper's `expansionAudio` getter must return a stable instance
/// after construction, because the APU caches it in `reset()`.
abstract class ExpansionAudio {
  void step();

  double get output;

  List<int> get debugOutputs;
}
