import 'package:flutter/widgets.dart';

import '../theme/kz_metrics.dart';
import '../theme/kz_motion.dart';
import '../theme/kz_theme.dart';

/// Shared interaction shell: press scale, keyboard focus ring, hover cursor,
/// disabled look and button semantics. Disabled when [onPressed] is null.
class KzPressable extends StatefulWidget {
  const KzPressable({
    required this.child,
    required this.borderRadius,
    this.onPressed,
    this.semanticsLabel,
    this.selected,
    this.toggled,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final bool? selected;
  final bool? toggled;

  @override
  State<KzPressable> createState() => _KzPressableState();
}

class _KzPressableState extends State<KzPressable> {
  bool _pressed = false;
  bool _focused = false;

  static const _disabledOpacity = 0.4;
  static const _pressedScale = 0.97;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final theme = KzTheme.of(context);
    final motion = KzMotion.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticsLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? _pressedScale : 1,
            duration: motion.press,
            curve: KzMotion.pressCurve,
            child: Opacity(
              opacity: enabled ? 1 : _disabledOpacity,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                  border: _focused
                      ? Border.all(
                          color: theme.colors.brand,
                          width: KzStroke.focusRing,
                        )
                      : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
