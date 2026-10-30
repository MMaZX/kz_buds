import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/link_state.dart';
import 'package:kz_buds/main.dart';
import 'package:kz_buds/presentation/providers/earbuds_providers.dart';

Future<void> pumpPage(WidgetTester tester, FakeEarbudsAdapter fake) async {
  addTearDown(fake.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [earbudsPortProvider.overrideWithValue(fake)],
      child: const KzBudsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows left, right and case battery', (tester) async {
    await pumpPage(tester, FakeEarbudsAdapter());
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Case'), findsOneWidget);
  });

  testWidgets('hides the case when it is not reported', (tester) async {
    await pumpPage(
      tester,
      FakeEarbudsAdapter(
        initialBattery: const BatteryStatus(left: 40, right: 41),
      ),
    );
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Case'), findsNothing);
  });

  testWidgets('shows disconnected state without battery', (tester) async {
    await pumpPage(
      tester,
      FakeEarbudsAdapter(initialConnection: LinkState.disconnected),
    );
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Left'), findsNothing);
  });
}
