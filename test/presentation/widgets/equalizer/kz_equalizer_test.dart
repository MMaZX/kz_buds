import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/widgets/equalizer/kz_equalizer.dart';
import 'package:kz_buds/presentation/widgets/equalizer/kz_equalizer_controller.dart';

import '../../../support/pump_kz.dart';

void main() {
  const frequencies = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  const width = 360.0;
  late KzEqualizerController eq;

  setUp(() {
    eq = KzEqualizerController(
      gains: List.filled(frequencies.length, 0),
      min: -8,
      max: 8,
      step: 0.5,
    );
  });

  Future<void> pump(WidgetTester tester, {Widget Function(Widget)? wrap}) {
    final equalizer = KzEqualizer(controller: eq, frequencies: frequencies);
    return pumpKz(
      tester,
      wrap?.call(equalizer) ?? SizedBox(width: width, child: equalizer),
    );
  }

  /// Global position of [fraction] (0 bottom, 1 top) on [band]'s track.
  Offset trackPoint(WidgetTester tester, int band, double fraction) {
    final origin = tester.getTopLeft(find.byType(KzEqualizer));
    final size = tester.getSize(find.byType(KzEqualizer));
    final geometry = KzEqualizerGeometry(size, frequencies.length);
    return origin +
        Offset(geometry.track(band).center.dx, geometry.yOfFraction(fraction));
  }

  group('geometry', () {
    test('tracks split the slider area evenly between the scale columns', () {
      final g = KzEqualizerGeometry(const Size(width, 400), 10);

      expect(g.track(0).center.dx, KzEqualizerGeometry.side + g.slot / 2);
      expect(
        g.track(9).center.dx,
        width - KzEqualizerGeometry.side - g.slot / 2,
      );
      expect(g.bandAtX(g.track(4).center.dx), 4);
      expect(g.bandAtX(-5), isNull);
    });

    test('fraction and y are inverse along the thumb travel', () {
      final g = KzEqualizerGeometry(const Size(width, 400), 10);

      expect(g.fractionAtY(g.yOfFraction(0.25)), closeTo(0.25, 1e-9));
      expect(g.fractionAtY(-100), 1);
      expect(g.fractionAtY(10000), 0);
    });

    test('frequency fraction spans 20 Hz to 20 kHz and clamps', () {
      expect(eqFrequencyFraction(20), 0);
      expect(eqFrequencyFraction(20000), closeTo(1, 1e-9));
      expect(eqFrequencyFraction(5), 0);
      expect(eqFrequencyFraction(632.4555), closeTo(0.5, 1e-6));
    });

    test('frequencies map to the graph on a log scale', () {
      final g = KzEqualizerGeometry(const Size(width, 400), 10);
      final x20 = g.graphXOf(20);
      final x200 = g.graphXOf(200);
      final x2000 = g.graphXOf(2000);

      expect(x200 - x20, closeTo(x2000 - x200, 1e-9));
    });
  });

  testWidgets('shows the axis, both scales and the selected value', (
    tester,
  ) async {
    eq.setGain(0, 2);
    await pump(tester);

    for (final label in ['20', '50', '100', '500', '1K', '5K', '10K', '20K']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('+'), findsNWidgets(2));
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('-'), findsNWidgets(2));
    expect(find.text('+2.0'), findsOneWidget);
  });

  testWidgets('a tap selects the band and sets its gain as one step', (
    tester,
  ) async {
    await pump(tester);

    await tester.tapAt(trackPoint(tester, 2, 1));
    await tester.pump();

    expect(eq.selected, 2);
    expect(eq.gains[2], 8);
    expect(eq.committed[2], 8);
    expect(find.text('+8.0'), findsOneWidget);
  });

  testWidgets('a drag edits live and commits once at the end', (tester) async {
    await pump(tester);
    final gesture = await tester.startGesture(trackPoint(tester, 1, 0.5));
    await gesture.moveTo(trackPoint(tester, 1, 0.6));
    await gesture.moveTo(trackPoint(tester, 1, 0.75));
    await tester.pump();

    expect(eq.selected, 1);
    expect(eq.gains[1], 4);
    expect(eq.canUndo, isFalse);

    await gesture.up();
    expect(eq.committed[1], 4);

    eq.undo();
    expect(eq.gains[1], 0);
  });

  testWidgets('arrow keys move the selection and nudge the gain', (
    tester,
  ) async {
    await pump(tester);
    await tester.tapAt(trackPoint(tester, 0, 0.5));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(eq.selected, 1);
    expect(eq.gains[1], 1);
    expect(eq.canUndo, isTrue);
  });

  testWidgets('describes the selected band as an adjustable slider', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    eq
      ..select(5)
      ..setGain(5, 2);
    await pump(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Band 1KHz'));
    expect(node.value, '+2.0 dB');
    expect(node.increasedValue, '+2.5 dB');
    expect(node.decreasedValue, '+1.5 dB');
    handle.dispose();
  });

  testWidgets('lays out at its preferred width under unbounded width', (
    tester,
  ) async {
    await pump(
      tester,
      wrap: (child) => Row(mainAxisSize: MainAxisSize.min, children: [child]),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(KzEqualizer)).width,
      KzEqualizerGeometry.preferredWidth,
    );
  });

  testWidgets('repaints when the controller changes', (tester) async {
    await pump(tester);

    eq.setGain(0, -3);
    await tester.pump();

    expect(find.text('-3.0'), findsOneWidget);
  });

  group('motion', () {
    List<double> shown(WidgetTester tester) =>
        tester.state<KzEqualizerState>(find.byType(KzEqualizer)).shownGains;

    testWidgets('a gain change glides fast and eases out to the target', (
      tester,
    ) async {
      await pump(tester);

      eq.setGain(0, 8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final early = shown(tester)[0];
      await tester.pump(const Duration(milliseconds: 80));
      final mid = shown(tester)[0];

      // Exponential ease-out: most of the way in the first frames.
      expect(early, greaterThan(4));
      expect(early, lessThan(8));
      expect(mid, greaterThan(early));
      expect(eq.gains[0], 8);

      await tester.pumpAndSettle();
      expect(shown(tester)[0], 8);
    });

    testWidgets('a glide only repaints: no rebuild on each tick', (
      tester,
    ) async {
      final raw = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RawEqualizer',
      );
      await pump(tester);
      eq.setGain(0, 8);
      await tester.pump();
      final first = tester.widget(raw);

      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(milliseconds: 40));

      expect(shown(tester)[0], lessThan(8));
      expect(identical(tester.widget(raw), first), isTrue);
    });

    testWidgets('a new target mid-way continues from what is shown', (
      tester,
    ) async {
      await pump(tester);
      eq.setGain(0, 8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final before = shown(tester)[0];

      eq.setGain(0, -8);
      await tester.pump();

      expect(shown(tester)[0], closeTo(before, 0.5));
      await tester.pumpAndSettle();
      expect(shown(tester)[0], -8);
    });

    testWidgets('jumps at once when the platform reduces motion', (
      tester,
    ) async {
      await pumpKz(
        tester,
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: width,
            child: KzEqualizer(controller: eq, frequencies: frequencies),
          ),
        ),
      );

      eq.setGain(0, 8);
      await tester.pump();

      expect(shown(tester)[0], 8);
    });
  });
}
