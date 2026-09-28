import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import '../data/cached.dart';
import 'session.dart';

/// All data providers depend on the current household so they reset when
/// the user joins, leaves or signs out.

final roomsProvider = FutureProvider<List<RoomDetail>>((ref) async {
  if (ref.watch(householdIdProvider) == null) return [];
  return cachedFetch(ref, 'rooms', () => client.room.list());
});

final roomStatusProvider = FutureProvider<List<RoomStatus>>((ref) async {
  if (ref.watch(householdIdProvider) == null) return [];
  return cachedFetch(ref, 'status', () => client.room.statusNow());
});

typedef CalendarQuery = ({int? roomId, DateTime from, DateTime to});

final calendarProvider = FutureProvider.autoDispose
    .family<List<BookingView>, CalendarQuery>((ref, q) async {
      if (ref.watch(householdIdProvider) == null) return [];
      return cachedFetch(
        ref,
        'calendar:${q.roomId}:${q.from.toIso8601String()}:${q.to.toIso8601String()}',
        () => client.booking.list(q.from, q.to, q.roomId),
      );
    });

/// Upcoming (true) or past (false) bookings of the signed-in user.
final myBookingsProvider = FutureProvider.family<List<BookingView>, bool>((
  ref,
  upcoming,
) async {
  if (ref.watch(householdIdProvider) == null) return [];
  return cachedFetch(
    ref,
    'mine:$upcoming',
    () => client.booking.mine(upcoming, 100, 0),
  );
});

final pendingApprovalsProvider = FutureProvider<List<BookingView>>((ref) async {
  if (ref.watch(householdIdProvider) == null || !ref.watch(isOwnerProvider)) {
    return [];
  }
  return cachedFetch(ref, 'pending', () => client.booking.pending());
});

final membersProvider = FutureProvider<List<MemberInfo>>((ref) async {
  if (ref.watch(householdIdProvider) == null) return [];
  return cachedFetch(ref, 'members', () => client.household.members());
});

final invitesProvider = FutureProvider.autoDispose<List<Invitation>>((
  ref,
) async {
  if (!ref.watch(isOwnerProvider)) return [];
  return client.household.activeInvites();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  if (!ref.watch(signedInProvider)) return [];
  ref.watch(householdIdProvider);
  return cachedFetch(ref, 'notifications', () => client.notification.list());
});

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).value ?? const [];
  return list.where((n) => n.readAt == null).length;
});

typedef UsageQuery = ({StatsPeriod period, DateTime anchor});

final usageProvider = FutureProvider.autoDispose.family<UsageStats, UsageQuery>(
  (ref, q) => client.stats.usage(q.period, q.anchor),
);

final peakHoursProvider = FutureProvider.autoDispose.family<PeakHours, int?>(
  (ref, roomId) => client.stats.peakHours(roomId, 30),
);

/// Refreshes every data provider, e.g. after reconnecting.
/// Pass `ref.invalidate` from a `Ref` or `WidgetRef`.
void refreshAll(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(meProvider);
  invalidate(roomsProvider);
  invalidate(roomStatusProvider);
  invalidate(calendarProvider);
  invalidate(myBookingsProvider);
  invalidate(pendingApprovalsProvider);
  invalidate(membersProvider);
  invalidate(notificationsProvider);
}
