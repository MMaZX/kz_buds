import '../protocol/rcsp_commands.dart';
import '../protocol/rcsp_protocol.dart';

/// Live checks shared by `tool/rcsp_spp_probe.dart` and the app's debug
/// buttons. They only read, or ring the earbuds; never reboot, reset,
/// rename or OTA.

/// Logs the device's support flags (target info TLV 19), battery and EQ.
Future<void> rcspInfo(
  RcspProtocol protocol,
  void Function(String message) log,
) async {
  final target = await protocol.send(RcspCommands.getTargetInfo());
  log('support ${RcspTargetInfo.parse(target.payload).support}');

  final sys = await protocol.send(
    RcspCommands.getSysInfo(
      function: RcspSysFunction.public,
      mask: RcspSysAttr.maskOf([
        RcspSysAttr.battery,
        RcspSysAttr.volume,
        RcspSysAttr.eq,
      ]),
    ),
  );
  final info = RcspSysInfo.parse(sys.payload);
  log('sys battery ${info.battery}, volume ${info.volume}');
  log('eq ${info.eq}');

  final adv = await protocol.send(RcspCommands.advGetInfo());
  log('adv battery ${RcspAdvInfo.parse(adv.payload).battery}');
}

/// Rings [side] (0 both, 1 left, 2 right) for [ring], then stops. [player]
/// is the last SEARCH_DEVICE byte: 0 is what the KZ app sends.
Future<void> rcspFind(
  RcspProtocol protocol,
  void Function(String message) log, {
  int side = 0,
  int player = 0,
  Duration ring = const Duration(seconds: 6),
}) async {
  final start = RcspCommands.searchDevice(
    start: true,
    timeoutSeconds: 10,
    side: side,
    player: player,
  );
  log('find start: side $side, player $player, payload ${_hex(start.payload)}');
  final started = await protocol.send(start);
  log(
    'find start answered: status ${started.status}, '
    'payload ${_hex(started.payload)}',
  );

  await Future<void>.delayed(ring);

  final stopped = await protocol.send(RcspCommands.searchDevice(start: false));
  log(
    'find stop answered: status ${stopped.status}, '
    'payload ${_hex(stopped.payload)}',
  );
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
