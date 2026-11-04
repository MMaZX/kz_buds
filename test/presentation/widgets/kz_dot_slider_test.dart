import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/widgets/kz_dot_slider.dart';

import '../../support/pump_kz.dart';

class _Host extends StatefulWidget {
  const _Host({required this.onChanged});

  final ValueChanged<double> onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double value = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: KzDotSlider(
      value: value,
      min: -12,
      max: 12,
      step: 0.5,
      semanticsLabel: '100 Hz',
      onChanged: (next) {
        setState(() => value = next);
        widget.onChanged(next);
      },
    ),
  );
}

KzDotSliderPainter painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(KzDotSlider),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as KzDotSliderPainter;

void main() {
  testWidgets('dragging up raises the value, snapped to the step', (
    tester,
  ) async {
    final values = <double>[];
    await pumpKz(tester, _Host(onChanged: values.add));
    await tester.drag(find.byType(KzDotSlider), const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(values, isNotEmpty);
    expect(values.last, greaterThan(0));
    expect(values.last % 0.5, 0);
  });

  testWidgets('dragging past the ends clamps to min and max', (tester) async {
    final values = <double>[];
    await pumpKz(tester, _Host(onChanged: values.add));
    await tester.drag(find.byType(KzDotSlider), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(values.last, 12);
    await tester.drag(find.byType(KzDotSlider), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(values.last, -12);
  });

  testWidgets('paints a dotted track; the thumb turns red off zero', (
    tester,
  ) async {
    await pumpKz(tester, _Host(onChanged: (_) {}));
    expect(painter(tester).dotCount, greaterThan(4));
    expect(painter(tester).thumb, KzPalette.inkText);

    await tester.drag(find.byType(KzDotSlider), const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(painter(tester).thumb, KzPalette.signalRedDark);
  });

  testWidgets('steps up with a semantic increase', (tester) async {
    final values = <double>[];
    await pumpKz(tester, _Host(onChanged: values.add));
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(find.bySemanticsLabel('100 Hz'));
    expect(node.label, '100 Hz');
    expect(node.value, '0');

    tester.semantics.increase(find.semantics.byLabel('100 Hz'));
    await tester.pumpAndSettle();
    expect(values.last, 0.5);
    semantics.dispose();
  });
}
