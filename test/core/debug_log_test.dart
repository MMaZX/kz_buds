import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/core/debug_log.dart';

void main() {
  late List<String?> printed;
  late DebugPrintCallback original;

  setUp(() {
    printed = [];
    original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
  });

  tearDown(() => debugPrint = original);

  test('prints the message with its tag in debug builds', () {
    const DebugLog('anc')('set off');

    expect(printed, ['[anc] set off']);
  });

  test('can be passed where a log callback is expected', () {
    final void Function(String message) log = const DebugLog('reconnect').call;

    log('watching');

    expect(printed, ['[reconnect] watching']);
  });
}
