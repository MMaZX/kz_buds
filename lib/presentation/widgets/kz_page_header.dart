import 'package:flutter/widgets.dart';

import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

class KzPageHeader extends StatelessWidget {
  const KzPageHeader({required this.title, this.onBack, super.key});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final back = onBack;

    return Row(
      children: [
        if (back != null) ...[
          KzPressable(
            borderRadius: BorderRadius.circular(KzRadii.pill),
            semanticsLabel: 'Back',
            onPressed: back,
            child: const Padding(
              padding: EdgeInsets.all(KzSpace.s8),
              child: KzIcon(KzIcons.back),
            ),
          ),
          const SizedBox(width: KzSpace.s8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.typography.h1.copyWith(color: theme.scheme.foreground),
          ),
        ),
      ],
    );
  }
}
