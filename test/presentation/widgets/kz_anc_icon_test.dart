import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/widgets/kz_anc_icon.dart';

import '../../support/pump_kz.dart';

void main() {
  testWidgets('each mode has its own glyph', (tester) async {
    final icons = AncMode.values.map(KzAncIcon.iconFor).toSet();
    expect(icons, hasLength(AncMode.values.length));
  });

  testWidgets('renders the mode glyph with its color', (tester) async {
    await pumpKz(
      tester,
      const KzAncIcon(mode: AncMode.ambient, color: KzPalette.signalRedDark),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, KzAncIcon.iconFor(AncMode.ambient));
    expect(icon.color, KzPalette.signalRedDark);
  });

  testWidgets('describes the mode for accessibility', (tester) async {
    await pumpKz(tester, const KzAncIcon(mode: AncMode.ambient));
    expect(find.bySemanticsLabel('Ambient'), findsOneWidget);
  });
}
