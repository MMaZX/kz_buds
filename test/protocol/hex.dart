import 'dart:typed_data';

Uint8List hex(String s) => Uint8List.fromList([
  for (final part in s.trim().split(RegExp(r'\s+')))
    if (part.isNotEmpty) int.parse(part, radix: 16),
]);
