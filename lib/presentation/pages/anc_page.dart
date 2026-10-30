import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/anc_mode.dart';
import '../providers/earbuds_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_anc_rings.dart';
import '../widgets/kz_list_row.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_section.dart';

class AncPage extends ConsumerWidget {
  const AncPage({super.key});

  static const _modes = [
    (AncMode.off, 'Off', 'No processing'),
    (AncMode.noiseCancelling, 'Noise cancelling', 'Reduces outside noise'),
    (AncMode.ambient, 'Ambient', 'Lets outside sound in'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = KzTheme.of(context);
    final mode = ref.watch(ancModeProvider).value ?? AncMode.off;
    final port = ref.read(earbudsPortProvider);

    return KzPage(
      glowScale: switch (mode) {
        AncMode.noiseCancelling => 0.85,
        AncMode.ambient => 1.15,
        AncMode.off => 1,
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            KzPageHeader(
              title: 'Noise control',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: KzSpace.s32),
            Center(
              child: KzAncRings(
                mode: mode,
                size: 120,
                color: mode == AncMode.off
                    ? theme.scheme.mutedForeground
                    : theme.colors.brand,
              ),
            ),
            const SizedBox(height: KzSpace.s32),
            KzSection(
              title: 'Mode',
              child: Column(
                children: [
                  for (final (value, title, subtitle) in _modes)
                    KzListRow(
                      title: title,
                      subtitle: subtitle,
                      trailing: mode == value
                          ? const KzIcon(KzIcons.check, emphasized: true)
                          : null,
                      onTap: () => port.setAncMode(value),
                    ),
                ],
              ),
            ),
            const SizedBox(height: KzSpace.s32),
          ],
        ),
      ),
    );
  }
}
