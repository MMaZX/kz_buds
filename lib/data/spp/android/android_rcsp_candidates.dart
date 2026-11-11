import 'dart:async';

import '../../../domain/entities/detected_earbuds.dart';

/// Decides whether the devices Android has connected are still worth an
/// automatic RCSP attempt.
///
/// Android cannot tell which connected audio device speaks RCSP before the
/// handshake, so a connected speaker would be retried forever. A device that
/// keeps failing is given up on until it disconnects and connects again; one
/// that completed the handshake once is never given up on.
class AndroidRcspCandidates {
  AndroidRcspCandidates({this.maxFailures = 3});

  /// Failed handshakes before an unproven device is given up on. More than
  /// one: earbuds may refuse SPP for a moment right after the OS connects.
  final int maxFailures;

  Set<String>? _connected;
  final _failures = <String, int>{};
  final _proven = <String>{};
  final _changes = StreamController<bool>.broadcast();
  bool _worthTrying = false;

  /// Whether a connected device may still answer. False while the OS cannot
  /// tell which devices are connected.
  bool get worthTrying => _worthTrying;

  /// [worthTrying] on listen, then each change.
  Stream<bool> get worthTryingChanges => Stream.multi((controller) {
    controller.add(_worthTrying);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  /// Takes the addresses the OS has connected, or null when it cannot tell.
  void update(Set<String>? connected) {
    final addresses = connected?.map(_key).toSet();
    _connected = addresses;
    if (addresses != null) {
      _failures.removeWhere((address, _) => !addresses.contains(address));
    }
    _refresh();
  }

  void proven(String address) {
    _proven.add(_key(address));
    _failures.remove(_key(address));
    _refresh();
  }

  void failed(String address) {
    _failures.update(_key(address), (count) => count + 1, ifAbsent: () => 1);
    _refresh();
  }

  /// Proven devices first, given-up devices last, otherwise the given order.
  List<DetectedEarbuds> prioritize(List<DetectedEarbuds> found) {
    int rank(DetectedEarbuds earbuds) {
      final address = _key(earbuds.id);
      if (_proven.contains(address)) return 0;
      return _givenUp(address) ? 2 : 1;
    }

    return [
      for (var wanted = 0; wanted <= 2; wanted++)
        for (final earbuds in found)
          if (rank(earbuds) == wanted) earbuds,
    ];
  }

  bool _givenUp(String address) =>
      !_proven.contains(address) && (_failures[address] ?? 0) >= maxFailures;

  void _refresh() {
    final worth = _connected?.any((address) => !_givenUp(address)) ?? false;
    if (worth == _worthTrying) return;
    _worthTrying = worth;
    _changes.add(worth);
  }

  static String _key(String address) => address.toUpperCase();
}
