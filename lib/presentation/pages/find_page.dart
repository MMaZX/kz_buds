import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/find_target.dart';
import '../providers/find_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_block_button.dart';
import '../widgets/kz_card.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_round_button.dart';

class FindPage extends ConsumerWidget {
  const FindPage({super.key});

  /// Firmware limit (odd/tasks/carol-pro-bluetooth.md L36): only the earbud
  /// holding the link rings alone, so both is the default.
  static const singleSideNote =
      'Left or right alone may not sound: the firmware only rings the '
      'earbud that holds the connection.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = KzTheme.of(context);
    final playing = ref.watch(findSoundProvider);
    final notifier = ref.read(findSoundProvider.notifier);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            KzPageHeader(
              title: 'Find my buds',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: KzSpace.s32),
            KzCard(
              radius: KzRadii.xl,
              padding: const EdgeInsets.all(KzSpace.s24),
              child: Column(
                children: [
                  KzRoundButton(
                    icon: KzIcons.earbuds,
                    label: 'Both',
                    semanticsLabel: 'Play on both earbuds',
                    selected: playing == FindTarget.both,
                    onPressed: () => notifier.play(FindTarget.both),
                  ),
                  const SizedBox(height: KzSpace.s24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final side in [FindTarget.left, FindTarget.right])
                        KzRoundButton(
                          icon: KzIcons.ear,
                          label: side == FindTarget.left ? 'Left' : 'Right',
                          semanticsLabel: 'Play on ${side.name} earbud',
                          selected: playing == side,
                          onPressed: () => notifier.play(side),
                        ),
                    ],
                  ),
                  const SizedBox(height: KzSpace.s16),
                  Text(
                    singleSideNote,
                    textAlign: TextAlign.center,
                    style: theme.typography.caption.copyWith(
                      color: theme.scheme.mutedForeground,
                    ),
                  ),
                  if (playing != null) ...[
                    const SizedBox(height: KzSpace.s24),
                    KzBlockButton(label: 'Stop', onPressed: notifier.stop),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KzSpace.s16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KzIcon(KzIcons.warning, size: 16, color: theme.colors.warning),
                const SizedBox(width: KzSpace.s8),
                Expanded(
                  child: Text(
                    'Remove the earbuds before playing a sound.',
                    style: theme.typography.caption.copyWith(
                      color: theme.colors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KzSpace.s32),
          ],
        ),
      ),
    );
  }
}
