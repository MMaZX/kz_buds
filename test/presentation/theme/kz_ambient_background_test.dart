import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_ambient_background.dart';

import '../../support/pump_kz.dart';

void main() {
  testWidgets('paints behind its child inside a RepaintBoundary', (
    tester,
  ) async {
    await pumpKz(
      tester,
      const SizedBox(
        width: 300,
        height: 400,
        child: KzAmbientBackground(child: Text('over ambient')),
      ),
    );
    expect(find.text('over ambient'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KzAmbientBackground),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(KzAmbientBackground),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('changing glowScale animates without errors', (tester) async {
    Widget ambient(double scale) => SizedBox(
      width: 300,
      height: 400,
      child: KzAmbientBackground(glowScale: scale, child: const Text('x')),
    );
    await pumpKz(tester, ambient(1));
    await pumpKz(tester, ambient(0.85));
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
