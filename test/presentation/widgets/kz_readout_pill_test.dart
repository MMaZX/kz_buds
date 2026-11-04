import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/widgets/kz_readout_pill.dart';

import '../../support/pump_kz.dart';

void main() {
  testWidgets('shows its label and is read-only for accessibility', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKz(
      tester,
      const SizedBox(
        width: 160,
        child: KzReadoutPill(label: 'F 1KHZ', fraction: 0.5),
      ),
    );

    expect(find.text('F 1KHZ'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('F 1KHZ'));
    expect(node.flagsCollection.isReadOnly, isTrue);
    expect(node.flagsCollection.isButton, isFalse);
    handle.dispose();
  });

  test('clamps the marker inside the pill', () {
    expect(const KzReadoutPill(label: 'x', fraction: 3).marker, 1);
    expect(const KzReadoutPill(label: 'x', fraction: -1).marker, 0);
  });
}
