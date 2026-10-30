import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_buds/domain/entities/bud.dart';
import 'package:kz_buds/presentation/providers/remap_providers.dart';

void main() {
  late ProviderContainer container;
  late RemapNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(touchRemapProvider.notifier);
  });

  RemapState state() => container.read(touchRemapProvider);

  test('every bud has an action for every gesture', () {
    for (final bud in Bud.values) {
      for (final gesture in TouchGesture.values) {
        expect(state().actionFor(bud, gesture), isNotNull);
      }
    }
  });

  test('changing one gesture leaves the rest untouched', () {
    final before = state().actionFor(Bud.left, TouchGesture.doubleTap);
    notifier.setAction(Bud.left, TouchGesture.singleTap, TouchAction.none);
    expect(
      state().actionFor(Bud.left, TouchGesture.singleTap),
      TouchAction.none,
    );
    expect(state().actionFor(Bud.left, TouchGesture.doubleTap), before);
  });

  test('buds are independent', () {
    final rightBefore = state().actionFor(Bud.right, TouchGesture.longPress);
    notifier.setAction(Bud.left, TouchGesture.longPress, TouchAction.volumeUp);
    expect(
      state().actionFor(Bud.left, TouchGesture.longPress),
      TouchAction.volumeUp,
    );
    expect(state().actionFor(Bud.right, TouchGesture.longPress), rightBefore);
  });

  test('every action has a label', () {
    for (final action in TouchAction.values) {
      expect(action.label, isNotEmpty);
    }
    for (final gesture in TouchGesture.values) {
      expect(gesture.label, isNotEmpty);
    }
  });
}
