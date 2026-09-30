import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/l10n.dart';
import '../core/time.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../state/settings.dart';
import '../widgets/common.dart';
import '../widgets/timeline.dart';
import 'booking_actions.dart';
import 'booking_form_screen.dart';

/// Screen 4: day and week calendar of one room. Free, booked and closed
/// time is visible with the booker's name and color; tap a free slot to
/// book (SRS 2.3.1). Updates in real time (SRS 2.3.8).
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int? _roomId;

  /// Selected day as a UTC date (the form TableCalendar uses). Its
  /// year/month/day are read as a day in the household time zone.
  DateTime? _selected;
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final time = ref.watch(houseTimeProvider);
    final rooms = ref.watch(roomsProvider);
    final locale = ref.watch(settingsProvider).localeCode;
    final today = time.now();
    final selected =
        _selected ?? DateTime.utc(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.navCalendar),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(s.dayView)),
                ButtonSegment(value: true, label: Text(s.weekView)),
              ],
              selected: {_week},
              onSelectionChanged: (v) => setState(() => _week = v.first),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: AsyncView(
              value: rooms,
              onRetry: () => ref.invalidate(roomsProvider),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return EmptyState(
                    icon: Icons.meeting_room_outlined,
                    text: s.noRooms,
                  );
                }
                final detail = rooms.firstWhere(
                  (r) => r.room.id == _roomId,
                  orElse: () => rooms.first,
                );
                final day = time.day(
                  selected.year,
                  selected.month,
                  selected.day,
                );
                final weekStart = time.startOfWeek(day);
                final days = _week
                    ? [for (var i = 0; i < 7; i++) time.addDays(weekStart, i)]
                    : [day];
                final query = (
                  roomId: detail.room.id,
                  from: HouseTime.utc(weekStart),
                  to: HouseTime.utc(time.addDays(weekStart, 7)),
                );
                final bookings = ref.watch(calendarProvider(query));

                return Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final r in rooms)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                avatar: Icon(roomIcon(r.room.type), size: 18),
                                label: Text(r.room.name),
                                selected: r.room.id == detail.room.id,
                                onSelected: (_) =>
                                    setState(() => _roomId = r.room.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TableCalendar<void>(
                      locale: locale,
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 400)),
                      focusedDay: selected,
                      calendarFormat: CalendarFormat.week,
                      availableCalendarFormats: const {CalendarFormat.week: ''},
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      rowHeight: 44,
                      selectedDayPredicate: (d) => isSameDay(d, selected),
                      onDaySelected: (selected, _) =>
                          setState(() => _selected = selected),
                      onPageChanged: (focused) =>
                          setState(() => _selected = focused),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _week
                                  ? time.monthLabel(weekStart)
                                  : time.fullDay(day),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            s.tapToBook,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      // Another week keeps the timeline on screen (and its
                      // scroll position) while its bookings load, instead
                      // of swapping it for a spinner.
                      child: bookings.hasError && !bookings.hasValue
                          ? ErrorView(
                              error: bookings.error!,
                              onRetry: () =>
                                  ref.invalidate(calendarProvider(query)),
                            )
                          : Stack(
                              children: [
                                Timeline(
                                  key: ValueKey('${detail.room.id}-$_week'),
                                  days: days,
                                  bookings: bookings.value ?? const [],
                                  hours: detail.hours,
                                  closures: detail.closures,
                                  slotMinutes: detail.room.slotMinutes,
                                  time: time,
                                  onTapBooking: (v) =>
                                      BookingActions.showDetails(
                                        context,
                                        ref,
                                        v,
                                      ),
                                  onTapSlot: (start) {
                                    if (!ensureOnline(context, ref)) return;
                                    context.push(
                                      '/book',
                                      extra: BookingFormArgs(
                                        roomId: detail.room.id,
                                        start: start,
                                      ),
                                    );
                                  },
                                ),
                                if (!bookings.hasValue)
                                  const Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: LinearProgressIndicator(
                                      minHeight: 2,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
