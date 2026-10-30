import 'package:flutter/widgets.dart';

import 'kz_theme.dart';

/// The app background: one flat color with a faint 1 px grid every 72 px, like
/// graph paper. No gradient, no glow.
class KzPaperBackground extends StatelessWidget {
  const KzPaperBackground({required this.child, super.key});

  final Widget child;

  static const spacing = 72.0;

  /// Offsets of the grid lines along an axis of length [extent].
  static List<double> lineOffsets(double extent) => [
    for (var offset = 0.0; offset < extent; offset += spacing) offset,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);

    return CustomPaint(
      painter: _PaperPainter(
        background: theme.scheme.background,
        grid: theme.grid,
      ),
      child: child,
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({required this.background, required this.grid});

  final Color background;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final paint = Paint()..color = grid;
    for (final x in KzPaperBackground.lineOffsets(size.width)) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);
    }
    for (final y in KzPaperBackground.lineOffsets(size.height)) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.background != background || old.grid != grid;
}
