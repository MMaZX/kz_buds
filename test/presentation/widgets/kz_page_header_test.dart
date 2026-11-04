import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/widgets/kz_page_header.dart';

import '../../support/pump_kz.dart';

void main() {
  testWidgets('a top-level page shows only the title, no bar', (tester) async {
    await pumpKz(tester, const KzPageHeader(title: 'Settings'));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsNothing);
    expect(find.bySemanticsLabel('More options'), findsNothing);
  });

  testWidgets('the title sits below the back arrow, aligned left', (
    tester,
  ) async {
    var backs = 0;
    await pumpKz(
      tester,
      SizedBox(
        width: 360,
        child: KzPageHeader(title: 'Find my buds', onBack: () => backs++),
      ),
    );
    final back = tester.getRect(find.bySemanticsLabel('Back'));
    final title = tester.getRect(find.text('Find my buds'));
    expect(title.top, greaterThanOrEqualTo(back.bottom));
    expect(title.left, back.left);

    await tester.tap(find.bySemanticsLabel('Back'));
    expect(backs, 1);
  });

  testWidgets('shows the more button on the right only when it has an action', (
    tester,
  ) async {
    var mores = 0;
    await pumpKz(
      tester,
      SizedBox(
        width: 360,
        child: KzPageHeader(
          title: 'Equalizer',
          onBack: () {},
          onMore: () => mores++,
        ),
      ),
    );
    final back = tester.getRect(find.bySemanticsLabel('Back'));
    final more = tester.getRect(find.bySemanticsLabel('More options'));
    expect(more.left, greaterThan(back.right));
    expect(more.top, back.top);

    await tester.tap(find.bySemanticsLabel('More options'));
    expect(mores, 1);
  });
}
