import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bud.dart';
import 'earbuds_providers.dart';

/// The earbud currently playing the locating sound. Auto-disposed: when
/// nobody watches it any more (the page was left) the sound is stopped.
class FindSoundNotifier extends Notifier<Bud?> {
  Bud? _playing;

  @override
  Bud? build() {
    final port = ref.watch(earbudsPortProvider);
    ref.onDispose(() {
      if (_playing != null) unawaited(port.stopFindSound());
    });
    return null;
  }

  Future<void> play(Bud bud) async {
    await ref.read(earbudsPortProvider).playFindSound(bud);
    _playing = bud;
    state = bud;
  }

  Future<void> stop() async {
    await ref.read(earbudsPortProvider).stopFindSound();
    _playing = null;
    state = null;
  }
}

final findSoundProvider = NotifierProvider.autoDispose<FindSoundNotifier, Bud?>(
  FindSoundNotifier.new,
);
