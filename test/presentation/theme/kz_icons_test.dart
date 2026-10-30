import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kz_buds/presentation/theme/kz_icons.dart';
import 'package:kz_buds/presentation/theme/kz_palette.dart';

import '../../support/pump_kz.dart';

HugeIcon hugeIcon(WidgetTester tester) =>
    tester.widget<HugeIcon>(find.byType(HugeIcon));

void main() {
  test('exposes the semantic icon set', () {
    final all = {
      'ear': KzIcons.ear,
      'earRings': KzIcons.earRings,
      'earbuds': KzIcons.earbuds,
      'tap': KzIcons.tap,
      'gameMode': KzIcons.gameMode,
      'eq': KzIcons.eq,
      'batteryEmpty': KzIcons.batteryEmpty,
      'batteryLow': KzIcons.batteryLow,
      'batteryMedium': KzIcons.batteryMedium,
      'batteryFull': KzIcons.batteryFull,
      'batteryCharging': KzIcons.batteryCharging,
      'trash': KzIcons.trash,
      'edit': KzIcons.edit,
      'help': KzIcons.help,
      'update': KzIcons.update,
      'menu': KzIcons.menu,
      'back': KzIcons.back,
      'close': KzIcons.close,
      'bluetooth': KzIcons.bluetooth,
      'settings': KzIcons.settings,
      'home': KzIcons.home,
    };
    for (final entry in all.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
    }
  });

  testWidgets('draws with stroke 1.5 by default', (tester) async {
    await pumpKz(tester, const KzIcon(KzIcons.ear));
    expect(hugeIcon(tester).strokeWidth, 1.5);
    expect(hugeIcon(tester).icon, KzIcons.ear);
  });

  testWidgets('draws with stroke 2.0 when emphasized', (tester) async {
    await pumpKz(tester, const KzIcon(KzIcons.ear, emphasized: true));
    expect(hugeIcon(tester).strokeWidth, 2.0);
  });

  testWidgets('takes color and size from the IconTheme', (tester) async {
    await pumpKz(tester, const KzIcon(KzIcons.tap));
    expect(hugeIcon(tester).color, KzPalette.inkText);
    expect(hugeIcon(tester).size, 20);
  });

  testWidgets('explicit color and size win', (tester) async {
    await pumpKz(
      tester,
      const KzIcon(KzIcons.tap, size: 32, color: KzPalette.copperDark),
    );
    expect(hugeIcon(tester).color, KzPalette.copperDark);
    expect(hugeIcon(tester).size, 32);
  });
}
