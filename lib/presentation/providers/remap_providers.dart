import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bud.dart';

enum TouchGesture {
  singleTap('Single tap'),
  doubleTap('Double tap'),
  tripleTap('Triple tap'),
  longPress('Long press');

  const TouchGesture(this.label);
  final String label;
}

/// Placeholder action set until Phase 2 reports what the device supports.
enum TouchAction {
  playPause('Play / pause'),
  nextTrack('Next track'),
  previousTrack('Previous track'),
  volumeUp('Volume up'),
  volumeDown('Volume down'),
  noiseControl('Noise control'),
  voiceAssistant('Voice assistant'),
  none('None');

  const TouchAction(this.label);
  final String label;
}

class RemapState {
  const RemapState(this._actions);

  final Map<Bud, Map<TouchGesture, TouchAction>> _actions;

  TouchAction actionFor(Bud bud, TouchGesture gesture) =>
      _actions[bud]![gesture]!;
}

const _defaults = <TouchGesture, TouchAction>{
  TouchGesture.singleTap: TouchAction.playPause,
  TouchGesture.doubleTap: TouchAction.nextTrack,
  TouchGesture.tripleTap: TouchAction.previousTrack,
  TouchGesture.longPress: TouchAction.noiseControl,
};

/// UI-only until the protocol is known (Phase 2).
class RemapNotifier extends Notifier<RemapState> {
  @override
  RemapState build() =>
      RemapState({for (final bud in Bud.values) bud: Map.of(_defaults)});

  void setAction(Bud bud, TouchGesture gesture, TouchAction action) {
    state = RemapState({
      for (final b in Bud.values)
        b: {...state._actions[b]!, if (b == bud) gesture: action},
    });
  }
}

final touchRemapProvider = NotifierProvider<RemapNotifier, RemapState>(
  RemapNotifier.new,
);
