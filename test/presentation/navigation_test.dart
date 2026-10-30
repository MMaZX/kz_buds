import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/presentation/providers/eq_providers.dart';
import 'package:kz_buds/presentation/widgets/kz_chip.dart';
import 'package:kz_buds/presentation/widgets/kz_nav_pill.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/pump_home.dart';

FakeEarbudsAdapter withEq() =>
    FakeEarbudsAdapter(capabilities: {Capability.anc, Capability.eq});

bool chipSelected(WidgetTester tester, String label) =>
    tester.widget<KzChip>(find.widgetWithText(KzChip, label)).selected;

void main() {
  group('navigation shell', () {
    testWidgets('without capabilities the nav has Home and Settings', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.byType(KzNavPill), findsOneWidget);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Equalizer'), findsNothing);
      expect(find.bySemanticsLabel('Touch'), findsNothing);
    });

    testWidgets('the button remap capability adds a Touch destination', (
      tester,
    ) async {
      await pumpApp(
        tester,
        FakeEarbudsAdapter(capabilities: {Capability.buttonRemap}),
      );
      expect(find.bySemanticsLabel('Touch'), findsOneWidget);
    });

    testWidgets('eq capability adds an EQ destination', (tester) async {
      await pumpApp(tester, withEq());
      expect(find.byType(KzNavPill), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Equalizer'));
      await tester.pumpAndSettle();
      expect(find.text('Equalizer'), findsWidgets);
      expect(find.byType(Placeholder), findsNothing);

      await tester.tap(find.bySemanticsLabel('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });

  group('equalizer', () {
    Future<ProviderContainer> openEq(WidgetTester tester) async {
      final container = await pumpApp(tester, withEq());
      await tester.tap(find.bySemanticsLabel('Equalizer'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows ten bands and starts on Flat', (tester) async {
      await openEq(tester);
      expect(find.byType(ShadSlider), findsNWidgets(10));
      for (final label in eqBandLabels) {
        expect(find.text(label), findsOneWidget);
      }
      expect(chipSelected(tester, 'Flat'), isTrue);
    });

    testWidgets('choosing Bass moves the sliders', (tester) async {
      final container = await openEq(tester);
      await tester.tap(find.widgetWithText(KzChip, 'Bass'));
      await tester.pumpAndSettle();
      expect(chipSelected(tester, 'Bass'), isTrue);
      expect(container.read(eqProvider).preset, EqPreset.bass);
      expect(find.text('+6'), findsOneWidget);
    });

    testWidgets('dragging a band switches to Custom', (tester) async {
      final container = await openEq(tester);
      await tester.drag(find.byType(ShadSlider).first, const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(container.read(eqProvider).preset, EqPreset.custom);
      expect(container.read(eqProvider).gains.first, greaterThan(0));
      expect(chipSelected(tester, 'Custom'), isTrue);
    });

    testWidgets('Reset returns to Flat', (tester) async {
      final container = await openEq(tester);
      await tester.tap(find.widgetWithText(KzChip, 'Bass'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(container.read(eqProvider).preset, EqPreset.flat);
      expect(chipSelected(tester, 'Flat'), isTrue);
    });
  });

  group('noise control page', () {
    Future<void> openAnc(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Noise control details'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens from the home card and lists the three modes', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      await openAnc(tester);
      expect(find.text('Noise control'), findsOneWidget);
      expect(find.text('Reduces outside noise'), findsOneWidget);
      expect(find.text('Lets outside sound in'), findsOneWidget);
      expect(find.text('No processing'), findsOneWidget);
    });

    testWidgets('choosing a mode sets it on the device', (tester) async {
      final fake = FakeEarbudsAdapter();
      await pumpApp(tester, fake);
      await openAnc(tester);
      await tester.tap(find.text('Lets outside sound in'));
      await tester.pumpAndSettle();
      expect(fake.ancMode, AncMode.ambient);
    });

    testWidgets('back returns to the home', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      await openAnc(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Noise control'), findsNothing);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
