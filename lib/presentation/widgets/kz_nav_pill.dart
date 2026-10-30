import 'package:flutter/widgets.dart';

import '../theme/kz_glass.dart';
import '../theme/kz_glass_theme.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import 'kz_pressable.dart';

class KzNavItem {
  const KzNavItem({required this.icon, required this.label});

  final KzIconData icon;
  final String label;
}

/// Floating glass navigation. The selected item shows icon and label in a
/// lighter pill; the others show only their icon. Four items at most.
class KzNavPill extends StatelessWidget {
  const KzNavPill({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<KzNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const maxItems = 4;
  static const maxWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    assert(items.length <= maxItems, 'KzNavPill holds at most $maxItems items');
    final theme = KzTheme.of(context);
    final radius = BorderRadius.circular(KzRadii.pill);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: KzGlass(
        level: KzGlassLevel.chrome,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(KzSpace.s4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < items.length; i++)
                KzPressable(
                  borderRadius: radius,
                  selected: i == selectedIndex,
                  semanticsLabel: items[i].label,
                  onPressed: () => onSelected(i),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? theme.glass.subtle.fill
                          : null,
                      borderRadius: radius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KzSpace.s16,
                        vertical: KzSpace.s12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KzIcon(
                            items[i].icon,
                            emphasized: i == selectedIndex,
                            color: i == selectedIndex
                                ? theme.scheme.foreground
                                : theme.scheme.mutedForeground,
                          ),
                          if (i == selectedIndex) ...[
                            const SizedBox(width: KzSpace.s8),
                            ExcludeSemantics(
                              child: Text(
                                items[i].label,
                                style: theme.typography.label.copyWith(
                                  color: theme.scheme.foreground,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
