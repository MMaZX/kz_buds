import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/kz_metrics.dart';
import '../../theme/kz_motion.dart';
import '../../theme/kz_theme.dart';
import 'kz_equalizer_controller.dart';

/// `+2.0`, `0.0`, `-3.5`.
String formatEqGain(double gain) {
  final text = gain.abs().toStringAsFixed(1);
  if (gain > 0) return '+$text';
  if (gain < 0) return '-$text';
  return text;
}

/// `31`, `500`, `1K`, `2.5K`, `16K`.
String formatEqFrequency(num hz) {
  if (hz < 1000) return hz.round().toString();
  final k = hz / 1000;
  return k == k.roundToDouble() ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
}

/// Position of [hz] on the 20 Hz to 20 kHz log axis, 0 to 1.
double eqFrequencyFraction(num hz) {
  const lo = KzEqualizerGeometry.minHz;
  const hi = KzEqualizerGeometry.maxHz;
  return (math.log(hz.clamp(lo, hi)) - math.log(lo)) /
      (math.log(hi) - math.log(lo));
}

/// Graphic equalizer: a response graph over one pill slider per band.
///
/// Built like a desktop control (see the Chicago design language): this
/// public widget owns focus, keyboard, mouse and semantics, and hands the
/// labels as child slots to a private render object that lays them out,
/// paints the graph and the tracks, and runs the tap and drag gestures.
///
/// Keys: Left/Right select a band, Up/Down move its gain one step.
class KzEqualizer extends StatefulWidget {
  const KzEqualizer({
    required this.controller,
    required this.frequencies,
    super.key,
  });

  final KzEqualizerController controller;

  /// Center of each band in Hz, one per controller band.
  final List<num> frequencies;

  /// Grid lines and axis labels of the graph, in Hz.
  static const axis = [20, 50, 100, 500, 1000, 5000, 10000, 20000];

  @override
  State<KzEqualizer> createState() => KzEqualizerState();
}

