import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import 'data.dart';
import 'session.dart';

/// Keeps a WebSocket stream open to the server and refreshes the affected
/// data when someone books, edits or cancels (SRS 2.3.8), so no manual
/// refresh is needed. Reconnects with back-off.
final realtimeProvider = NotifierProvider<RealtimeNotifier, bool>(
  RealtimeNotifier.new,
);

class RealtimeNotifier extends Notifier<bool> {
  StreamSubscription<HouseholdEvent>? _subscription;
  Timer? _retryTimer;
  int _attempt = 0;

  @override
  bool build() {
    final signedIn = ref.watch(signedInProvider);
    // Resubscribe when the household changes: the server picks the channel.
    ref.watch(householdIdProvider);
    ref.onDispose(_stop);

    void onConnectivity(bool connected) {
      if (connected && ref.mounted && ref.read(signedInProvider)) {
        refreshAll(ref.invalidate);
        _connect();
      }
    }

    client.connectivityMonitor?.addListener(onConnectivity);
    ref.onDispose(
      () => client.connectivityMonitor?.removeListener(onConnectivity),
    );

    if (signedIn) Future.microtask(_connect);
    return false;
  }

  void _connect() {
    if (!ref.mounted) return;
    _retryTimer?.cancel();
    _subscription?.cancel();
    _subscription = client.events.subscribe().listen(
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
    switch (event.type) {
      case HouseholdEventType.bookingsChanged:
        ref.invalidate(calendarProvider);
        ref.invalidate(myBookingsProvider);
        ref.invalidate(roomStatusProvider);
        ref.invalidate(pendingApprovalsProvider);
      case HouseholdEventType.roomsChanged:
        ref.invalidate(roomsProvider);
        ref.invalidate(roomStatusProvider);
        ref.invalidate(calendarProvider);
      case HouseholdEventType.membersChanged:
        ref.invalidate(membersProvider);
        ref.invalidate(meProvider);
        ref.invalidate(calendarProvider);
        ref.invalidate(roomStatusProvider);
      case HouseholdEventType.householdChanged:
        ref.invalidate(meProvider);
      case HouseholdEventType.notification:
        ref.invalidate(notificationsProvider);
        ref.invalidate(pendingApprovalsProvider);
        ref.invalidate(meProvider);
    }
  }

  void _stop() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }
}
