/// Earbuds the OS already knows that may speak a supported protocol.
/// Only connecting proves it.
class DetectedEarbuds {
  const DetectedEarbuds({required this.id, required this.name});

  /// Stable transport id (the Bluetooth address on Linux and Android).
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is DetectedEarbuds && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'DetectedEarbuds($name)';
}
