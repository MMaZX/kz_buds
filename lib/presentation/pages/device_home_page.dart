import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/link_state.dart';
import '../providers/earbuds_providers.dart';
import '../theme/kz_glass.dart';
import '../theme/kz_glass_theme.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_anc_rings.dart';
import '../widgets/kz_battery_indicator.dart';
import '../widgets/kz_chip.dart';
import '../widgets/kz_page.dart';

class DeviceHomePage extends ConsumerWidget {
  const DeviceHomePage({super.key});

  static const _heroHeight = 220.0;
  static const _dimmedHeroOpacity = 0.4;

  double _glowScale(AncMode mode) => switch (mode) {
    AncMode.noiseCancelling => 0.85,
    AncMode.ambient => 1.15,
    AncMode.off => 1,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = KzTheme.of(context);
    final link = ref.watch(connectionProvider);
    final battery = ref.watch(batteryProvider);
    final capabilities =
        ref.watch(capabilitiesProvider).value ?? const <Capability>{};
    final mode = ref.watch(ancModeProvider).value ?? AncMode.off;
    final connected = link.value == LinkState.connected;

    return KzPage(
      glowScale: _glowScale(mode),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            _Header(link: link),
            const SizedBox(height: KzSpace.s24),
            Opacity(
              opacity: connected ? 1 : _dimmedHeroOpacity,
              // Placeholder until per-model renders exist.
              child: SizedBox(
                height: _heroHeight,
                child: Placeholder(color: theme.scheme.mutedForeground),
              ),
            ),
            const SizedBox(height: KzSpace.s24),
            if (connected) ...[
              switch (battery) {
                AsyncData(:final value) => _BatteryRow(status: value),
                AsyncError() => const Text('Battery unavailable'),
                _ => const SizedBox.shrink(),
              },
              if (capabilities.contains(Capability.anc)) ...[
                const SizedBox(height: KzSpace.s24),
                _NoiseControlCard(
                  mode: mode,
                  onSelected: ref.read(earbudsPortProvider).setAncMode,
                ),
              ],
            ],
            const SizedBox(height: KzSpace.s32),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.link});

  final AsyncValue<LinkState> link;

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;
    final connected = link.value == LinkState.connected;
    final label = switch (link) {
      AsyncData(value: LinkState.connected) => 'Connected',
      AsyncData(value: LinkState.connecting) => 'Connecting...',
      AsyncData() => 'Disconnected',
      AsyncError() => 'Connection error',
      _ => 'Loading...',
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            'KZ Buds',
            style: theme.typography.h1.copyWith(color: scheme.foreground),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: connected ? theme.colors.success : scheme.mutedForeground,
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: KzSpace.s8),
        ),
        const SizedBox(width: KzSpace.s8),
        Text(
          label,
          style: theme.typography.caption.copyWith(
            color: scheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _BatteryRow extends StatelessWidget {
  const _BatteryRow({required this.status});

  final BatteryStatus status;

  @override
  Widget build(BuildContext context) {
    final indicators = [
      if (status.left != null)
        KzBatteryIndicator(label: 'L', level: status.left),
      if (status.caseLevel != null)
        KzBatteryIndicator(label: 'Case', level: status.caseLevel),
      if (status.right != null)
        KzBatteryIndicator(label: 'R', level: status.right),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: indicators,
    );
  }
}

class _NoiseControlCard extends StatelessWidget {
  const _NoiseControlCard({required this.mode, required this.onSelected});

  final AncMode mode;
  final ValueChanged<AncMode> onSelected;

  static const _labels = {
    AncMode.noiseCancelling: 'ANC',
    AncMode.ambient: 'Ambient',
    AncMode.off: 'Off',
  };

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return KzGlass(
      level: KzGlassLevel.panel,
      borderRadius: BorderRadius.circular(KzRadii.xl),
      child: Padding(
        padding: const EdgeInsets.all(KzSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'NOISE CONTROL',
                    style: theme.typography.overline.copyWith(
                      color: scheme.mutedForeground,
                    ),
                  ),
                ),
                KzAncRings(
                  mode: mode,
                  size: 36,
                  color: mode == AncMode.off
                      ? scheme.mutedForeground
                      : theme.colors.brand,
                ),
              ],
            ),
            const SizedBox(height: KzSpace.s12),
            Wrap(
              spacing: KzSpace.s8,
              runSpacing: KzSpace.s8,
              children: [
                for (final entry in _labels.entries)
                  KzChip(
                    label: entry.value,
                    selected: mode == entry.key,
                    onPressed: () => onSelected(entry.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
