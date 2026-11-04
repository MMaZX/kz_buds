import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../domain/entities/eq_settings.dart';
import '../providers/earbuds_providers.dart';
import '../providers/eq_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/equalizer/kz_equalizer.dart';
import '../widgets/equalizer/kz_equalizer_controller.dart';
import '../widgets/kz_block_button.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_page_header.dart';
import '../widgets/kz_readout_pill.dart';
import '../widgets/kz_round_button.dart';
import 'app_shell.dart';

class EqPage extends ConsumerWidget {
  const EqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(eqProfileProvider);
    final settings = ref.watch(eqSettingsProvider).value;
    final theme = KzTheme.of(context);

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            const KzPageHeader(title: 'Equalizer'),
            const SizedBox(height: KzSpace.s24),
            switch (profile.value) {
              final EqProfile p when settings != null => _EqEditor(
                key: ValueKey(p),
                profile: p,
                initial: settings,
              ),
              EqProfile() => const SizedBox.shrink(),
              null when profile.isLoading => const SizedBox.shrink(),
              null => Text(
                'The equalizer is not available on these earbuds.',
                style: theme.typography.body.copyWith(
                  color: theme.scheme.mutedForeground,
                ),
              ),
            },
            const SizedBox(height: AppShell.navClearance),
          ],
        ),
      ),
    );
  }
}

/// Simple picks one of the device presets; Advanced edits the custom mode.
enum _EqTab { simple, advanced }

/// Edits one profile. The equalizer owns selection, live drags and undo;
/// every committed change is sent to the earbuds: a preset with its own
/// mode, anything else as the custom mode. Settings that arrive from the
/// earbuds become the new baseline.
class _EqEditor extends ConsumerStatefulWidget {
  const _EqEditor({required this.profile, required this.initial, super.key});

  final EqProfile profile;

  /// What the earbuds held when the editor opened.
  final EqSettings initial;

  @override
  ConsumerState<_EqEditor> createState() => _EqEditorState();
}

class _EqEditorState extends ConsumerState<_EqEditor> {
  late final KzEqualizerController _eq;

  /// What the earbuds hold, as far as this page knows.
  late EqSettings _device;

  /// Last committed gains seen, so live edits and the notification that
  /// precedes a commit do not count as changes.
  late List<double> _seen;

  EqProfile get _profile => widget.profile;

  /// Opens on Advanced when the earbuds are already on the custom mode. A
  /// controller, not `value`: ShadTabs re-selects `value` on every rebuild.
  late final ShadTabsController<_EqTab> _tabs;

  @override
  void initState() {
    super.initState();
    _device = widget.initial;
    _tabs = ShadTabsController(
      value: _device.mode == _profile.customMode
          ? _EqTab.advanced
          : _EqTab.simple,
    );
    _eq = KzEqualizerController(
      gains: _device.gains,
      min: _profile.minGain,
      max: _profile.maxGain,
      step: _profile.step,
    )..addListener(_onCommitted);
    _seen = _eq.committed;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _eq
      ..removeListener(_onCommitted)
      ..dispose();
    super.dispose();
  }

  void _onDeviceSettings(EqSettings settings) {
    setState(() => _device = settings);
    if (!listEquals(settings.gains, _eq.committed)) _eq.load(settings.gains);
  }

  void _onCommitted() {
    final gains = _eq.committed;
    if (identical(gains, _seen)) return;
    _seen = gains;
    if (listEquals(gains, _device.gains)) return;
    _send(EqSettings(mode: _profile.customMode, gains: gains));
  }

  void _selectPreset(EqPresetData preset) {
    final gains = preset.mode == _profile.customMode
        ? _eq.committed
        : preset.gains;
    _send(EqSettings(mode: preset.mode, gains: gains));
    _eq.setAll(gains);
  }

  void _send(EqSettings settings) {
    final previous = _device;
    setState(() => _device = settings);
    unawaited(
      ref.read(earbudsPortProvider).setEq(settings).catchError((Object _) {
        // The adapter logs the failure; show what the earbuds still hold.
        if (!mounted) return;
        setState(() => _device = previous);
        _eq.load(previous.gains);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(eqSettingsProvider, (_, next) {
      final settings = next.value;
      if (settings != null && settings != _device) {
        _onDeviceSettings(settings);
      }
    });

    final names = ref.watch(earbudsModelProvider)?.eqPresetNames ?? const {};

    return ShadTabs<_EqTab>(
      controller: _tabs,
      gap: KzSpace.s24,
      tabs: [
        ShadTab(
          value: _EqTab.simple,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KzSpace.s8,
            children: [
              for (final preset in _profile.presets)
                if (preset.mode != _profile.customMode)
                  ShadButton.raw(
                    variant: _device.mode == preset.mode
                        ? ShadButtonVariant.primary
                        : ShadButtonVariant.outline,
                    onPressed: () => _selectPreset(preset),
                    child: Text(eqPresetLabel(_profile, preset, names: names)),
                  ),
            ],
          ),
          child: const Text('SIMPLE'),
        ),
        ShadTab(
          value: _EqTab.advanced,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KzEqualizer(controller: _eq, frequencies: _profile.frequencies),
              const SizedBox(height: KzSpace.s16),
              ListenableBuilder(
                listenable: _eq,
                builder: (context, _) =>
                    _Controls(eq: _eq, frequencies: _profile.frequencies),
              ),
            ],
          ),
          child: const Text('ADVANCED'),
        ),
      ],
    );
  }
}

/// Read-only band readouts, then Reset and undo/redo.
class _Controls extends StatelessWidget {
  const _Controls({required this.eq, required this.frequencies});

  final KzEqualizerController eq;
  final List<int> frequencies;

  @override
  Widget build(BuildContext context) {
    final band = eq.selected;
    final hz = frequencies[band];
    final gain = eq.gains[band];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: KzReadoutPill(
                label: 'F ${formatEqFrequency(hz)}HZ',
                fraction: eqFrequencyFraction(hz),
              ),
            ),
            const SizedBox(width: KzSpace.s12),
            Expanded(
              child: KzReadoutPill(
                label: 'GAIN ${formatEqGain(gain)} DB',
                fraction: (gain - eq.min) / (eq.max - eq.min),
              ),
            ),
          ],
        ),
        const SizedBox(height: KzSpace.s24),
        Row(
          children: [
            KzBlockButton(label: 'Reset', onPressed: eq.reset),
            const Spacer(),
            KzRoundButton(
              icon: KzIcons.undo,
              semanticsLabel: 'Undo',
              onPressed: eq.canUndo ? eq.undo : null,
            ),
            const SizedBox(width: KzSpace.s12),
            KzRoundButton(
              icon: KzIcons.redo,
              semanticsLabel: 'Redo',
              onPressed: eq.canRedo ? eq.redo : null,
            ),
          ],
        ),
      ],
    );
  }
}
