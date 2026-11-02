import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/capabilities/capability.dart';
import 'package:kz_buds/domain/entities/anc_mode.dart';
import 'package:kz_buds/domain/entities/battery_status.dart';
import 'package:kz_buds/domain/entities/earbuds_identity.dart';
import 'package:kz_buds/domain/entities/find_target.dart';
import 'package:kz_buds/domain/entities/link_state.dart';
import 'package:kz_buds/domain/ports/earbuds_port.dart';
import 'package:kz_buds/presentation/providers/earbuds_providers.dart';

/// Reports find buds only while connected, like the RCSP adapter.
class _LinkBoundPort implements EarbudsPort {
  final link = StreamController<LinkState>.broadcast();
  LinkState state = LinkState.disconnected;

  Future<void> close() => link.close();

  @override
  Stream<LinkState> watchConnection() => link.stream;

  @override
  Future<Set<Capability>> capabilities() async =>
      state == LinkState.connected ? {Capability.findBuds} : {};

  @override
  Future<void> connect() async {}

  @override
  Future<EarbudsIdentity?> identity() async => null;

  @override
  Stream<BatteryStatus> watchBattery() => const Stream.empty();

  @override
  Stream<AncMode> watchAncMode() => const Stream.empty();

  @override
  Future<void> setAncMode(AncMode mode) async {}

  @override
  Future<void> playFindSound(FindTarget target) async {}

  @override
  Future<void> stopFindSound() async {}
}

void main() {
  test('capabilities are read again when the link state changes', () async {
    final port = _LinkBoundPort();
    final container = ProviderContainer(
      overrides: [earbudsPortProvider.overrideWithValue(port)],
    );
    addTearDown(container.dispose);
    addTearDown(port.close);
    container.listen(capabilitiesProvider, (_, _) {});

    expect(await container.read(capabilitiesProvider.future), isEmpty);

    port.state = LinkState.connected;
    port.link.add(LinkState.connected);
    await pumpEventQueue();

    expect(await container.read(capabilitiesProvider.future), {
      Capability.findBuds,
    });
  });
}
