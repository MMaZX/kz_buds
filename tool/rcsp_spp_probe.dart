// Live checks of the SPP path on Linux: detect paired JieLi earbuds through
// BlueZ, connect them like the OS does, run the RCSP handshake, then:
//
//   fvm dart run tool/rcsp_spp_probe.dart
//       info (default): support flags, battery, volume, EQ. Read-only.
//   fvm dart run tool/rcsp_spp_probe.dart find [both|left|right] [player]
//       rings the earbuds for a few seconds, then stops them. player is the
//       last SEARCH_DEVICE byte (0 = what the KZ app sends, 1 = device).
//
// It never sends reboot, factory reset, rename or OTA.
import 'dart:io';

import 'package:kz_buds/data/rcsp/rcsp_diagnostics.dart';
import 'package:kz_buds/data/spp/bluez_earbuds_discovery.dart';
import 'package:kz_buds/data/spp/linux/linux_rcsp_session.dart';
import 'package:kz_buds/data/spp/linux/linux_rfcomm_link.dart';

const _sides = {'both': 0, 'left': 1, 'right': 2};

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'info' : args[0];
  if (mode != 'info' && mode != 'find') {
    _log('usage: rcsp_spp_probe.dart [info | find [both|left|right] [0|1]]');
    exit(64);
  }

  final watch = Stopwatch()..start();
  final session = await openLinuxRcspSession(
    discover: BluezEarbudsDiscovery().pairedEarbuds,
    connectOs: bluezConnectProfiles,
    openLink: LinuxRfcommLink.connect,
    log: _log,
  );
  _log('auth passed in ${watch.elapsedMilliseconds} ms');
  try {
    if (mode == 'info') {
      await rcspInfo(session.protocol, _log);
    } else {
      await rcspFind(
        session.protocol,
        _log,
        side: _sides[args.length > 1 ? args[1] : 'both'] ?? 0,
        player: args.length > 2 ? int.parse(args[2]) : 0,
      );
    }
  } finally {
    await session.close();
  }
  exit(0);
}

void _log(String message) => stdout.writeln(message);
