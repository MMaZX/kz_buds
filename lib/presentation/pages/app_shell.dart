import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../providers/earbuds_providers.dart';
import '../providers/navigation_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../widgets/kz_nav_pill.dart';
import 'device_home_page.dart';
import 'eq_page.dart';
import 'settings_page.dart';
import 'touch_page.dart';

/// Hosts the top-level destinations and the floating nav. A destination
/// exists only if the device reports its capability; with a single
/// destination there is no nav.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  /// Space pages reserve at the bottom so content clears the floating nav.
  static const navClearance = 112.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities =
        ref.watch(capabilitiesProvider).value ?? const <Capability>{};
    final tabs = [
      KzTab.home,
      if (capabilities.contains(Capability.eq)) KzTab.eq,
      if (capabilities.contains(Capability.buttonRemap)) KzTab.touch,
      KzTab.settings,
    ];
    final selected = ref.watch(selectedTabProvider);
    final current = tabs.contains(selected) ? selected : KzTab.home;

    final page = switch (current) {
      KzTab.home => const DeviceHomePage(),
      KzTab.eq => const EqPage(),
      KzTab.touch => const TouchPage(),
      KzTab.settings => const SettingsPage(),
    };
    if (tabs.length < 2) return page;

    return Stack(
      children: [
        Positioned.fill(child: page),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: KzSpace.s16),
              child: KzNavPill(
                items: [
                  for (final tab in tabs)
                    switch (tab) {
                      KzTab.home => const KzNavItem(
                        icon: KzIcons.home,
                        label: 'Home',
                      ),
                      KzTab.eq => const KzNavItem(
                        icon: KzIcons.eq,
                        label: 'Equalizer',
                      ),
                      KzTab.touch => const KzNavItem(
                        icon: KzIcons.tap,
                        label: 'Touch',
                      ),
                      KzTab.settings => const KzNavItem(
                        icon: KzIcons.settings,
                        label: 'Settings',
                      ),
                    },
                ],
                selectedIndex: tabs.indexOf(current),
                onSelected: (index) =>
                    ref.read(selectedTabProvider.notifier).select(tabs[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
