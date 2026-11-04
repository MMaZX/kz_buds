import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/find_target.dart';
import 'earbuds_providers.dart';

/// What is currently playing the locating sound. Auto-disposed: when nobody
/// watches it any more (the page was left) the sound is stopped.
class FindSoundNotifier extends Notifier<FindTarget?> {
  FindTarget? _playing;

  @override
  FindTarget? build() {
    final port = ref.watch(earbudsPortProvider);
    ref.onDispose(() {
      if (_playing != null) unawaited(port.stopFindSound());
    });
    return null;
  }

  Future<void> play(FindTarget target) async {
    await ref.read(earbudsPortProvider).playFindSound(target);
    _playing = target;
    state = target;
  }

  Future<void> stop() async {
    await ref.read(earbudsPortProvider).stopFindSound();
    _playing = null;
    state = null;
  }
}

final findSoundProvider =
    NotifierProvider.autoDispose<FindSoundNotifier, FindTarget?>(
      FindSoundNotifier.new,
    );
