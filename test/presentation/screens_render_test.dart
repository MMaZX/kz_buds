import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/data/fake/fake_earbuds_adapter.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/link_state.dart';
import 'package:kz_buds/presentation/theme/kz_theme_preference.dart';

import '../support/pump_home.dart';

/// S11: every screen renders in dark and light for the capability states.
void main() {
  final states = <String, FakeEarbudsAdapter Function()>{
    'all capabilities': () =>
        FakeEarbudsAdapter(capabilities: Capability.values.toSet()),
    'no capabilities': () => FakeEarbudsAdapter(capabilities: {}),
    'case null': () => FakeEarbudsAdapter(
      capabilities: Capability.values.toSet(),
      initialBattery: const BatteryStatus(left: 30, right: 20),
    ),
    'disconnected': () => FakeEarbudsAdapter(
      capabilities: Capability.values.toSet(),
      initialLinkState: LinkState.disconnected,
    ),
  };
  final screens = <String, Future<void> Function(WidgetTester)>{
    'home': (t) async {},
    'equalizer': (t) async => t.tap(find.bySemanticsLabel('Equalizer')),
    'touch': (t) async => t.tap(find.bySemanticsLabel('Touch')),
    'settings': (t) async => t.tap(find.bySemanticsLabel('Settings')),
    'noise control': (t) async =>
        t.tap(find.bySemanticsLabel('Noise control details')),
    'find': (t) async => t.tap(find.bySemanticsLabel('Find my buds')),
  };

  for (final preference in [KzThemePreference.dark, KzThemePreference.light]) {
    for (final state in states.entries) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} / ${state.key} / ${preference.name}', (
          tester,
        ) async {
          await pumpApp(tester, state.value(), preference: preference);
          final target = screen.key;
          final reachable = switch (target) {
            'noise control' || 'find' =>
              state.key != 'no capabilities' && state.key != 'disconnected',
            'equalizer' || 'touch' => state.key != 'no capabilities',
            _ => true,
          };
          if (!reachable) return;
          await screen.value(tester);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
