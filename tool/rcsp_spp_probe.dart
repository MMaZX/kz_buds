// Live check of the SPP path on Linux: detect paired JieLi earbuds through
// BlueZ, run the RCSP handshake and read the battery. Read-only: it sends
// only GET_SYS_INFO and ADV_GET_INFO.
//
//   fvm dart run tool/rcsp_spp_probe.dart
import 'dart:io';

import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/spp/bluez_earbuds_discovery.dart';
import 'package:kz_buds/data/spp/linux/linux_rfcomm_link.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';

Future<void> main() async {
  final found = await BluezEarbudsDiscovery().pairedEarbuds();
  _log('detected ${found.length}: ${found.map((e) => e.name).join(', ')}');
  if (found.isEmpty) exit(1);

  final earbuds = found.first;
  _log('connecting to ${earbuds.name} (${_redact(earbuds.id)})');
  final watch = Stopwatch()..start();
  final session = await RcspSppSession.open(
    () => LinuxRfcommLink.connect(earbuds.id),
  );
  _log('auth passed in ${watch.elapsedMilliseconds} ms');
  try {
    final sys = await session.protocol.send(
      RcspCommands.getSysInfo(
        function: RcspSysFunction.public,
        mask: RcspSysAttr.maskOf([
          RcspSysAttr.battery,
          RcspSysAttr.volume,
          RcspSysAttr.eq,
          RcspSysAttr.noiseLive,
        ]),
      ),
    );
    final info = RcspSysInfo.parse(sys.payload);
    _log('sys battery ${info.battery}, volume ${info.volume}');
    _log('eq ${info.eq}');
    _log('noise ${info.noise}');

    final adv = await session.protocol.send(RcspCommands.advGetInfo());
    _log('adv battery ${RcspAdvInfo.parse(adv.payload).battery}');
  } finally {
    await session.close();
  }
  exit(0);
}

void _log(String message) => stdout.writeln(message);

String _redact(String address) => address.length < 5
    ? '?'
    : 'xx:xx:xx:xx:${address.substring(address.length - 5)}';
