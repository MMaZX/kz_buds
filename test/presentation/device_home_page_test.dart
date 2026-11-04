import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/earbuds_identity.dart';
import 'package:kz_buds/domain/entities/link_state.dart';
import 'package:kz_buds/presentation/providers/navigation_providers.dart';
import 'package:kz_buds/presentation/theme/kz_model_art.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';
import 'package:kz_buds/presentation/widgets/noise_control_sheet.dart';

import '../support/pump_home.dart';

void main() {
  group('battery', () {
    testWidgets('shows left, right and case', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('78%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('hides the case when it is not reported', (tester) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(
          initialBattery: const BatteryStatus(left: 40, right: 41),
        ),
      );
      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('C'), findsNothing);
    });

    testWidgets('hides a bud that is not reported', (tester) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(
          initialBattery: const BatteryStatus(right: 55, caseLevel: 10),
        ),
      );
      expect(find.text('L'), findsNothing);
      expect(find.text('R'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('updates live', (tester) async {
      final fake = FakeEarbudsAdapter();
      await pumpApp(tester, fake);
      fake.updateBattery(const BatteryStatus(left: 11, right: 22));
      await tester.pumpAndSettle();
      expect(find.text('11%'), findsOneWidget);
      expect(find.text('C'), findsNothing);
    });
  });

  group('noise control', () {
    testWidgets('shows only with the anc capability', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('NOISE CONTROL'), findsOneWidget);
    });

    testWidgets('no anc capability hides it', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter(capabilities: {}));
      expect(find.text('NOISE CONTROL'), findsNothing);
    });

    testWidgets('opens the noise control sheet', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      await tester.tap(find.bySemanticsLabel('Noise control details'));
      await tester.pumpAndSettle();
      expect(find.byType(NoiseControlSheet), findsOneWidget);
    });
  });

  group('shortcuts', () {
    testWidgets('equalizer and controls follow their capabilities', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('EQUALIZER'), findsNothing);
      expect(find.text('CONTROLS'), findsNothing);

      await pumpApp(
        tester,
        FakeEarbudsAdapter(
          capabilities: {Capability.eq, Capability.buttonRemap},
        ),
      );
      expect(find.text('EQUALIZER'), findsOneWidget);
      expect(find.text('CONTROLS'), findsOneWidget);
    });

    testWidgets('equalizer opens the equalizer tab', (tester) async {
      final container = await pumpApp(
        tester,
        FakeEarbudsAdapter(capabilities: {Capability.eq}),
      );
      await tester.tap(find.text('EQUALIZER'));
      await tester.pumpAndSettle();
      expect(container.read(selectedTabProvider), KzTab.eq);
    });

    testWidgets('the settings icon opens the settings tab', (tester) async {
      final container = await pumpApp(tester, FakeEarbudsAdapter());
      await tester.tap(find.bySemanticsLabel('Open settings'));
      await tester.pumpAndSettle();
      expect(container.read(selectedTabProvider), KzTab.settings);
    });

    testWidgets('the title is the model name', (tester) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(identity: const EarbudsIdentity(name: 'CAROL PRO')),
      );
      expect(find.text('KZ CAROL PRO'), findsOneWidget);
    });
  });

  testWidgets('the page background is one flat color', (tester) async {
    await pumpApp(tester, FakeEarbudsAdapter());
    final flat = find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == KzPalette.inkBg,
    );
    expect(flat, findsWidgets);
  });

  testWidgets('the page background is flat: no gradient anywhere', (
    tester,
  ) async {
    await pumpApp(tester, FakeEarbudsAdapter());
    final gradients = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox && (w.decoration as BoxDecoration).gradient != null,
    );
    expect(gradients, findsNothing);
    expect(
      find.byType(CustomPaint).evaluate().where((e) {
        final paint = e.widget as CustomPaint;
        return paint.painter != null &&
            paint.painter.runtimeType.toString().contains('Ambient');
      }),
      isEmpty,
    );
  });

  group('link state', () {
    testWidgets('disconnected shows the status and no battery', (tester) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(initialLinkState: LinkState.disconnected),
      );
      expect(find.text('Disconnected'), findsWidgets);
      expect(find.text('L'), findsNothing);
      expect(find.text('NOISE CONTROL'), findsNothing);
    });

    testWidgets('connecting shows the status', (tester) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(initialLinkState: LinkState.connecting),
      );
      expect(find.text('Connecting...'), findsWidgets);
      expect(find.text('L'), findsNothing);
    });

    testWidgets('reacts to the link dropping', (tester) async {
      final fake = FakeEarbudsAdapter();
      await pumpApp(tester, fake);
      expect(find.text('L'), findsOneWidget);
      fake.updateLinkState(LinkState.disconnected);
      await tester.pumpAndSettle();
      expect(find.text('L'), findsNothing);
      expect(find.text('Disconnected'), findsWidgets);
    });

    testWidgets('disconnected offers Reconnect, which connects', (
      tester,
    ) async {
      final fake = FakeEarbudsAdapter(initialLinkState: LinkState.disconnected);
      await pumpApp(tester, fake);

      await tester.tap(find.text('RECONNECT'));
      await tester.pumpAndSettle();

      expect(fake.connectCalls, 1);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('RECONNECT'), findsNothing);
    });

    testWidgets('connected and connecting hide Reconnect', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.text('RECONNECT'), findsNothing);

      await pumpApp(
        tester,
        FakeEarbudsAdapter(initialLinkState: LinkState.connecting),
      );
      expect(find.text('RECONNECT'), findsNothing);
    });
  });

  testWidgets('a recognised model shows its artwork as the hero', (
    tester,
  ) async {
    await pumpApp(
      tester,
      FakeEarbudsAdapter(identity: const EarbudsIdentity(name: 'CAROL PRO')),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, KzModelArt.kzCarolPro);
    expect(find.bySemanticsLabel('KZ Carol Pro'), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('the hero is a Placeholder until renders exist', (tester) async {
    await pumpApp(tester, FakeEarbudsAdapter());
    expect(find.byType(Placeholder), findsOneWidget);
  });

  group('renders in dark and light for every state', () {
    final states = <String, FakeEarbudsAdapter Function()>{
      'all capabilities': FakeEarbudsAdapter.new,
      'no anc': () => FakeEarbudsAdapter(capabilities: {}),
      'case null': () => FakeEarbudsAdapter(
        initialBattery: const BatteryStatus(left: 30, right: 20),
      ),
      'disconnected': () =>
          FakeEarbudsAdapter(initialLinkState: LinkState.disconnected),
      'critical battery': () => FakeEarbudsAdapter(
        initialBattery: const BatteryStatus(left: 5, right: 9, caseLevel: 3),
      ),
      'every capability': () =>
          FakeEarbudsAdapter(capabilities: Capability.values.toSet()),
    };
    for (final preference in [
      KzThemePreference.dark,
      KzThemePreference.light,
    ]) {
      for (final entry in states.entries) {
        testWidgets('${entry.key} / ${preference.name}', (tester) async {
          await pumpApp(tester, entry.value(), preference: preference);
          expect(tester.takeException(), isNull);
          expect(find.byType(Placeholder), findsOneWidget);
        });
      }
    }
  });
}
