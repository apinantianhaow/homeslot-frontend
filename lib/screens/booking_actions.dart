import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import '../core/colors.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'booking_form_screen.dart';

/// Edit, cancel and release actions shared by the calendar and "My
/// bookings" (SRS 2.3.6, 2.3.7).
abstract final class BookingActions {
  static bool canChange(BookingView view, int? myUserId) =>
      view.booking.userId == myUserId &&
      (view.booking.status == BookingStatus.pending ||
          view.booking.status == BookingStatus.confirmed) &&
      view.booking.startAt.isAfter(DateTime.now());

  static bool canRelease(BookingView view, int? myUserId) {
    final now = DateTime.now();
    final b = view.booking;
    return b.userId == myUserId &&
        b.status == BookingStatus.confirmed &&
        !b.startAt.isAfter(now) &&
        b.endAt.isAfter(now);
  }

  static void edit(BuildContext context, WidgetRef ref, BookingView view) {
    if (!ensureOnline(context, ref)) return;
    context.push('/book', extra: BookingFormArgs(edit: view));
  }

  /// Asks whether to apply to one booking or the whole weekly series.
  static Future<EditScope?> askScope(BuildContext context) {
    final s = context.s;
    return showDialog<EditScope>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.scopeTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, EditScope.single),
            child: Text(s.scopeSingle),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, EditScope.series),
            child: Text(s.scopeSeries),
          ),
        ],
      ),
    );
  }

  static Future<void> cancel(
    BuildContext context,
    WidgetRef ref,
    BookingView view,
  ) async {
    if (!ensureOnline(context, ref)) return;
    final s = context.s;
    var scope = EditScope.single;
    if (view.booking.seriesId != null) {
      final picked = await askScope(context);
      if (picked == null) return;
      scope = picked;
    } else if (!context.mounted ||
        !await confirmDialog(
          context,
          message: s.cancelConfirm,
          confirmLabel: s.cancelBooking,
          destructive: true,
        )) {
      return;
    }
    try {
      final count = await client.booking.cancel(view.booking.id!, scope, null);
      _refresh(ref);
      if (context.mounted) showMessage(context, s.cancelled(count));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static Future<void> release(
    BuildContext context,
    WidgetRef ref,
    BookingView view,
  ) async {
    if (!ensureOnline(context, ref)) return;
    final s = context.s;
    if (!await confirmDialog(
      context,
      message: s.releaseConfirm,
      confirmLabel: s.releaseRoom,
    )) {
      return;
    }
    try {
      await client.booking.release(view.booking.id!);
      _refresh(ref);
      if (context.mounted) showMessage(context, s.released);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static void _refresh(WidgetRef ref) {
    ref.invalidate(calendarProvider);
    ref.invalidate(myBookingsProvider);
    ref.invalidate(roomStatusProvider);
  }

  /// Details of a booking with the actions the user may take.
  static Future<void> showDetails(
    BuildContext context,
    WidgetRef ref,
    BookingView view,
  ) {
    final s = context.s;
    final time = ref.read(houseTimeProvider);
    final myId = ref.read(myUserIdProvider);
    final b = view.booking;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      view.roomName,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(b.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(time.range(b.startAt, b.endAt)),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: hexColor(view.userColor),
                  ),
                  const SizedBox(width: 8),
                  Text(s.bookedBy(view.userName)),
                ],
              ),
              if (b.purpose != null) ...[
                const SizedBox(height: 8),
                Text('${s.purpose}: ${b.purpose}'),
              ],
              if (b.note != null) ...[
                const SizedBox(height: 4),
                Text('${s.note}: ${b.note}'),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canChange(view, myId)) ...[
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        edit(context, ref, view);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(s.edit),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        cancel(context, ref, view);
                      },
                      icon: const Icon(Icons.close),
                      label: Text(s.cancelBooking),
                    ),
                  ],
                  if (canRelease(view, myId))
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        release(context, ref, view);
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(s.releaseRoom),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
