import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/widgets/equalizer/kz_equalizer_controller.dart';

void main() {
  KzEqualizerController build([List<double>? gains]) => KzEqualizerController(
    gains: gains ?? const [0, 0, 0],
    min: -8,
    max: 8,
    step: 0.5,
  );

  test('snaps and clamps a gain to the step and the range', () {
    final eq = build()..setGain(1, 2.3);
    expect(eq.gains, [0, 2.5, 0]);

    eq.setGain(1, 40);
    expect(eq.gains, [0, 8, 0]);
  });

  test('select clamps to the band range and notifies', () {
    final eq = build();
    var notified = 0;
    eq.addListener(() => notified++);

    eq.select(7);

    expect(eq.selected, 2);
    expect(notified, 1);
  });

  test('a drag (setGain then commit) is one undo step', () {
    final eq = build()
      ..setGain(0, 1)
      ..setGain(0, 2)
      ..setGain(0, 3);
    expect(eq.canUndo, isFalse);

    eq.commit();
    expect(eq.committed, [3, 0, 0]);
    expect(eq.canUndo, isTrue);

    eq.undo();
    expect(eq.gains, [0, 0, 0]);
    expect(eq.committed, [0, 0, 0]);
    expect(eq.canRedo, isTrue);

    eq.redo();
    expect(eq.gains, [3, 0, 0]);
  });

  test('committing an unchanged state adds no history', () {
    final eq = build()..commit();

    expect(eq.canUndo, isFalse);
  });

  test('a new commit after undo drops the redo branch', () {
    final eq = build()
      ..nudge(0, 2)
      ..undo()
      ..nudge(1, -1);

    expect(eq.gains, [0, -0.5, 0]);
    expect(eq.canRedo, isFalse);
  });

  test('setAll and reset are single undo steps', () {
    final eq = build()..setAll(const [1, 2, 3]);
    expect(eq.committed, [1, 2, 3]);

    eq.reset();
    expect(eq.gains, [0, 0, 0]);

    eq.undo();
    expect(eq.gains, [1, 2, 3]);
  });

  test('setAll rejects a list of another length', () {
    expect(() => build().setAll(const [1]), throwsArgumentError);
  });

  test('load takes outside gains as a new baseline without history', () {
    final eq = build()..nudge(0, 2);
    var notified = 0;
    eq.addListener(() => notified++);

    eq.load(const [1, 2, 3]);

    expect(eq.gains, [1, 2, 3]);
    expect(eq.committed, [1, 2, 3]);
    expect(eq.canUndo, isFalse);
    expect(eq.canRedo, isFalse);
    expect(notified, 1);
  });
}
