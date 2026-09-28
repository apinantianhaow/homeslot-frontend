import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/booking_tile.dart';
import '../widgets/common.dart';
import 'booking_actions.dart';

/// Screen 6: "upcoming" and "past" bookings with edit, cancel and release
/// (SRS 2.3.6, 2.3.7, 2.6.1).
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.navBookings),
          bottom: TabBar(
            tabs: [
              Tab(text: s.upcoming),
              Tab(text: s.past),
            ],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            const Expanded(
              child: TabBarView(
                children: [
                  _BookingList(upcoming: true),
                  _BookingList(upcoming: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final myId = ref.watch(myUserIdProvider);
    final value = ref.watch(myBookingsProvider(upcoming));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBookingsProvider(upcoming).future),
      child: AsyncView(
        value: value,
        onRetry: () => ref.invalidate(myBookingsProvider(upcoming)),
        data: (list) => list.isEmpty
            ? ListView(
                children: [
                  EmptyState(
                    icon: upcoming ? Icons.event_available : Icons.history,
                    text: upcoming ? s.noUpcoming : s.noPast,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final view = list[i];
                  final canChange = BookingActions.canChange(view, myId);
                  final canRelease = BookingActions.canRelease(view, myId);
                  return BookingTile(
                    view: view,
                    onTap: () => BookingActions.showDetails(context, ref, view),
                    trailing: !upcoming || (!canChange && !canRelease)
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (action) => switch (action) {
                              'edit' => BookingActions.edit(context, ref, view),
                              'cancel' => BookingActions.cancel(
                                context,
                                ref,
                                view,
                              ),
                              _ => BookingActions.release(context, ref, view),
                            },
                            itemBuilder: (_) => [
                              if (canChange) ...[
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(s.edit),
                                ),
                                PopupMenuItem(
                                  value: 'cancel',
                                  child: Text(s.cancelBooking),
                                ),
                              ],
                              if (canRelease)
                                PopupMenuItem(
                                  value: 'release',
                                  child: Text(s.releaseRoom),
                                ),
                            ],
                          ),
                  );
                },
              ),
      ),
    );
  }
}
