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

/// Logs the live noise attribute and the device's noise table. With [mode]
/// (0 off, 1 ANC, 2 transparency) it first sends that mode's table entry,
/// as the KZ app does, then reads the live attribute back.
Future<void> rcspNoise(
  RcspProtocol protocol,
  void Function(String message) log, {
  int? mode,
}) async {
  Future<RcspSysInfo> read() async => RcspSysInfo.parse(
    (await protocol.send(
      RcspCommands.getSysInfo(
        function: RcspSysFunction.public,
        mask: RcspSysAttr.maskOf([
          RcspSysAttr.noiseLive,
          RcspSysAttr.noiseTable,
        ]),
      ),
    )).payload,
  );

  final before = await read();
  log('noise live ${before.noise}');
  final table = before.noiseTable;
  log('noise table ${table ?? 'missing'}');
  if (mode == null) return;

  final entry = table?.where((e) => e.mode == mode).firstOrNull;
  if (entry == null) {
    log('mode $mode is not in the device table; nothing sent');
    return;
  }
  final set = RcspCommands.setNoise(entry);
  log('noise set: mode $mode, payload ${_hex(set.payload)}');
  final answer = await protocol.send(set);
  log(
    'noise set answered: status ${answer.status}, '
    'payload ${_hex(answer.payload)}',
  );
  log('noise live after ${(await read()).noise}');
}

/// Reads every sys info attribute (functions public and bt, full mask) and
/// every ADV info item, keyed `sys ff attr 0d` / `adv type 05`, hex values.
/// Read-only. Target info is left out: it carries the auth key and the
/// device addresses. A query the device rejects is logged and skipped.
Future<Map<String, String>> rcspSnapshot(
  RcspProtocol protocol,
  void Function(String message) log,
) async {
  final snapshot = <String, String>{};
  for (final function in [RcspSysFunction.public, RcspSysFunction.bt]) {
    final tag = function.toRadixString(16).padLeft(2, '0');
    try {
      final response = await protocol.send(
        RcspCommands.getSysInfo(function: function, mask: 0xffffffff),
      );
      RcspSysInfo.parse(response.payload).values.forEach((attr, value) {
        snapshot['sys $tag attr ${_hex([attr])}'] = _hex(value);
      });
    } on Object catch (error) {
      log('sys $tag read failed: $error');
    }
  }
  try {
    final response = await protocol.send(RcspCommands.advGetInfo());
    RcspAdvInfo.parse(response.payload).values.forEach((type, value) {
      snapshot['adv type ${_hex([type])}'] = _hex(value);
    });
  } on Object catch (error) {
    log('adv read failed: $error');
  }
  return snapshot;
}

/// One line per key whose value differs between two snapshots, sorted.
List<String> rcspDiff(Map<String, String> before, Map<String, String> after) {
  final keys = {...before.keys, ...after.keys}.toList()..sort();
  return [
    for (final key in keys)
      if (before[key] != after[key])
        '$key: ${before[key] ?? '(new)'} -> ${after[key] ?? '(gone)'}',
  ];
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