/// Public only so tests can read [shownGains].
class KzEqualizerState extends State<KzEqualizer>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode(debugLabel: 'KzEqualizer');

  /// Glides the drawn gains to the controller's: every change starts a new
  /// glide from what is on screen, so a drag never jumps.
  late final AnimationController _glide = AnimationController(vsync: this)
    ..value = 1;
  late List<double> _from;
  late List<double> _to;

  KzEqualizerController get _eq => widget.controller;

  /// The gains as drawn right now, between the last start and the target.
  @visibleForTesting
  List<double> get shownGains {
    final t = KzMotion.valueCurve.transform(_glide.value);
    return [
      for (var i = 0; i < _to.length; i++)
        i < _from.length ? _from[i] + (_to[i] - _from[i]) * t : _to[i],
    ];
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _from = _to = _eq.gains;
    _eq.addListener(_onGains);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _glide.duration = KzMotion.of(context).value;
  }

  @override
  void didUpdateWidget(KzEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onGains);
      widget.controller.addListener(_onGains);
      _onGains();
    }
  }

  @override
  void dispose() {
    _eq.removeListener(_onGains);
    _glide.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  void _onGains() {
    final next = _eq.gains;
    if (listEquals(next, _to)) return;
    _from = shownGains;
    _to = next;
    _glide.forward(from: 0);
  }

  void _onFocusChange() => setState(() {});

  void _press(int band) {
    _eq.select(band);
    _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _eq.select(_eq.selected - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _eq.select(_eq.selected + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _eq.nudge(_eq.selected, 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _eq.nudge(_eq.selected, -1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.frequencies.length == _eq.bandCount,
      'needs one frequency per band',
    );
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final axisStyle = theme.typography.caption.copyWith(
      color: scheme.mutedForeground,
    );
    final scaleStyle = theme.typography.label.copyWith(
      color: scheme.foreground,
    );

    return ListenableBuilder(
      listenable: _eq,
      builder: (context, _) {
        final band = _eq.selected;
        final gain = _eq.gains[band];
        String dB(double value) => '${formatEqGain(_eq.snap(value))} dB';

        return Semantics(
          container: true,
          slider: true,
          label: 'Band ${formatEqFrequency(widget.frequencies[band])}Hz',
          value: dB(gain),
          increasedValue: dB(gain + _eq.step),
          decreasedValue: dB(gain - _eq.step),
          onIncrease: () => _eq.nudge(band, 1),
          onDecrease: () => _eq.nudge(band, -1),
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: _onKey,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: _RawEqualizer(
                    data: _EqPaintData(
                      gains: _eq.gains,
                      shownGains: () => shownGains,
                      glide: _glide,
                      frequencies: widget.frequencies,
                      min: _eq.min,
                      max: _eq.max,
                      zero: _eq.zero,
                      selected: band,
                      focused: _focusNode.hasFocus,
                      panel: scheme.secondary,
                      line: scheme.border,
                      point: scheme.mutedForeground,
                      thumb: scheme.foreground,
                      accent: theme.colors.brand,
                    ),
                    onSelect: _press,
                    onSetGain: (band, gain) {
                      _press(band);
                      _eq
                        ..setGain(band, gain)
                        ..commit();
                    },
                    onDragGain: (band, gain) {
                      _press(band);
                      _eq.setGain(band, gain);
                    },
                    onDragEnd: _eq.commit,
                    axisLabels: [
                      for (final hz in KzEqualizer.axis)
                        Text(formatEqFrequency(hz), style: axisStyle),
                    ],
                    scaleLabels: [
                      for (var side = 0; side < 2; side++)
                        for (final mark in const ['+', '0', '-'])
                          Text(mark, style: scaleStyle),
                    ],
                    valueLabel: Text(
                      formatEqGain(gain),
                      style: theme.typography.label.copyWith(
                        color: theme.colors.brand,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where everything sits for a given size; shared by layout, painting,
/// hit testing and tests.
class KzEqualizerGeometry {
  KzEqualizerGeometry(this.size, this.bandCount);

  final Size size;
  final int bandCount;

  static const preferredWidth = 360.0;
  static const graphHeight = 128.0;
  static const axisHeight = 28.0;
  static const gap = 20.0;
  static const sliderHeight = 232.0;
  static const valueHeight = 28.0;
  static const height =
      graphHeight + axisHeight + gap + sliderHeight + valueHeight;

  /// Width of each scale column ("+", "0", "-") beside the tracks.
  static const side = 28.0;
  static const maxTrackWidth = 28.0;
  static const minSlot = 20.0;
  static const graphInset = 16.0;
  static const minHz = 20.0;
  static const maxHz = 20000.0;

  Rect get graph => Rect.fromLTWH(0, 0, size.width, graphHeight);

  Rect get sliders => Rect.fromLTWH(
    side,
    graphHeight + axisHeight + gap,
    math.max(0, size.width - 2 * side),
    sliderHeight,
  );

  double get slot => sliders.width / bandCount;

  double get trackWidth => math.min(maxTrackWidth, slot * 0.65);

  Rect track(int band) => Rect.fromCenter(
    center: Offset(sliders.left + (band + 0.5) * slot, sliders.center.dy),
    width: trackWidth,
    height: sliderHeight,
  );

  double get thumbRadius => trackWidth * 0.4;

  double get _travelTop => sliders.top + trackWidth / 2;

  double get _travelBottom => sliders.bottom - trackWidth / 2;

  /// y of a value at [fraction] of the range (0 bottom, 1 top).
  double yOfFraction(double fraction) =>
      _travelBottom - fraction * (_travelBottom - _travelTop);

  double fractionAtY(double y) =>
      ((_travelBottom - y) / (_travelBottom - _travelTop)).clamp(0.0, 1.0);

  int? bandAtX(double x) {
    final i = ((x - sliders.left) / slot).floor();
    return i >= 0 && i < bandCount ? i : null;
  }

  double graphXOf(num hz) =>
      graph.left +
      graphInset +
      eqFrequencyFraction(hz) * (graph.width - 2 * graphInset);

  double graphYOfFraction(double fraction) =>
      graph.bottom - graphInset - fraction * (graph.height - 2 * graphInset);
}

class _EqPaintData {
  const _EqPaintData({
    required this.gains,
    required this.shownGains,
    required this.glide,
    required this.frequencies,
    required this.min,
    required this.max,
    required this.zero,
    required this.selected,
    required this.focused,
    required this.panel,
    required this.line,
    required this.point,
    required this.thumb,
    required this.accent,
  });

  /// Target gains; [shownGains] gives the ones on screen during a glide.
  final List<double> gains;
  final ValueGetter<List<double>> shownGains;

  /// Ticks while the gains glide; the render object repaints on it.
  final Listenable glide;
  final List<num> frequencies;
  final double min;
  final double max;
  final double zero;
  final int selected;
  final bool focused;
  final Color panel;
  final Color line;
  final Color point;
  final Color thumb;
  final Color accent;

  double fractionOf(double gain) => (gain - min) / (max - min);
}

enum _Group { axis, scale, value }

@immutable
class _Slot {
  const _Slot(this.group, this.index);

  final _Group group;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is _Slot && other.group == group && other.index == index;

  @override
  int get hashCode => Object.hash(group, index);
}

class _RawEqualizer extends RenderObjectWidget {
  const _RawEqualizer({
    required this.data,
    required this.onSelect,
    required this.onSetGain,
    required this.onDragGain,
    required this.onDragEnd,
    required this.axisLabels,
    required this.scaleLabels,
    required this.valueLabel,
  });

  final _EqPaintData data;
  final ValueChanged<int> onSelect;
  final void Function(int band, double gain) onSetGain;
  final void Function(int band, double gain) onDragGain;
  final VoidCallback onDragEnd;

  /// One per [KzEqualizer.axis] entry.
  final List<Widget> axisLabels;

  /// "+", "0", "-" on the left, then the same on the right.
  final List<Widget> scaleLabels;
  final Widget valueLabel;

  @override
  RenderObjectElement createElement() => _EqualizerElement(this);

  @override
  _RenderEqualizer createRenderObject(BuildContext context) =>
      _RenderEqualizer(data)..callbacksFrom(this);

  @override
  void updateRenderObject(BuildContext context, _RenderEqualizer renderObject) {
    renderObject
      ..data = data
      ..callbacksFrom(this);
  }
}

/// Keeps one child element per label slot and hands their render boxes to
/// [_RenderEqualizer] by slot.
class _EqualizerElement extends RenderObjectElement {
  _EqualizerElement(_RawEqualizer super.widget);

  List<Element?> _axis = const [];
  List<Element?> _scale = const [];
  Element? _value;

  @override
  _RawEqualizer get widget => super.widget as _RawEqualizer;

  @override
  _RenderEqualizer get renderObject => super.renderObject as _RenderEqualizer;

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final child in [..._axis, ..._scale, _value]) {
      if (child != null) visitor(child);
    }
  }

  @override
  void forgetChild(Element child) {
    _axis = [for (final e in _axis) identical(e, child) ? null : e];
    _scale = [for (final e in _scale) identical(e, child) ? null : e];
    if (identical(_value, child)) _value = null;
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _updateChildren();
  }

  @override
  void update(_RawEqualizer newWidget) {
    super.update(newWidget);
    _updateChildren();
  }

  void _updateChildren() {
    _axis = _updateGroup(_axis, widget.axisLabels, _Group.axis);
    _scale = _updateGroup(_scale, widget.scaleLabels, _Group.scale);
    _value = updateChild(
      _value,
      widget.valueLabel,
      const _Slot(_Group.value, 0),
    );
  }

  List<Element?> _updateGroup(
    List<Element?> old,
    List<Widget> widgets,
    _Group group,
  ) {
    for (var i = widgets.length; i < old.length; i++) {
      updateChild(old[i], null, null);
    }
    return [
      for (var i = 0; i < widgets.length; i++)
        updateChild(
          i < old.length ? old[i] : null,
          widgets[i],
          _Slot(group, i),
        ),
    ];
  }

  @override
  void insertRenderObjectChild(RenderObject child, _Slot slot) =>
      renderObject.setChild(slot, child as RenderBox);

  @override
  void moveRenderObjectChild(RenderObject child, _Slot oldSlot, _Slot newSlot) {
    renderObject
      ..setChild(oldSlot, null)
      ..setChild(newSlot, child as RenderBox);
  }

  @override
  void removeRenderObjectChild(RenderObject child, _Slot slot) =>
      renderObject.setChild(slot, null);
}

class _RenderEqualizer extends RenderBox {
  _RenderEqualizer(this._data);

  final _children = <_Slot, RenderBox>{};

  _EqPaintData _data;

  /// Layout depends only on the selection and the range; everything else
  /// (gains, focus, colors) is paint.
  set data(_EqPaintData value) {
    final old = _data;
    _data = value;
    if (!identical(old.glide, value.glide) && attached) {
      old.glide.removeListener(markNeedsPaint);
      value.glide.addListener(markNeedsPaint);
    }
    if (old.selected != value.selected ||
        old.gains.length != value.gains.length ||
        old.min != value.min ||
        old.max != value.max ||
        old.zero != value.zero) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  late ValueChanged<int> _onSelect;
  late void Function(int band, double gain) _onSetGain;
  late void Function(int band, double gain) _onDragGain;
  late VoidCallback _onDragEnd;

  void callbacksFrom(_RawEqualizer widget) {
    _onSelect = widget.onSelect;
    _onSetGain = widget.onSetGain;
    _onDragGain = widget.onDragGain;
    _onDragEnd = widget.onDragEnd;
  }

  int get _bandCount => _data.gains.length;

  KzEqualizerGeometry get _geometry => KzEqualizerGeometry(size, _bandCount);

  // Children.

  void setChild(_Slot slot, RenderBox? child) {
    final old = _children.remove(slot);
    if (old != null) dropChild(old);
    if (child != null) {
      _children[slot] = child;
      adoptChild(child);
    }
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _data.glide.addListener(markNeedsPaint);
    for (final child in _children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    _data.glide.removeListener(markNeedsPaint);
    super.detach();
    for (final child in _children.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() => _children.values.forEach(redepthChild);

  @override
  void visitChildren(RenderObjectVisitor visitor) =>
      _children.values.forEach(visitor);

  // Layout.

  double _widthFor(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : KzEqualizerGeometry.preferredWidth;

  @override
  double computeMinIntrinsicWidth(double height) =>
      2 * KzEqualizerGeometry.side + _bandCount * KzEqualizerGeometry.minSlot;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(KzEqualizerGeometry.preferredWidth, computeMinIntrinsicWidth(0));

  @override
  double computeMinIntrinsicHeight(double width) => KzEqualizerGeometry.height;

  @override
  double computeMaxIntrinsicHeight(double width) => KzEqualizerGeometry.height;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => constraints
      .constrain(Size(_widthFor(constraints), KzEqualizerGeometry.height));

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
    final g = _geometry;
    final loose = BoxConstraints.loose(size);

    void place(_Slot slot, Offset center, {bool clampX = true}) {
      final child = _children[slot];
      if (child == null) return;
      child.layout(loose, parentUsesSize: true);
      final s = child.size;
      var dx = center.dx - s.width / 2;
      if (clampX) dx = dx.clamp(0.0, math.max(0.0, size.width - s.width));
      (child.parentData! as BoxParentData).offset = Offset(
        dx,
        center.dy - s.height / 2,
      );
    }

    final axisY =
        KzEqualizerGeometry.graphHeight + KzEqualizerGeometry.axisHeight / 2;
    for (var i = 0; i < KzEqualizer.axis.length; i++) {
      place(
        _Slot(_Group.axis, i),
        Offset(g.graphXOf(KzEqualizer.axis[i]), axisY),
      );
    }

    final marks = [1.0, _data.fractionOf(_data.zero), 0.0];
    for (var side = 0; side < 2; side++) {
      final x = side == 0
          ? KzEqualizerGeometry.side / 2
          : size.width - KzEqualizerGeometry.side / 2;
      for (var m = 0; m < marks.length; m++) {
        place(
          _Slot(_Group.scale, side * marks.length + m),
          Offset(x, g.yOfFraction(marks[m])),
        );
      }
    }

    place(
      const _Slot(_Group.value, 0),
      Offset(
        g.track(_data.selected).center.dx,
        g.sliders.bottom + KzEqualizerGeometry.valueHeight / 2,
      ),
    );
  }

  // Painting.

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    final g = _geometry;
    final shown = _data.shownGains();
    _paintGraph(canvas, g, shown);
    for (var i = 0; i < _bandCount; i++) {
      _paintTrack(canvas, g, i, shown);
    }
    canvas.restore();

    for (final child in _children.values) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  void _paintGraph(Canvas canvas, KzEqualizerGeometry g, List<double> shown) {
    final d = _data;
    final panel = RRect.fromRectAndRadius(
      g.graph,
      const Radius.circular(KzRadii.xl),
    );
    canvas
      ..save()
      ..clipRRect(panel)
      ..drawRRect(panel, Paint()..color = d.panel);

    final grid = Paint()
      ..color = d.line.withValues(alpha: 0.6)
      ..strokeWidth = KzStroke.hairline;
    for (final hz in KzEqualizer.axis) {
      final x = g.graphXOf(hz);
      canvas.drawLine(Offset(x, g.graph.top), Offset(x, g.graph.bottom), grid);
    }
    final zeroY = g.graphYOfFraction(d.fractionOf(d.zero));
    canvas.drawLine(
      Offset(g.graph.left, zeroY),
      Offset(g.graph.right, zeroY),
      grid,
    );

    final points = [
      for (var i = 0; i < _bandCount; i++)
        Offset(
          g.graphXOf(d.frequencies[i]),
          g.graphYOfFraction(d.fractionOf(shown[i])),
        ),
    ];
    final curve = _smoothPath(points);
    final left = g.graph.left + KzEqualizerGeometry.graphInset;
    final right = g.graph.right - KzEqualizerGeometry.graphInset;
    final line = Path()
      ..moveTo(left, points.first.dy)
      ..lineTo(points.first.dx, points.first.dy)
      ..addPath(curve, Offset.zero)
      ..lineTo(right, points.last.dy);
    final area = Path.from(line)
      ..lineTo(right, zeroY)
      ..lineTo(left, zeroY)
      ..close();
    canvas
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              d.thumb.withValues(alpha: 0.16),
              d.thumb.withValues(alpha: 0.02),
            ],
          ).createShader(g.graph),
      )
      ..drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = KzStroke.icon
          ..color = d.point.withValues(alpha: 0.7),
      );

    for (var i = 0; i < points.length; i++) {
      final selected = i == d.selected;
      canvas
        ..drawCircle(points[i], 6, Paint()..color = d.panel)
        ..drawCircle(
          points[i],
          selected ? 4.5 : 4,
          Paint()..color = selected ? d.accent : d.point,
        );
    }
    canvas.restore();
  }

  /// Catmull-Rom spline through [points] as cubic Béziers.
  static Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(points.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _paintTrack(
    Canvas canvas,
    KzEqualizerGeometry g,
    int band,
    List<double> shown,
  ) {
    final d = _data;
    final selected = band == d.selected;
    final rect = g.track(band);
    final pill = RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2));
    if (selected) {
      canvas.drawRRect(pill, Paint()..color = d.panel);
    } else {
      canvas.drawRRect(
        pill.deflate(KzStroke.hairline / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = KzStroke.hairline
          ..color = d.line,
      );
    }
    if (selected && d.focused) {
      canvas.drawRRect(
        pill.inflate(KzStroke.focusRing + 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = KzStroke.focusRing
          ..color = d.accent,
      );
    }

    final x = rect.center.dx;
    final zeroFraction = d.fractionOf(d.zero);
    final dotPaint = Paint()..color = d.line;
    for (final f in {
      0.0,
      zeroFraction / 2,
      zeroFraction,
      (1 + zeroFraction) / 2,
      1.0,
    }) {
      canvas.drawCircle(Offset(x, g.yOfFraction(f)), 3.5, dotPaint);
    }

    final valueY = g.yOfFraction(d.fractionOf(shown[band]));
    final zeroY = g.yOfFraction(zeroFraction);
    if (valueY != zeroY) {
      final fillWidth = g.thumbRadius * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - fillWidth / 2,
            math.min(valueY, zeroY) - fillWidth / 2,
            x + fillWidth / 2,
            math.max(valueY, zeroY) + fillWidth / 2,
          ),
          Radius.circular(fillWidth / 2),
        ),
        Paint()
          ..color = selected
              ? d.accent.withValues(alpha: 0.35)
              : d.thumb.withValues(alpha: 0.22),
      );
    }
    canvas.drawCircle(
      Offset(x, valueY),
      g.thumbRadius,
      Paint()..color = selected ? d.accent : d.thumb,
    );
  }

  // Gestures.

  late final _tap = TapGestureRecognizer(debugOwner: this)..onTapUp = _onTapUp;

  late final _drag = VerticalDragGestureRecognizer(debugOwner: this)
    ..onStart = _onDragStart
    ..onUpdate = _onDragUpdate
    ..onEnd = ((_) => _endDrag())
    ..onCancel = _endDrag;

  int? _dragBand;

  @override
  bool hitTestSelf(Offset position) => size.contains(position);

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent) return;
    _tap.addPointer(event);
    if (entry.localPosition.dy >= _geometry.sliders.top) {
      _drag.addPointer(event);
    }
  }

  double _gainAt(double y) =>
      _data.min + _geometry.fractionAtY(y) * (_data.max - _data.min);

  void _onTapUp(TapUpDetails details) {
    final p = globalToLocal(details.globalPosition);
    final g = _geometry;
    if (p.dy < g.sliders.top) {
      _onSelect(_nearestGraphBand(p.dx));
      return;
    }
    final band = g.bandAtX(p.dx);
    if (band != null) _onSetGain(band, _gainAt(p.dy));
  }

  int _nearestGraphBand(double x) {
    var best = 0;
    for (var i = 1; i < _bandCount; i++) {
      if ((_geometry.graphXOf(_data.frequencies[i]) - x).abs() <
          (_geometry.graphXOf(_data.frequencies[best]) - x).abs()) {
        best = i;
      }
    }
    return best;
  }

  void _onDragStart(DragStartDetails details) {
    _dragBand = _geometry.bandAtX(globalToLocal(details.globalPosition).dx);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final band = _dragBand;
    if (band == null) return;
    _onDragGain(band, _gainAt(globalToLocal(details.globalPosition).dy));
  }

  void _endDrag() {
    if (_dragBand == null) return;
    _dragBand = null;
    _onDragEnd();
  }

  @override
  void dispose() {
    _tap.dispose();
    _drag.dispose();
    super.dispose();
  }
}
