import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

void main() {
  final libFiles = dartFiles('lib');

  test('lib imports Material only as `show Scaffold`, never Cupertino', () {
    final material = RegExp(
      r'''import\s+['"]package:flutter/material\.dart['"]([^;]*);''',
    );
    for (final f in libFiles) {
      final src = f.readAsStringSync();
      expect(
        src.contains('package:flutter/cupertino.dart'),
        isFalse,
        reason: f.path,
      );
      for (final m in material.allMatches(src)) {
        expect(m.group(1)!.trim(), 'show Scaffold', reason: f.path);
      }
    }
  });

  test('hex colors live only in kz_palette.dart', () {
    for (final f in libFiles) {
      if (f.path.endsWith('presentation/theme/kz_palette.dart')) continue;
      expect(
        f.readAsStringSync().contains('Color(0x'),
        isFalse,
        reason: f.path,
      );
    }
  });

  test('HugeIcons is referenced only from kz_icons.dart', () {
    for (final f in libFiles) {
      if (f.path.endsWith('presentation/theme/kz_icons.dart')) continue;
      expect(
        f.readAsStringSync().contains('HugeIcons.'),
        isFalse,
        reason: f.path,
      );
    }
  });

  test('domain stays pure Dart', () {
    for (final f in dartFiles('lib/domain')) {
      final src = f.readAsStringSync();
      expect(src.contains('package:flutter'), isFalse, reason: f.path);
      expect(src.contains('riverpod'), isFalse, reason: f.path);
    }
  });

  test('protocol code imports only dart: libraries and itself', () {
    final import = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true);
    for (final f in dartFiles('lib/data/protocol')) {
      for (final m in import.allMatches(f.readAsStringSync())) {
        final uri = m.group(1)!;
        expect(
          uri.startsWith('dart:') || !uri.contains(':'),
          isTrue,
          reason: '${f.path} imports $uri',
        );
      }
    }
  });
}
