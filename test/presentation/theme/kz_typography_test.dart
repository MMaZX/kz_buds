import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_licenses.dart';
import 'package:kz_buds/presentation/theme/kz_typography.dart';

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File('assets/fonts/inter/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

double widthOf(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const type = KzTypography();

  test('body is Inter 15 / 400 / 1.45', () {
    expect(type.body.fontFamily, 'Inter');
    expect(type.body.fontSize, 15);
    expect(type.body.fontWeight, FontWeight.w400);
    expect(type.body.height, 1.45);
  });

  test('numeric styles use tabular figures', () {
    for (final style in [type.numeralXl, type.numeralL]) {
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  test('numerals use the Display optical size, light weight', () {
    expect(type.numeralXl.fontFamily, 'InterDisplay');
    expect(type.numeralXl.fontWeight, FontWeight.w300);
  });

  test('11% and 88% have the same width with Inter loaded', () async {
    await loadFont('InterDisplay', ['InterDisplay-Light.ttf']);
    expect(
      widthOf('11%', type.numeralXl),
      closeTo(widthOf('88%', type.numeralXl), 0.01),
    );
  });

  test('maps onto the shadcn text theme with the Inter family', () {
    final shad = type.toShadTextTheme();
    expect(shad.family, 'Inter');
    expect(shad.p.fontSize, type.body.fontSize);
    expect(shad.h1.fontSize, type.h1.fontSize);
  });

  test('registers the Inter license', () async {
    registerKzLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    expect(entries.any((e) => e.packages.contains('Inter')), isTrue);
  });
}
