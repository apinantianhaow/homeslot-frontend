import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/state/data.dart';
import 'package:homeslot/state/realtime.dart';
import 'package:homeslot/state/session.dart';
import 'package:homeslot_client/homeslot_client.dart';

/// The real-time connection (SRS 2.3.8): which lists reload after events,
/// and what happens when the app goes to the background and comes back or
/// the connection drops.
void main() {
  late ProviderContainer container;

  /// One stream per connection the app opened.
  late List<StreamController<HouseholdEvent>> connections;

  /// How often each list was loaded from the server.
  late Map<String, int> loads;

  void start() {
    connections = [];
    loads = {};
    void load(String name) => loads[name] = (loads[name] ?? 0) + 1;
    container = ProviderContainer(
      overrides: [
        signedInProvider.overrideWith(_SignedIn.new),
        householdIdProvider.overrideWithValue(1),
        connectivityMonitorProvider.overrideWithValue(null),
        householdEventsProvider.overrideWithValue(() {
          final connection = StreamController<HouseholdEvent>();
          connections.add(connection);
          return connection.stream;
        }),
        meProvider.overrideWith(_Me.new),
        roomsProvider.overrideWith((ref) async {
          load('rooms');
          return [];
        }),
        roomStatusProvider.overrideWith((ref) async {
          load('status');
          return [];
        }),
        calendarProvider.overrideWith((ref, query) async {
          load('calendar');
          return [];
        }),
        myBookingsProvider.overrideWith((ref, upcoming) async {
          load('mine');
          return [];
        }),
        pendingApprovalsProvider.overrideWith((ref) async {
          load('pending');
          return [];
        }),
        membersProvider.overrideWith((ref) async {
          load('members');
          return [];
        }),
        notificationsProvider.overrideWith((ref) async {
          load('notifications');
          return [];
        }),
      ],
    );
    // Like the app: the connection is open and the screens show the lists.
    container.listen(realtimeProvider, (_, _) {});
    final week = (
      roomId: 1,
      from: DateTime.utc(2030, 1, 7),
      to: DateTime.utc(2030, 1, 14),
    );
    for (final ProviderListenable<Object?> list in [
      roomsProvider,
      roomStatusProvider,
      calendarProvider(week),
      myBookingsProvider(true),
      pendingApprovalsProvider,
      membersProvider,
      notificationsProvider,
    ]) {
      container.listen(list, (_, _) {});
    }
  }

  HouseholdEvent event(HouseholdEventType type) =>
      HouseholdEvent(type: type, at: DateTime.utc(2030));

  void toBackground(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  void toForeground(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('events that arrive together reload each list once', (
    tester,
  ) async {
    start();
    await tester.pump();
    expect(connections, hasLength(1));
    final before = Map.of(loads);

    connections.last
      ..add(event(HouseholdEventType.bookingsChanged))
      ..add(event(HouseholdEventType.membersChanged))
      ..add(event(HouseholdEventType.bookingsChanged));
    await tester.pump(const Duration(milliseconds: 100));
    expect(loads, before, reason: 'waits briefly for more events');

    await tester.pump(const Duration(milliseconds: 150));
    for (final name in ['status', 'calendar', 'mine', 'pending', 'members']) {
      expect(loads[name], before[name]! + 1, reason: name);
    }
    expect(loads['rooms'], before['rooms'], reason: 'rooms did not change');
    expect(loads['notifications'], before['notifications']);
    container.dispose();
  });

  testWidgets('a short trip to the background reloads only the room status', (
    tester,
  ) async {
    start();
    await tester.pump();
    final before = Map.of(loads);

    toBackground(tester);
    await tester.pump(const Duration(seconds: 5));
    toForeground(tester);
    // Riverpod reloads invalidated providers in a zero-length timer.
    await tester.pump(Duration.zero);

    expect(connections, hasLength(1), reason: 'the connection is kept');
    expect(loads['status'], before['status']! + 1);
    expect(loads['calendar'], before['calendar']);
    container.dispose();
  });

  testWidgets('coming back after a while reconnects and reloads everything', (
    tester,
  ) async {
    start();
    await tester.pump();
    final before = Map.of(loads);

    toBackground(tester);
    await tester.pump(const Duration(minutes: 5));
    toForeground(tester);
    // Riverpod reloads invalidated providers in a zero-length timer.
    await tester.pump(Duration.zero);

    expect(connections, hasLength(2), reason: 'events may have been missed');
    for (final name in before.keys) {
      expect(loads[name], before[name]! + 1, reason: name);
    }
    container.dispose();
  });

  testWidgets('a connection that worked for a while retries after 1 s', (
    tester,
  ) async {
    start();
    await tester.pump();

    // Failing right after connecting backs off: 1 s, then 2 s.
    connections.last.addError(Exception('offline'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(connections, hasLength(2));
    connections.last.addError(Exception('offline'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(connections, hasLength(2), reason: 'the second retry waits longer');
    await tester.pump(const Duration(seconds: 1));
    expect(connections, hasLength(3));

    // This connection stays up, so when it drops the back-off starts over.
    await tester.pump(const Duration(minutes: 1));
    connections.last.addError(Exception('offline'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(connections, hasLength(4));
    container.dispose();
  });
}

class _SignedIn extends SignedInNotifier {
  @override
  bool build() => true;
}

class _Me extends MeNotifier {
  @override
  Future<MeInfo?> build() async => null;
}
