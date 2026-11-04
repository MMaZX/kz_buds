import 'package:flutter/foundation.dart';

/// State of a [KzEqualizer]: one gain per band, the selected band and an
/// undo history.
///
/// Live edits ([setGain], as during a drag) change [gains] without history;
/// [commit] turns them into one undo step. [nudge], [setAll] and [reset]
/// commit on their own. [committed] is what a caller should send to the
/// device.
class KzEqualizerController extends ChangeNotifier {
  KzEqualizerController({
    required List<double> gains,
    required this.min,
    required this.max,
    this.step = 1,
    int selected = 0,
  }) : assert(gains.isNotEmpty, 'needs at least one band'),
       assert(min < max, 'min must be below max'),
       assert(step > 0, 'step must be positive'),
       _gains = List.of(gains),
       _history = [List.unmodifiable(gains)],
       _selected = selected.clamp(0, gains.length - 1);

  final double min;
  final double max;
  final double step;

  final List<double> _gains;
  final List<List<double>> _history;
  var _index = 0;
  int _selected;

  int get bandCount => _gains.length;

  List<double> get gains => List.unmodifiable(_gains);

  /// The last committed gains: the state undo and redo move between.
  List<double> get committed => _history[_index];

  int get selected => _selected;

  bool get canUndo => _index > 0;

  bool get canRedo => _index < _history.length - 1;

  /// 0 when the range includes it, else [min].
  double get zero => min <= 0 && max >= 0 ? 0 : min;

  double snap(double gain) {
    final snapped = ((gain.clamp(min, max) - min) / step).round() * step + min;
    return snapped.clamp(min, max);
  }

  void select(int band) {
    final next = band.clamp(0, bandCount - 1);
    if (next == _selected) return;
    _selected = next;
    notifyListeners();
  }

  /// Live edit without history; follow it with [commit].
  void setGain(int band, double gain) {
    final next = snap(gain);
    if (_gains[band] == next) return;
    _gains[band] = next;
    notifyListeners();
  }

  /// Records the current gains as one undo step, if they changed.
  void commit() {
    if (listEquals(_gains, committed)) return;
    _history
      ..removeRange(_index + 1, _history.length)
      ..add(List.unmodifiable(_gains));
    _index++;
    notifyListeners();
  }

  /// Moves [band] by [steps] steps and commits.
  void nudge(int band, int steps) {
    setGain(band, _gains[band] + steps * step);
    commit();
  }

  /// Replaces every gain (a preset) as one undo step.
  void setAll(List<double> gains) {
    if (gains.length != bandCount) {
      throw ArgumentError.value(gains, 'gains', 'needs $bandCount values');
    }
    for (var i = 0; i < bandCount; i++) {
      _gains[i] = snap(gains[i]);
    }
    notifyListeners();
    commit();
  }

  void reset() => setAll(List.filled(bandCount, zero));

  /// Takes gains from outside (the device) as the new baseline: no undo
  /// step, and the history starts over.
  void load(List<double> gains) {
    if (gains.length != bandCount) {
      throw ArgumentError.value(gains, 'gains', 'needs $bandCount values');
    }
    for (var i = 0; i < bandCount; i++) {
      _gains[i] = snap(gains[i]);
    }
    _history
      ..clear()
      ..add(List.unmodifiable(_gains));
    _index = 0;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _index--;
    _restore();
  }

  void redo() {
    if (!canRedo) return;
    _index++;
    _restore();
  }

  void _restore() {
    _gains.setAll(0, committed);
    notifyListeners();
  }
}
