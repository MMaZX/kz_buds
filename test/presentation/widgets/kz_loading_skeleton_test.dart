import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/presentation/theme/kz_icons.dart';
import 'package:kz_buds/presentation/widgets/kz_loading_skeleton.dart';

import '../../support/pump_kz.dart';

void main() {
  group('kzSkeletonFrame', () {
    const count = 4;

    test('starts each icon invisible and large', () {
      final frame = kzSkeletonFrame(0, count);
      expect(frame.index, 0);
      expect(frame.opacity, 0);
      expect(frame.scale, closeTo(KzLoadingSkeleton.maxScale, 1e-9));
    });

    test('holds the icon fully visible mid-slot', () {
      final frame = kzSkeletonFrame(0.5 / count, count);
      expect(frame.index, 0);
      expect(frame.opacity, 1);
    });

    test('fades out at the end of the slot and moves on', () {
      expect(kzSkeletonFrame(0.999 / count, count).opacity, lessThan(0.01));
      expect(kzSkeletonFrame(1.5 / count, count).index, 1);
      expect(kzSkeletonFrame(3.5 / count, count).index, 3);
    });

    test('shrinks steadily from large to small within a slot', () {
      final scales = [
        for (var t = 0.0; t < 1; t += 0.1)
          kzSkeletonFrame(t / count, count).scale,
      ];
      for (var i = 1; i < scales.length; i++) {
        expect(scales[i], lessThanOrEqualTo(scales[i - 1]));
      }
      expect(scales.first, greaterThan(1));
      expect(scales.last, lessThan(1));
    });
  });

  group('KzLoadingSkeleton', () {
    KzIconData shownIcon(WidgetTester tester) =>
        tester.widget<KzIcon>(find.byType(KzIcon)).icon;

    testWidgets('changes icon every period and explains the wait', (
      tester,
    ) async {
      await pumpKz(
        tester,
        const SizedBox.square(
          dimension: 300,
          child: KzLoadingSkeleton(label: 'Connecting to your earbuds'),
        ),
        settle: false,
      );

      expect(find.text('Connecting to your earbuds'), findsOneWidget);
      expect(shownIcon(tester), KzLoadingSkeleton.icons[0]);

      await tester.pump(KzLoadingSkeleton.iconPeriod);
      expect(shownIcon(tester), KzLoadingSkeleton.icons[1]);

      await tester.pump(KzLoadingSkeleton.iconPeriod);
      expect(shownIcon(tester), KzLoadingSkeleton.icons[2]);
    });

    testWidgets('stays still with reduced motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await pumpKz(
        tester,
        const SizedBox.square(
          dimension: 300,
          child: KzLoadingSkeleton(label: 'Connecting to your earbuds'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(KzLoadingSkeleton.iconPeriod * 2);

      expect(shownIcon(tester), KzLoadingSkeleton.icons[0]);
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byType(KzIcon), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1);
    });
  });
}
