import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kz_buds/presentation/theme/kz_icons.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';
import 'package:kz_buds/presentation/widgets/kz_battery_indicator.dart';
import 'package:kz_buds/presentation/widgets/kz_chip.dart';
import 'package:kz_buds/presentation/widgets/kz_list_row.dart';
import 'package:kz_buds/presentation/widgets/kz_nav_pill.dart';
import 'package:kz_buds/presentation/widgets/kz_page.dart';
import 'package:kz_buds/presentation/widgets/kz_power_pill.dart';
import 'package:kz_buds/presentation/widgets/kz_round_button.dart';
import 'package:kz_buds/presentation/widgets/kz_section.dart';

import '../../support/pump_kz.dart';

void main() {
  group('KzChip', () {
    testWidgets('tap calls onPressed', (tester) async {
      var taps = 0;
      await pumpKz(
        tester,
        KzChip(label: 'ANC', selected: false, onPressed: () => taps++),
      );
      await tester.tap(find.text('ANC'));
      expect(taps, 1);
    });

    testWidgets('disabled chip is dimmed and has no tap action', (
      tester,
    ) async {
      await pumpKz(tester, const KzChip(label: 'Off', selected: false));
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(KzChip),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.4);
      final gesture = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byType(KzChip),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(gesture.onTap, isNull);
    });

    testWidgets('keyboard: tab to focus, enter activates', (tester) async {
      var taps = 0;
      await pumpKz(
        tester,
        KzChip(label: 'ANC', selected: false, onPressed: () => taps++),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('selected chip fills with the primary color', (tester) async {
      await pumpKz(
        tester,
        KzChip(label: 'ANC', selected: true, onPressed: () {}),
      );
      final filled = find.descendant(
        of: find.byType(KzChip),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).color == KzPalette.paper,
        ),
      );
      expect(filled, findsOneWidget);
    });
  });

  group('KzPowerPill', () {
    testWidgets('shows ON and toggles off on tap', (tester) async {
      bool? received;
      await pumpKz(
        tester,
        KzPowerPill(value: true, onChanged: (v) => received = v),
      );
      expect(find.text('ON'), findsOneWidget);
      await tester.tap(find.byType(KzPowerPill));
      expect(received, isFalse);
    });

    testWidgets('shows OFF when off and toggles on', (tester) async {
      bool? received;
      await pumpKz(
        tester,
        KzPowerPill(value: false, onChanged: (v) => received = v),
      );
      expect(find.text('OFF'), findsOneWidget);
      await tester.tap(find.byType(KzPowerPill));
      expect(received, isTrue);
    });
  });

  group('KzRoundButton', () {
    testWidgets('is 56 px, labels in uppercase, taps', (tester) async {
      var taps = 0;
      await pumpKz(
        tester,
        KzRoundButton(
          icon: KzIcons.ear,
          label: 'Hear',
          onPressed: () => taps++,
        ),
      );
      expect(find.text('HEAR'), findsOneWidget);
      final circle = find.byKey(const ValueKey('kz-round-button-circle'));
      expect(tester.getSize(circle), const Size.square(56));
      await tester.tap(find.byType(KzRoundButton));
      expect(taps, 1);
    });
  });

  group('KzBatteryIndicator', () {
    testWidgets('renders nothing for a null level', (tester) async {
      await pumpKz(tester, const KzBatteryIndicator(label: 'Case'));
      expect(find.text('Case'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows label, level and a proportional bar', (tester) async {
      await pumpKz(tester, const KzBatteryIndicator(label: 'L', level: 72));
      expect(find.text('L'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      final bar = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(bar.widthFactor, closeTo(0.72, 0.001));
    });

    testWidgets('critical level carries an icon and the critical color', (
      tester,
    ) async {
      await pumpKz(tester, const KzBatteryIndicator(label: 'R', level: 20));
      final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
      expect(icon.icon, KzIcons.batteryLow);
      expect(icon.color, KzPalette.criticalDark);
      final text = tester.widget<Text>(find.text('20%'));
      expect(text.style!.color, KzPalette.criticalDark);
    });

    testWidgets('healthy level is neutral with no icon', (tester) async {
      await pumpKz(tester, const KzBatteryIndicator(label: 'R', level: 21));
      expect(find.byType(HugeIcon), findsNothing);
      final text = tester.widget<Text>(find.text('21%'));
      expect(text.style!.color, KzPalette.paper);
    });

    testWidgets('charging shows the charging icon in success color', (
      tester,
    ) async {
      await pumpKz(
        tester,
        const KzBatteryIndicator(label: 'L', level: 50, charging: true),
      );
      final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
      expect(icon.icon, KzIcons.batteryCharging);
      expect(icon.color, KzPalette.successDark);
    });
  });

  group('KzNavPill', () {
    final items = [
      const KzNavItem(icon: KzIcons.home, label: 'Home'),
      const KzNavItem(icon: KzIcons.eq, label: 'EQ'),
      const KzNavItem(icon: KzIcons.tap, label: 'Touch'),
    ];

    testWidgets('only the selected item shows its label', (tester) async {
      await pumpKz(
        tester,
        KzNavPill(items: items, selectedIndex: 1, onSelected: (_) {}),
      );
      expect(find.text('EQ'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Touch'), findsNothing);
    });

    testWidgets('tapping an item selects it', (tester) async {
      int? selected;
      await pumpKz(
        tester,
        KzNavPill(
          items: items,
          selectedIndex: 0,
          onSelected: (i) => selected = i,
        ),
      );
      await tester.tap(find.bySemanticsLabel('Touch'));
      expect(selected, 2);
    });

    testWidgets('more than four items is rejected', (tester) async {
      final many = List.generate(
        5,
        (i) => KzNavItem(icon: KzIcons.home, label: 'Item $i'),
      );
      await pumpKz(
        tester,
        KzNavPill(items: many, selectedIndex: 0, onSelected: (_) {}),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('KzSection and KzListRow', () {
    testWidgets('section shows an uppercase title and its content', (
      tester,
    ) async {
      await pumpKz(
        tester,
        const KzSection(title: 'Appearance', child: Text('content')),
      );
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('list row shows title, subtitle, trailing and taps', (
      tester,
    ) async {
      var taps = 0;
      await pumpKz(
        tester,
        KzListRow(
          title: 'Single tap',
          subtitle: 'Play or pause',
          trailing: const Text('>'),
          onTap: () => taps++,
        ),
      );
      expect(find.text('Single tap'), findsOneWidget);
      expect(find.text('Play or pause'), findsOneWidget);
      expect(find.text('>'), findsOneWidget);
      await tester.tap(find.text('Single tap'));
      expect(taps, 1);
    });
  });

  group('KzPage', () {
    testWidgets('shows its child over the ambient background', (tester) async {
      await pumpKz(
        tester,
        const SizedBox(
          width: 300,
          height: 600,
          child: KzPage(child: Text('page')),
        ),
      );
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('lifts content above the keyboard', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpKz(
        tester,
        const SizedBox(
          width: 400,
          height: 800,
          child: KzPage(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text('bottom'),
            ),
          ),
        ),
      );
      final before = tester.getBottomLeft(find.text('bottom')).dy;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final after = tester.getBottomLeft(find.text('bottom')).dy;
      expect(before - after, closeTo(300, 1));
    });
  });
}
