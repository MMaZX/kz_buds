import 'package:flutter/foundation.dart';

/// Development-only console output, tagged by area: `[anc] set off`.
///
/// Prints only in debug builds. In profile and release builds [kDebugMode]
/// is a compile-time constant false, so nothing is printed. The caller
/// still builds the message string, so keep messages cheap.
///
/// Callable, so it fits any `void Function(String message)` log parameter.
class DebugLog {
  const DebugLog(this.tag);

  final String tag;

  void call(String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }
}
