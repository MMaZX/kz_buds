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
import '../widgets/kz_anc_icon.dart';
import '../widgets/kz_battery_indicator.dart';
import '../widgets/kz_page.dart';
import '../widgets/kz_pill_button.dart';
import '../widgets/kz_pressable.dart';
import '../widgets/noise_control_sheet.dart';
import 'app_shell.dart';
import 'find_page.dart';
import 'kz_route.dart';

/// Shown under Reconnect after the OS denied Bluetooth access.
const bluetoothAccessHint =
    'Bluetooth access denied. Allow it for KZ Buds in system settings.';

/// Shown under Reconnect while the Bluetooth radio is off.
const bluetoothOffHint = 'Bluetooth is off. Turn it on to connect the earbuds.';

class DeviceHomePage extends ConsumerWidget {
  const DeviceHomePage({super.key});

  static const _heroMinHeight = 120.0;
  static const _heroMaxHeight = 360.0;
  static const _dimmedHeroOpacity = 0.4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = ref.watch(connectionProvider);
    final battery = ref.watch(batteryProvider);
    final capabilities =
        ref.watch(capabilitiesProvider).value ?? const <Capability>{};
    final mode = ref.watch(ancModeProvider).value ?? AncMode.off;
    final model = ref.watch(earbudsModelProvider);
    final connected = link.value == LinkState.connected;
    final issue = ref.watch(reconnectProvider);
    final hasEq = capabilities.contains(Capability.eq);
    final hasRemap = capabilities.contains(Capability.buttonRemap);
    final tabs = ref.read(selectedTabProvider.notifier);

    return KzPage(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: KzSpace.s8),
                  _TopBar(
                    onFind: capabilities.contains(Capability.findBuds)
                        ? () => Navigator.of(context).push(
                            kzRoute<void>(context, (_) => const FindPage()),
                          )
                        : null,
                    onSettings: () => tabs.select(KzTab.settings),
                  ),
                  const SizedBox(height: KzSpace.s16),
                  _Title(name: model?.displayName ?? 'KZ Buds', link: link),
                  const SizedBox(height: KzSpace.s16),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: _heroMinHeight,
                        maxHeight: _heroMaxHeight,
                      ),
                      child: Opacity(
                        opacity: connected ? 1 : _dimmedHeroOpacity,
                        child: _Hero(model: model),
                      ),
                    ),
                  ),
                  const SizedBox(height: KzSpace.s24),
                  if (link.value == LinkState.disconnected)
                    KzPillButton(
                      label: 'Reconnect',
                      filled: true,
                      semanticsLabel: 'Reconnect the earbuds',
                      leading: KzIcon(
                        KzIcons.bluetooth,
                        size: 18,
                        color: KzTheme.of(context).scheme.secondaryForeground,
                      ),
                      onPressed: () => unawaited(
                        ref
                            .read(reconnectProvider.notifier)
                            .reconnect()
                            .catchError(
                              (Object error) =>
                                  debugPrint('Reconnect failed: $error'),
                            ),
                      ),
                    ),
                  if (link.value == LinkState.disconnected &&
                      issue != null) ...[
                    const SizedBox(height: KzSpace.s12),
                    Text(
                      switch (issue) {
                        ConnectIssue.accessDenied => bluetoothAccessHint,
                        ConnectIssue.bluetoothOff => bluetoothOffHint,
                      },
                      textAlign: TextAlign.center,
                      style: KzTheme.of(context).typography.caption.copyWith(
                        color: KzTheme.of(context).scheme.mutedForeground,
                      ),
                    ),
                  ],
                  if (connected) ...[
                    switch (battery) {
                      AsyncData(:final value) => _BatteryRow(status: value),
                      AsyncError() => const Center(
                        child: Text('Battery unavailable'),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                    const SizedBox(height: KzSpace.s40),
                    if (hasEq || hasRemap) ...[
                      Row(
                        spacing: KzSpace.s12,
                        children: [
                          if (hasEq)
                            Expanded(
                              child: KzPillButton(
                                label: 'Equalizer',
                                semanticsLabel: 'Open the equalizer',
                                onPressed: () => tabs.select(KzTab.eq),
                              ),
                            ),
                          if (hasRemap)
                            Expanded(
                              child: KzPillButton(
                                label: 'Controls',
                                semanticsLabel: 'Open touch controls',
                                onPressed: () => tabs.select(KzTab.touch),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: KzSpace.s12),
                    ],
                    if (capabilities.contains(Capability.anc))
                      KzPillButton(
                        label: 'Noise control',
                        filled: true,
                        semanticsLabel: 'Noise control details',
                        leading: KzAncIcon(
                          mode: mode,
                          size: 20,
                          color: mode == AncMode.off
                              ? KzTheme.of(context).scheme.secondaryForeground
                              : KzTheme.of(context).colors.brand,
                        ),
                        onPressed: () =>
                            unawaited(showNoiseControlSheet(context)),
                      ),
                  ],
                  const SizedBox(height: AppShell.navClearance),
                ],
              ),
            ),
          ),
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

/// Quick actions above the title: find on the left, settings on the right.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings, this.onFind});

  final VoidCallback? onFind;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onFind != null)
          _IconAction(
            icon: KzIcons.find,
            semanticsLabel: 'Find my buds',
            onPressed: onFind!,
          ),
        const Spacer(),
        _IconAction(
          icon: KzIcons.settings,
          semanticsLabel: 'Open settings',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final KzIconData icon;
  final String semanticsLabel;
  final VoidCallback onPressed;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return KzPressable(
      borderRadius: BorderRadius.circular(KzRadii.pill),
      semanticsLabel: semanticsLabel,
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: _size,
        child: Center(
          child: KzIcon(icon, color: KzTheme.of(context).scheme.foreground),
        ),
      ),
    );
  }
}

/// The model name as the page title, with the link state under it.
class _Title extends StatelessWidget {
  const _Title({required this.name, required this.link});

  final String name;
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

    return Column(
      spacing: KzSpace.s8,
      children: [
        Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.typography.h1.copyWith(
            color: scheme.foreground,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: KzSpace.s8,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: connected
                    ? theme.colors.success
                    : scheme.mutedForeground,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: KzSpace.s8),
            ),
            Text(
              label,
              style: theme.typography.caption.copyWith(
                color: scheme.mutedForeground,
              ),
            ),
          ],
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
        KzBatteryIndicator(label: 'C', level: status.caseLevel),
      if (status.right != null)
        KzBatteryIndicator(label: 'R', level: status.right),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: KzSpace.s32,
      children: indicators,
    );
  }
}
