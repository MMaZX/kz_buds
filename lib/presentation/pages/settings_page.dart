import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/theme_providers.dart';
import '../providers/visual_settings_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../theme/kz_theme_preference.dart';
import '../widgets/kz_chip.dart';
import '../widgets/kz_list_row.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_section.dart';
import 'about_page.dart';
import 'app_shell.dart';
import 'kz_route.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _themeLabels = {
    KzThemePreference.system: 'System',
    KzThemePreference.light: 'Light',
    KzThemePreference.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(themePreferenceProvider);
    final settings = ref.watch(visualSettingsProvider);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            const KzPageHeader(title: 'Settings'),
            const SizedBox(height: KzSpace.s24),
            KzSection(
              title: 'Appearance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: KzSpace.s8,
                    runSpacing: KzSpace.s8,
                    children: [
                      for (final entry in _themeLabels.entries)
                        KzChip(
                          label: entry.value,
                          selected: preference == entry.key,
                          onPressed: () => ref
                              .read(themePreferenceProvider.notifier)
                              .set(entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: KzSpace.s8),
                  KzListRow(
                    title: 'Reduce transparency',
                    subtitle: 'Replaces blur with solid surfaces',
                    trailing: ShadSwitch(
                      value: settings.reduceTransparency,
                      onChanged: ref
                          .read(visualSettingsProvider.notifier)
                          .setReduceTransparency,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KzSpace.s24),
            KzSection(
              title: 'About',
              child: KzListRow(
                title: 'About KZ Buds',
                trailing: KzIcon(
                  KzIcons.forward,
                  color: KzTheme.of(context).scheme.mutedForeground,
                ),
                onTap: () =>
                    Navigator.of(context)
                        .push(kzRoute<void>(context, (_) => const AboutPage())),
              ),
            ),
            const SizedBox(height: AppShell.navClearance),
          ],
        ),
      ),
    );
  }
}
