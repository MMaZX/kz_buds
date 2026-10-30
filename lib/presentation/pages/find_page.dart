import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../domain/entities/bud.dart';
import '../providers/find_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_card.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_round_button.dart';

class FindPage extends ConsumerWidget {
  const FindPage({super.key});

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final bud in Bud.values)
                        KzRoundButton(
                          icon: KzIcons.ear,
                          label: bud == Bud.left ? 'Left' : 'Right',
                          semanticsLabel: 'Play on ${bud.name} earbud',
                          selected: playing == bud,
                          onPressed: () => notifier.play(bud),
                        ),
                    ],
                  ),
                  if (playing != null) ...[
                    const SizedBox(height: KzSpace.s24),
                    ShadButton.destructive(
                      onPressed: notifier.stop,
                      leading: const KzIcon(KzIcons.close, size: 16),
                      child: const Text('Stop'),
                    ),
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
