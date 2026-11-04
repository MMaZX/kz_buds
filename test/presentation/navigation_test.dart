import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/domain/entities/eq_settings.dart';
import 'package:kz_buds/presentation/pages/anc_page.dart';
import 'package:kz_buds/presentation/providers/eq_providers.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/widgets/equalizer/kz_equalizer.dart';
import 'package:kz_buds/presentation/widgets/kz_chip.dart';
import 'package:kz_buds/presentation/widgets/kz_nav_pill.dart';

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

    EqSettings? sent(ProviderContainer container) =>
        container.read(eqSettingsProvider).value;

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the equalizer on Flat with the band readouts', (
      tester,
    ) async {
      await openEq(tester);
      expect(find.byType(KzEqualizer), findsOneWidget);
      expect(find.text('F 31HZ'), findsOneWidget);
      expect(find.text('GAIN 0.0 DB'), findsOneWidget);
      expect(chipSelected(tester, 'Flat'), isTrue);
    });

    testWidgets('choosing Bass sends that preset', (tester) async {
      final container = await openEq(tester);
      await tester.tap(find.widgetWithText(KzChip, 'Bass'));
      await tester.pumpAndSettle();
      expect(chipSelected(tester, 'Bass'), isTrue);
      expect(sent(container)?.mode, 1);
      expect(find.text('+6.0'), findsOneWidget);
    });

    testWidgets('dragging a band sends the custom mode', (tester) async {
      final container = await openEq(tester);
      final box = find.byType(KzEqualizer);
      final geometry = KzEqualizerGeometry(tester.getSize(box), 10);
      final start =
          tester.getTopLeft(box) +
          Offset(geometry.track(0).center.dx, geometry.yOfFraction(0.5));
      await tester.dragFrom(start, const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(sent(container)?.mode, FakeEarbudsAdapter.eqDevProfile.customMode);
      expect(sent(container)!.gains.first, greaterThan(0));
      expect(chipSelected(tester, 'Custom'), isTrue);
    });

    testWidgets('undo and redo send the previous gains as custom', (
      tester,
    ) async {
      final container = await openEq(tester);
      await tester.tap(find.widgetWithText(KzChip, 'Bass'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.bySemanticsLabel('Undo'));
      expect(sent(container)?.gains, List.filled(10, 0.0));
      await tapVisible(tester, find.bySemanticsLabel('Redo'));
      expect(
        sent(container)?.gains,
        FakeEarbudsAdapter.eqDevProfile.presets[1].gains,
      );
    });

    testWidgets('Reset sends flat gains', (tester) async {
      final container = await openEq(tester);
      await tester.tap(find.widgetWithText(KzChip, 'Bass'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('RESET'));
      expect(sent(container)?.gains, List.filled(10, 0.0));
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

    testWidgets('a pushed page is opaque and slides in, never fades', (
      tester,
    ) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      await tester.tap(find.bySemanticsLabel('Noise control details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.ancestor(
          of: find.byType(AncPage),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byType(AncPage),
          matching: find.byType(SlideTransition),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byType(AncPage),
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == KzPalette.inkBg,
          ),
        ),
        // The app background plus the route's own opaque background.
        findsNWidgets(2),
      );
    });

    testWidgets('the home does not show through the page', (tester) async {
      await pumpApp(tester, FakeEarbudsAdapter());
      expect(find.byType(Placeholder), findsOneWidget);
      await openAnc(tester);
      expect(find.text('Noise control'), findsOneWidget);
      expect(find.byType(Placeholder), findsNothing);
      expect(find.text('KZ Buds'), findsNothing);
      expect(find.text('NOISE CONTROL'), findsNothing);
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
