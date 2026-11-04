import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_color_scheme.dart';
import 'package:kz_buds/presentation/theme/kz_colors.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const dark = KzColorScheme.dark();
  const light = KzColorScheme.light();

  test('dark and light pin the key tokens', () {
    expect(dark.background, const Color(0xFF000000));
    expect(light.background, const Color(0xFFF5F5F5));
    expect(dark.ring, const Color(0xFFE22B33));
    expect(light.ring, const Color(0xFFC8102E));
    expect(dark.primary, dark.foreground);
    expect(light.primary, light.foreground);
  });

  test('surfaces are truly neutral grays (R = G = B)', () {
    for (final s in [dark, light]) {
      for (final color in [
        s.background,
        s.foreground,
        s.card,
        s.popover,
        s.secondary,
        s.muted,
        s.mutedForeground,
        s.accent,
        s.border,
        s.input,
      ]) {
        final r = (color.r * 255).round();
        final g = (color.g * 255).round();
        final b = (color.b * 255).round();
        expect(r == g && g == b, isTrue, reason: '$color is tinted');
      }
    }
  });

  for (final entry in {'dark': dark, 'light': light}.entries) {
    final name = entry.key;
    final s = entry.value;

    group('contrast ($name)', () {
      test('foreground, muted and destructive read on background and card', () {
        for (final surface in [s.background, s.card]) {
          expect(contrast(s.foreground, surface), greaterThanOrEqualTo(4.5));
          expect(
            contrast(s.mutedForeground, surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(contrast(s.destructive, surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('primaryForeground reads on primary', () {
        expect(
          contrast(s.primaryForeground, s.primary),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('input boundary on card and ring on background reach 3:1', () {
        expect(contrast(s.input, s.card), greaterThanOrEqualTo(3.0));
        expect(contrast(s.ring, s.background), greaterThanOrEqualTo(3.0));
      });

      test('brandForeground reads on brand', () {
        final colors = KzColors(s);
        expect(
          contrast(colors.brandForeground, colors.brand),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('cards separate from the background by fill, not stroke', () {
        expect(s.card, isNot(s.background));
        expect(s.secondary, isNot(s.card));
      });

      test('brand text reads on background', () {
        expect(
          contrast(KzColors(s).brand, s.background),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }

  group('KzColors.battery', () {
    final colors = KzColors(dark);

    test('0 to 20 is critical, 21 to 100 is neutral', () {
      expect(colors.battery(0), colors.batteryCritical);
      expect(colors.battery(20), colors.batteryCritical);
      expect(colors.battery(21), colors.batteryOk);
      expect(colors.battery(100), colors.batteryOk);
    });

    test('healthy battery is neutral, not green or the accent', () {
      expect(colors.batteryOk, dark.foreground);
      expect(colors.batteryOk, isNot(colors.brand));
    });
  });
}
