import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import 'data.dart';
import 'session.dart';

/// Opens the server's stream of household events (replaced in tests).
final householdEventsProvider = Provider<Stream<HouseholdEvent> Function()>(
  (ref) => client.events.subscribe,
);

/// Reports when the network comes back, if the platform can tell (replaced
/// in tests).
final connectivityMonitorProvider = Provider<ConnectivityMonitor?>(
  (ref) => client.connectivityMonitor,
);

/// Keeps a WebSocket stream open to the server and refreshes the affected
/// data when someone books, edits or cancels (SRS 2.3.8), so no manual
/// refresh is needed. Reconnects with back-off.
final realtimeProvider = NotifierProvider<RealtimeNotifier, bool>(
  RealtimeNotifier.new,
);

class RealtimeNotifier extends Notifier<bool> {
  /// Events that arrive together (one action often sends several, e.g.
  /// "members changed" and "bookings changed") refresh each list once.
  static const _coalesce = Duration(milliseconds: 200);

  /// A connection that stayed up this long starts the back-off again.
  static const _stableAfter = Duration(seconds: 30);

  /// Time in the background after which events may have been missed.
  static const _staleAfter = Duration(seconds: 30);

  StreamSubscription<HouseholdEvent>? _subscription;
  Timer? _retryTimer;
  Timer? _flushTimer;
  final _pending = <ProviderOrFamily>{};
  int _attempt = 0;
  DateTime? _connectedAt;
  DateTime? _hiddenAt;

  @override
  bool build() {
    final signedIn = ref.watch(signedInProvider);
    // Resubscribe when the household changes: the server picks the channel.
    ref.watch(householdIdProvider);
    ref.onDispose(_stop);

    void onConnectivity(bool connected) {
      if (connected && ref.mounted && ref.read(signedInProvider)) {
        _reconnectNow();
      }
    }

    final connectivity = ref.watch(connectivityMonitorProvider);
    connectivity?.addListener(onConnectivity);
    ref.onDispose(() => connectivity?.removeListener(onConnectivity));

    // Phones drop the sockets of apps in the background, often without the
    // stream noticing. Coming back after a while reconnects and refreshes at
    // once instead of showing old data until the back-off timer fires.
    final lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = clock.now(),
      onShow: _onShow,
    );
    ref.onDispose(lifecycle.dispose);

    if (signedIn) Future.microtask(_connect);
    return false;
  }

  void _onShow() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || !ref.mounted || !ref.read(signedInProvider)) {
      return;
    }
    if (!state || clock.now().difference(hiddenAt) > _staleAfter) {
      _reconnectNow();
    } else {
      // "In use" and "free" depend on the clock, not only on events.
      ref.invalidate(roomStatusProvider);
    }
  }

  void _reconnectNow() {
    _attempt = 0;
    // Events may have been missed while disconnected.
    refreshAll(ref.invalidate);
    _connect();
  }

  void _connect() {
    if (!ref.mounted) return;
    _retryTimer?.cancel();
    _subscription?.cancel();
    _connectedAt = clock.now();
    _subscription = ref
        .read(householdEventsProvider)()
        .listen(
          _onEvent,
          onError: (Object _) => _scheduleRetry(),
          onDone: _scheduleRetry,
          cancelOnError: true,
        );
    state = true;
  }

  void _scheduleRetry() {
    if (!ref.mounted) return;
    state = false;
    _retryTimer?.cancel();
    final connectedAt = _connectedAt;
    if (connectedAt != null &&
        clock.now().difference(connectedAt) > _stableAfter) {
      // The connection worked; a network blip should be recovered quickly,
      // not after the longest back-off.
      _attempt = 0;
    }
    final seconds = min(30, 1 << min(_attempt, 5));
    _attempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (!ref.mounted || !ref.read(signedInProvider)) return;
      // Events may have been missed while disconnected.
      refreshAll(ref.invalidate);
      _connect();
    });
  }

  void _onEvent(HouseholdEvent event) {
    _attempt = 0;
    _pending.addAll(switch (event.type) {
      HouseholdEventType.bookingsChanged => [
        calendarProvider,
        myBookingsProvider,
        roomStatusProvider,
        pendingApprovalsProvider,
      ],
      HouseholdEventType.roomsChanged => [
        roomsProvider,
        roomStatusProvider,
        calendarProvider,
      ],
      HouseholdEventType.membersChanged => [
        membersProvider,
        meProvider,
        calendarProvider,
        roomStatusProvider,
      ],
      HouseholdEventType.householdChanged => [meProvider],
      HouseholdEventType.notification => [
        notificationsProvider,
        pendingApprovalsProvider,
        meProvider,
      ],
    });
    _flushTimer ??= Timer(_coalesce, _flush);
  }

  void _flush() {
    _flushTimer = null;
    if (!ref.mounted) return;
    final providers = _pending.toList();
    _pending.clear();
    for (final provider in providers) {
      ref.invalidate(provider);
    }
  }

  void _stop() {
    _retryTimer?.cancel();
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
    _subscription?.cancel();
    _subscription = null;
  }
}
