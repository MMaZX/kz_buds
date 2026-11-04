/// What the earbuds' equalizer is set to: a preset [mode] and its gains.
class EqSettings {
  const EqSettings({required this.mode, required this.gains});

  final int mode;

  /// One gain in dB per band of the [EqProfile].
  final List<double> gains;

  @override
  bool operator ==(Object other) =>
      other is EqSettings &&
      other.mode == mode &&
      _sameGains(other.gains, gains);

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(gains));

  @override
  String toString() => 'EqSettings($mode, $gains)';
}

/// A preset the device stores: its mode and gains. [name] only when the
/// source knows one; the RCSP firmware reports none.
class EqPresetData {
  const EqPresetData({required this.mode, required this.gains, this.name});

  final int mode;
  final List<double> gains;
  final String? name;
}

/// What the equalizer of the connected earbuds offers.
class EqProfile {
  const EqProfile({
    required this.frequencies,
    required this.presets,
    required this.customMode,
    required this.minGain,
    required this.maxGain,
    this.step = 1,
  });

  /// Band centers in Hz, ascending.
  final List<int> frequencies;

  /// Read-only presets; the [customMode] one is what the user edits.
  final List<EqPresetData> presets;
  final int customMode;
  final double minGain;
  final double maxGain;
  final double step;
}

bool _sameGains(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
