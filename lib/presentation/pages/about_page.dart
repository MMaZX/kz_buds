import 'package:flutter/widgets.dart';

import '../app_info.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_list_row.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_section.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _credits = [
    ('Inter', 'SIL Open Font License 1.1'),
    ('shadcn_ui', 'MIT License'),
    ('hugeicons', 'MIT License'),
    ('flutter_riverpod', 'MIT License'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            KzPageHeader(
              title: 'About',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: KzSpace.s24),
            Text(
              'KZ Buds',
              style: theme.typography.title.copyWith(
                color: theme.scheme.foreground,
              ),
            ),
            const SizedBox(height: KzSpace.s4),
            Text(
              'Version $kAppVersion',
              style: theme.typography.caption.copyWith(
                color: theme.scheme.mutedForeground,
              ),
            ),
            const SizedBox(height: KzSpace.s24),
            KzSection(
              title: 'Credits',
              child: Column(
                children: [
                  for (final (name, license) in _credits)
                    KzListRow(title: name, subtitle: license),
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
