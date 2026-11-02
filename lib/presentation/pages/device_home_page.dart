import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/capabilities/capability.dart';
import '../../domain/catalog/earbuds_model.dart';
import '../../domain/entities/anc_mode.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/link_state.dart';
import '../providers/earbuds_providers.dart';
import '../providers/navigation_providers.dart';
import '../theme/kz_icons.dart';
import '../theme/kz_metrics.dart';
import '../theme/kz_model_art.dart';
import '../theme/kz_theme.dart';
import '../widgets/kz_anc_rings.dart';
import '../widgets/kz_battery_indicator.dart';
import '../widgets/kz_card.dart';
import '../widgets/kz_chip.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_pressable.dart';
import '../widgets/kz_round_button.dart';
import 'anc_page.dart';
import 'app_shell.dart';
import 'find_page.dart';
import 'kz_route.dart';

class DeviceHomePage extends ConsumerWidget {
  const DeviceHomePage({super.key});

  static const _heroHeight = 220.0;
  static const _dimmedHeroOpacity = 0.4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(connectionProvider);
    final battery = ref.watch(batteryProvider);
    final capabilities =
        ref.watch(capabilitiesProvider).value ?? const <Capability>{};
    final mode = ref.watch(ancModeProvider).value ?? AncMode.off;
    final connected = link.value == LinkState.connected;

    return KzPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: KzSpace.s16),
            _Header(link: link),
            const SizedBox(height: KzSpace.s24),
            Opacity(
              opacity: connected ? 1 : _dimmedHeroOpacity,
              child: SizedBox(
                height: _heroHeight,
                child: _Hero(model: ref.watch(earbudsModelProvider)),
              ),
            ),
            const SizedBox(height: KzSpace.s24),
            if (link.value == LinkState.disconnected)
              Center(
                child: KzRoundButton(
                  icon: KzIcons.bluetooth,
                  label: 'Reconnect',
                  semanticsLabel: 'Reconnect the earbuds',
                  onPressed: () => unawaited(
                    ref
                        .read(earbudsPortProvider)
                        .connect()
                        .catchError(
                          (Object error) =>
                              debugPrint('Reconnect failed: $error'),
                        ),
                  ),
                ),
              ),
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
                  onOpen: () =>
                      Navigator.of(context)
                          .push(kzRoute<void>(context, (_) => const AncPage())),
                ),
              ],
              if (capabilities.contains(Capability.findBuds) ||
                  capabilities.contains(Capability.buttonRemap)) ...[
                const SizedBox(height: KzSpace.s24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (capabilities.contains(Capability.findBuds))
                      KzRoundButton(
                        icon: KzIcons.find,
                        label: 'Find',
                        semanticsLabel: 'Find my buds',
                        onPressed: () => Navigator.of(
                          context,
                        ).push(kzRoute<void>(context, (_) => const FindPage())),
                      ),
                    if (capabilities.contains(Capability.findBuds) &&
                        capabilities.contains(Capability.buttonRemap))
                      const SizedBox(width: KzSpace.s24),
                    if (capabilities.contains(Capability.buttonRemap))
                      KzRoundButton(
                        icon: KzIcons.tap,
                        label: 'Touch',
                        semanticsLabel: 'Open touch controls',
                        onPressed: () => ref
                            .read(selectedTabProvider.notifier)
                            .select(KzTab.touch),
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: AppShell.navClearance),
          ],
        ),
      ),
    );
  }
}

/// The model's artwork, or a generic placeholder for unknown models.
class _Hero extends StatelessWidget {
  const _Hero({required this.model});

  final EarbudsModel? model;

  @override
  Widget build(BuildContext context) {
    final asset = KzModelArt.assetFor(model);
    if (asset == null) {
      return Placeholder(color: KzTheme.of(context).scheme.mutedForeground);
    }
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      semanticLabel: model!.displayName,
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
  const _NoiseControlCard({
    required this.mode,
    required this.onSelected,
    required this.onOpen,
  });

  final AncMode mode;
  final ValueChanged<AncMode> onSelected;
  final VoidCallback onOpen;

  static const _labels = {
    AncMode.noiseCancelling: 'ANC',
    AncMode.ambient: 'Ambient',
    AncMode.off: 'Off',
  };

  @override
  Widget build(BuildContext context) {
    final theme = KzTheme.of(context);
    final scheme = theme.scheme;

    return KzCard(
      radius: KzRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          KzPressable(
            borderRadius: BorderRadius.circular(KzRadii.md),
            semanticsLabel: 'Noise control details',
            onPressed: onOpen,
            child: ExcludeSemantics(
              child: Row(
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
                  const SizedBox(width: KzSpace.s8),
                  KzIcon(KzIcons.forward, color: scheme.mutedForeground),
                ],
              ),
            ),
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
    );
  }
}
