import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../../domain/entities/anc_mode.dart';
import '../theme/kz_theme.dart';

/// Noise-control mode glyph from the Lucide icon font shipped with shadcn_ui.
class KzAncIcon extends StatelessWidget {
  const KzAncIcon({required this.mode, this.size = 24, this.color, super.key});

  final AncMode mode;
  final double size;
  final Color? color;

  /// The 300 weight matches the app's thinner icon stroke.
  static IconData iconFor(AncMode mode) => switch (mode) {
    AncMode.noiseCancelling => LucideIcons.earOff300,
    AncMode.ambient => LucideIcons.ear300,
    AncMode.off => LucideIcons.headphones300,
  };

  static String labelFor(AncMode mode) => switch (mode) {
    AncMode.off => 'Off',
    AncMode.noiseCancelling => 'Noise cancelling',
    AncMode.ambient => 'Ambient',
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconFor(mode),
      size: size,
      color: color ?? KzTheme.of(context).scheme.foreground,
      semanticLabel: labelFor(mode),
    );
  }
}
