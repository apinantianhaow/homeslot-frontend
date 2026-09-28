import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/booking_tile.dart';
import '../widgets/common.dart';
import 'booking_actions.dart';
import 'booking_form_screen.dart';

/// Screen 3: what every room is doing right now and the user's next
/// bookings (SRS 2.3.9). Tapping a room starts a booking.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final me = ref.watch(meProvider).value;
    final status = ref.watch(roomStatusProvider);
    final upcoming = ref.watch(myBookingsProvider(true));
    final pending = ref.watch(pendingApprovalsProvider).value ?? const [];
    final unread = ref.watch(unreadCountProvider);
    final isOwner = ref.watch(isOwnerProvider);

    Future<void> refresh() async {
      ref.invalidate(roomStatusProvider);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(pendingApprovalsProvider);
      await ref.read(roomStatusProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(me?.household?.name ?? s.appName),
        actions: [
          IconButton(
            tooltip: s.notifications,
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ensureOnline(context, ref)) context.push('/book');
        },
        icon: const Icon(Icons.add),
        label: Text(s.book),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      s.hello(me?.user.displayName ?? ''),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (isOwner && pending.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.pending_actions),
                          title: Text(s.pendingRequests(pending.length)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/approvals'),
                        ),
                      ),
                    ),
                  SectionHeader(s.roomsNow),
                  AsyncView(
                    value: status,
                    onRetry: () => ref.invalidate(roomStatusProvider),
                    data: (rooms) => rooms.isEmpty
                        ? EmptyState(
                            icon: Icons.meeting_room_outlined,
                            text: isOwner
                                ? '${s.noRooms}\n${s.noRoomsOwnerHint}'
                                : s.noRooms,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                for (final r in rooms)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _RoomStatusCard(status: r),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  SectionHeader(s.myNextBookings),
                  AsyncView(
                    value: upcoming,
                    onRetry: () => ref.invalidate(myBookingsProvider),
                    data: (list) => list.isEmpty
                        ? EmptyState(
                            icon: Icons.event_available,
                            text: s.noUpcoming,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                for (final v in list.take(3))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: BookingTile(
                                      view: v,
                                      onTap: () => BookingActions.showDetails(
                                        context,
                                        ref,
                                        v,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStatusCard extends ConsumerWidget {
  const _RoomStatusCard({required this.status});

  final RoomStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final time = ref.watch(houseTimeProvider);
    final scheme = Theme.of(context).colorScheme;
    final current = status.current;
    final next = status.next;

    final (label, color) = status.closure != null
        ? (s.statusClosed(status.closure!.reason), scheme.error)
        : current != null
        ? (
            s.statusBusyUntil(
              current.userName,
              time.endHm(current.booking.endAt, current.booking.startAt),
            ),
            scheme.error,
          )
        : !status.openNow
        ? (s.statusNotOpen, scheme.outline)
        : (s.statusFree, Colors.green.shade600);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!ensureOnline(context, ref)) return;
          context.push('/book', extra: BookingFormArgs(roomId: status.room.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RoomAvatar(room: status.room),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.room.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(color: color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next == null
                          ? s.noNextBooking
                          : s.nextBooking(
                              time.range(
                                next.booking.startAt,
                                next.booking.endAt,
                              ),
                              next.userName,
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline),
            ],
          ),
        ),
      ),
    );
  }
}
