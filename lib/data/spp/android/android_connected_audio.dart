import 'dart:async';

import 'package:flutter/services.dart';

const _channel = MethodChannel('kz_buds/bluetooth');
const _linkEvents = EventChannel('kz_buds/bluetooth/audio_link');

/// Addresses (upper case) of the devices Android has an audio profile
/// connected to, or null when the OS cannot tell.
///
/// `bluetooth_rfcomm` reports every bonded device as not connected, so this
/// asks the platform side (MainActivity) directly.
Future<Set<String>?> androidConnectedAudioAddresses({
  Duration timeout = const Duration(seconds: 2),
}) async {
  try {
    final addresses = await _channel
        .invokeListMethod<String>('connectedAudioDevices')
        .timeout(timeout);
    return addresses?.map((address) => address.toUpperCase()).toSet();
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  } on TimeoutException {
    return null;
  }
}

/// The connected audio addresses on listen, then again every time Android
/// connects or disconnects an audio device or switches Bluetooth.
///
/// Event driven: nothing runs between OS events. A signal that arrives during
/// a query triggers one more query, so the last value is never stale.
Stream<Set<String>?> androidConnectedAudioChanges({
  Stream<Object?>? signals,
  Future<Set<String>?> Function() query = androidConnectedAudioAddresses,
}) => Stream.multi((controller) {
  var querying = false;
  var stale = false;
  Future<void> refresh() async {
    if (querying) {
      stale = true;
      return;
    }
    querying = true;
    try {
      do {
        stale = false;
        final connected = await query();
        if (controller.isClosed) return;
        controller.add(connected);
      } while (stale);
    } finally {
      querying = false;
    }
  }

  final subscription = (signals ?? _linkEvents.receiveBroadcastStream()).listen(
    (_) => unawaited(refresh()),
    onError: controller.addError,
  );
  controller.onCancel = subscription.cancel;
  unawaited(refresh());
});
