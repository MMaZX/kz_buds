import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/battery_status.dart';
import '../../domain/entities/link_state.dart';
import '../providers/earbuds_providers.dart';
import '../widgets/battery_tile.dart';

class DeviceHomePage extends ConsumerWidget {
  const DeviceHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final battery = ref.watch(batteryProvider);

    return ColoredBox(
      color: const Color(0xFF000000),
      child: Center(
        child: switch (connection) {
          AsyncData(value: LinkState.connected) => switch (battery) {
            AsyncData(:final value) => _BatteryRow(status: value),
            AsyncError() => const Text('Battery unavailable'),
            _ => const Text('Loading...'),
          },
          AsyncData(value: LinkState.connecting) => const Text('Connecting...'),
          AsyncData() => const Text('Disconnected'),
          AsyncError() => const Text('Connection error'),
          _ => const Text('Loading...'),
        },
      ),
    );
  }
}

class _BatteryRow extends StatelessWidget {
  const _BatteryRow({required this.status});

  final BatteryStatus status;

  @override
  Widget build(BuildContext context) {
    final left = status.left;
    final right = status.right;
    final caseLevel = status.caseLevel;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (left != null) BatteryTile(label: 'Left', level: left),
        if (right != null) BatteryTile(label: 'Right', level: right),
        if (caseLevel != null) BatteryTile(label: 'Case', level: caseLevel),
      ],
    );
  }
}
