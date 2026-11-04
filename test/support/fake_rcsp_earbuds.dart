import 'dart:async';
import 'dart:typed_data';

import 'package:kz_buds/data/protocol/rcsp_auth.dart';
import 'package:kz_buds/data/protocol/rcsp_commands.dart';
import 'package:kz_buds/data/protocol/rcsp_frame.dart';
import 'package:kz_buds/data/spp/rcsp_spp_session.dart';

/// In-memory SPP link that plays RCSP earbuds: completes the handshake with
/// [deviceAuth] and answers ADV_GET_INFO with [advBattery] (`L R C`).
class FakeRcspEarbuds implements SppLink {
  FakeRcspEarbuds({
    RcspAuth? deviceAuth,
    this.advBattery = const [60, 70, 0],
    this.supportFlags = const [0x44, 0x00],
    this.deviceName = 'CAROL PRO',
    this.noiseTable = defaultNoiseTable,
    this.liveNoiseMode = 1,
    this.setSysInfoStatus = 0,
  }) : _auth = deviceAuth ?? RcspAuth();

  final RcspAuth _auth;
  List<int> advBattery;

  /// Target info TLV 19; the default reports search device and ANC.
  final List<int> supportFlags;

  /// Target info TLV 16; empty leaves the item out, as the Carol Pro does.
  final String deviceName;

  /// Sys info attr 14 entries (9 bytes each); empty leaves the attribute out.
  final List<List<int>> noiseTable;

  /// Mode byte of sys info attr 13.
  final int liveNoiseMode;

  /// Response status for SET_SYS_INFO; non-zero plays a rejection.
  final int setSysInfoStatus;

  static const defaultNoiseTable = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 10, 0, 10, 0, 5, 0, 5],
    [2, 0, 8, 0, 8, 0, 4, 0, 4],
  ];
  final _incoming = StreamController<List<int>>();
  final _ownChallenge = Uint8List.fromList([0x00, ...List.filled(16, 0x5a)]);
  final requests = <RcspFrame>[];
  bool closed = false;
  var _sn = 0;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (closed) throw StateError('link closed');
    if (bytes.length == 17 && bytes[0] == RcspAuth.challengeFlag) {
      _incoming.add(_auth.answer(bytes));
    } else if (RcspAuth.isPass(bytes)) {
      _incoming.add(_ownChallenge);
    } else if (bytes.length == 17 && bytes[0] == RcspAuth.answerFlag) {
      if (_auth.verify(_ownChallenge, bytes)) {
        _incoming.add(RcspAuth.passMessage);
      }
    } else {
      final request = RcspFrame.decode(bytes);
      requests.add(request);
      final payload = switch (request.opcode) {
        RcspOpcode.advGetInfo => [0x04, 0x00, ...advBattery],
        RcspOpcode.getTargetInfo => [
          supportFlags.length + 1,
          0x13,
          ...supportFlags,
          if (deviceName.isNotEmpty) ...[
            deviceName.length + 1,
            0x10,
            ...deviceName.codeUnits,
          ],
        ],
        RcspOpcode.getSysInfo => [
          0xff, 0x02, 0x00, 0x50, //
          0x0a, 0x0d, liveNoiseMode, 0, 10, 0, 10, 0, 5, 0, 5,
          if (noiseTable.isNotEmpty) ...[
            2 + noiseTable.length * 9,
            0x0e,
            noiseTable.length,
            for (final entry in noiseTable) ...entry,
          ],
        ],
        _ => const <int>[],
      };
      _incoming.add(
        RcspFrame.response(
          opcode: request.opcode,
          status: request.opcode == RcspOpcode.setSysInfo
              ? setSysInfoStatus
              : 0,
          sn: request.sn,
          payload: payload,
        ).encode(),
      );
    }
  }

  /// Pushes an unsolicited C2 status block carrying `L R C`.
  void pushStatus(List<int> battery) => _incoming.add(
    RcspFrame.command(
      opcode: RcspOpcode.advStatus,
      sn: _sn++,
      expectsResponse: false,
      payload: [
        0x05, 0xd6, 0x00, 0x00, 0x00, 0x00, 0x22, //
        0, 0, 0, 0, 0, 0, 0x02, ...battery, 0x01,
      ],
    ).encode(),
  );

  /// Pushes any unsolicited command frame.
  void push(int opcode, List<int> payload) => _incoming.add(
    RcspFrame.command(
      opcode: opcode,
      sn: _sn++,
      expectsResponse: false,
      payload: payload,
    ).encode(),
  );

  /// The earbuds drop the link.
  Future<void> drop() => _incoming.close();

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }
}
