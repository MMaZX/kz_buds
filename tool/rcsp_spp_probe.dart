// Live checks of the SPP path on Linux: detect paired JieLi earbuds through
// BlueZ, connect them like the OS does, run the RCSP handshake, then:
//
//   fvm dart run tool/rcsp_spp_probe.dart
//       info (default): support flags, battery, volume, EQ. Read-only.
//   fvm dart run tool/rcsp_spp_probe.dart find [both|left|right] [player]
//       rings the earbuds for a few seconds, then stops them. player is the
//       last SEARCH_DEVICE byte (0 = what the KZ app sends, 1 = device).
//   fvm dart run tool/rcsp_spp_probe.dart noise [off|anc|transparency]
//       reads the noise mode and the device's mode table; with a mode, sends
//       that table entry first.
//   fvm dart run tool/rcsp_spp_probe.dart dump
//       prints every readable sys info attribute and ADV item, then on each
//       Enter reads them again and prints only what changed; q quits.
//       Read-only. Output may include device data: do not post it publicly.
//
// It never sends reboot, factory reset, rename or OTA.
import 'dart:io';

import 'package:kz_buds/data/protocol/rcsp_protocol.dart';
import 'package:kz_buds/data/rcsp/rcsp_diagnostics.dart';
import 'package:kz_buds/data/spp/bluez_earbuds_discovery.dart';
import 'package:kz_buds/data/spp/linux/linux_rcsp_session.dart';
import 'package:kz_buds/data/spp/linux/linux_rfcomm_link.dart';

const _sides = {'both': 0, 'left': 1, 'right': 2};
const _noiseModes = {'off': 0, 'anc': 1, 'transparency': 2};

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'info' : args[0];
  final noiseArg = mode == 'noise' && args.length > 1 ? args[1] : null;
  if (!{'info', 'find', 'noise', 'dump'}.contains(mode) ||
      (noiseArg != null && !_noiseModes.containsKey(noiseArg))) {
    _log(
      'usage: rcsp_spp_probe.dart [info | find [both|left|right] [0|1] | '
      'noise [off|anc|transparency] | dump]',
    );
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
    } else if (mode == 'dump') {
      await _dump(session.protocol);
    } else if (mode == 'noise') {
      await rcspNoise(session.protocol, _log, mode: _noiseModes[noiseArg]);
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

Future<void> _dump(RcspProtocol protocol) async {
  var previous = await rcspSnapshot(protocol, _log);
  for (final entry in previous.entries) {
    _log('${entry.key}: ${entry.value}');
  }
  for (var round = 1; ; round++) {
    _log('--- change something on the earbuds, then Enter (q quits)');
    final line = stdin.readLineSync();
    if (line == null || line.trim() == 'q') return;
    final current = await rcspSnapshot(protocol, _log);
    final changes = rcspDiff(previous, current);
    _log('round $round: ${changes.isEmpty ? 'no changes' : ''}');
    changes.forEach(_log);
    previous = current;
  }
}

void _log(String message) => stdout.writeln(message);
