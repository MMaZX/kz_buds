import 'dart:async';
import 'dart:math';

import '../../domain/entities/link_state.dart';

/// Keeps the control session up while the OS has the earbuds connected.
///
/// It never forces a connection on its own: when the OS does not have the
/// earbuds it waits for the OS to connect them (forcing one every few
/// seconds would page the radio and pull the audio away from a phone).
/// When the OS connects them it tries at once; while the OS has them and the
/// session is down it retries after a random delay in [minDelay, maxDelay)
/// (bounded full jitter). One attempt runs at a time. Everything is timers
/// and futures on the calling isolate; the blocking work lives in the link.
class ReconnectSupervisor {
  ReconnectSupervisor({
    required this._osLink,
    required Stream<LinkState> session,
    required this._connect,
    Random? random,
    this.minDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(seconds: 10),
    this.onError,
    this.log,
  }) : _sessionStates = session,
       _random = random ?? Random();

  final Stream<bool> _osLink;
  final Stream<LinkState> _sessionStates;
  final Future<void> Function() _connect;
  final Random _random;
  final Duration minDelay;
  final Duration maxDelay;

  /// Called with every failed attempt.
  final void Function(Object error)? onError;

  /// Called with a short line for every state change and decision.
  final void Function(String message)? log;

  final _subscriptions = <StreamSubscription<Object?>>[];
  bool? _osUp;
  LinkState? _session;
  Timer? _retry;
  bool _attempting = false;
  bool _stopped = false;

  void start() {
    _subscriptions
      ..add(_sessionStates.listen(_onSession))
      ..add(
        _osLink.listen(
          _onOs,
          onError: (Object error) => log?.call('OS link watch failed: $error'),
        ),
      );
  }

  Future<void> stop() async {
    _stopped = true;
    _cancelRetry();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  bool get _sessionDown => _session == LinkState.disconnected;

  void _onOs(bool up) {
    final wasUp = _osUp;
    _osUp = up;
    log?.call('OS link: ${up ? 'connected' : 'disconnected'}');
    if (!up) {
      _cancelRetry();
    } else if (wasUp != true && _sessionDown) {
      _attempt();
    }
  }

  void _onSession(LinkState state) {
    final previous = _session;
    _session = state;
    log?.call('session: ${state.name}');
    if (state != LinkState.disconnected) {
      _cancelRetry();
    } else if (previous != null &&
        previous != LinkState.disconnected &&
        _osUp == true) {
      _schedule();
    }
  }

  void _attempt() {
    if (_attempting || _stopped) return;
    _cancelRetry();
    _attempting = true;
    log?.call('attempt: connecting');
    unawaited(
      _connect()
          .then((_) => log?.call('attempt: connected'))
          .catchError((Object error) {
            log?.call('attempt failed: $error');
            onError?.call(error);
          })
          .whenComplete(() {
            _attempting = false;
            if (_osUp == true && _sessionDown) _schedule();
          }),
    );
  }

  void _schedule() {
    if (_attempting || _stopped || _retry != null) return;
    final spread = maxDelay - minDelay;
    final delay = minDelay + spread * _random.nextDouble();
    log?.call('retry in ${(delay.inMilliseconds / 1000).toStringAsFixed(1)} s');
    _retry = Timer(delay, () {
      _retry = null;
      _attempt();
    });
  }

  void _cancelRetry() {
    _retry?.cancel();
    _retry = null;
  }
}
