import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/presentation/widgets/kz_anc_rings.dart';

import '../../support/pump_kz.dart';

KzAncRingsPainter painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(KzAncRings),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as KzAncRingsPainter;
}

void main() {
  for (final (mode, rings) in [
    (AncMode.off, 0),
    (AncMode.noiseCancelling, 2),
    (AncMode.ambient, 3),
  ]) {
    testWidgets('$mode draws $rings rings', (tester) async {
      await pumpKz(tester, KzAncRings(mode: mode));
      expect(painter(tester).ringCount, rings);
    });
  }

  testWidgets('describes the mode for accessibility', (tester) async {
    await pumpKz(tester, const KzAncRings(mode: AncMode.ambient));
    expect(find.bySemanticsLabel('Ambient'), findsOneWidget);
  });
}
