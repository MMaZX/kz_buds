import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../domain/entities/bud.dart';
import '../providers/remap_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../widgets/kz_chip.dart';
import '../widgets/kz_list_row.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_section.dart';
import 'app_shell.dart';

class TouchPage extends ConsumerStatefulWidget {
  const TouchPage({super.key});

  @override
  ConsumerState<TouchPage> createState() => _TouchPageState();
}

class _TouchPageState extends ConsumerState<TouchPage> {
  Bud _bud = Bud.left;

  static const _budLabels = {Bud.left: 'Left', Bud.right: 'Right'};
  static const _selectWidth = 168.0;

  @override
  Widget build(BuildContext context) {
    final remap = ref.watch(touchRemapProvider);
    final notifier = ref.read(touchRemapProvider.notifier);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            const KzPageHeader(title: 'Touch controls'),
            const SizedBox(height: KzSpace.s24),
            Wrap(
              spacing: KzSpace.s8,
              children: [
                for (final entry in _budLabels.entries)
                  KzChip(
                    label: entry.value,
                    selected: _bud == entry.key,
                    onPressed: () => setState(() => _bud = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: KzSpace.s24),
            KzSection(
              title: '${_budLabels[_bud]} earbud',
              child: Column(
                children: [
                  for (final gesture in TouchGesture.values)
                    KzListRow(
                      leading: KzIcons.tap,
                      title: gesture.label,
                      trailing: SizedBox(
                        width: _selectWidth,
                        child: ShadSelect<TouchAction>(
                          key: ValueKey('$_bud-$gesture'),
                          initialValue: remap.actionFor(_bud, gesture),
                          options: [
                            for (final action in TouchAction.values)
                              ShadOption(
                                value: action,
                                child: Text(action.label),
                              ),
                          ],
                          selectedOptionBuilder: (context, value) =>
                              Text(value.label),
                          onChanged: (value) {
                            if (value != null) {
                              notifier.setAction(_bud, gesture, value);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppShell.navClearance),
          ],
        ),
      ),
    );
  }
}
