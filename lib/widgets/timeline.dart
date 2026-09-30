import 'dart:math';

import 'package:flutter/material.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/colors.dart';
import '../core/l10n.dart';
import '../core/time.dart';

/// Day or week timeline of one room (SRS 3.1 screen 4).
///
/// Closed hours and closures are shaded; each booking is drawn in the
/// booker's personal color; tapping a free slot starts a booking.
class Timeline extends StatefulWidget {
  const Timeline({
    super.key,
    required this.days,
    required this.bookings,
    required this.hours,
    required this.closures,
    required this.slotMinutes,
    required this.time,
    required this.onTapSlot,
    required this.onTapBooking,
  });

  /// Local midnights of the days to show (1 for day view, 7 for week view).
  final List<tz.TZDateTime> days;
  final List<BookingView> bookings;
  final List<RoomHours> hours;
  final List<RoomClosure> closures;
  final int slotMinutes;
  final HouseTime time;
  final void Function(DateTime start) onTapSlot;
  final void Function(BookingView view) onTapBooking;

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  late final ScrollController _scroll;

  bool get _isWeek => widget.days.length > 1;
  double get _hourHeight => _isWeek ? 44 : 60;

  @override
  void initState() {
    super.initState();
    final nowHour = widget.time.now().hour;
    final firstHour = max(0, min(nowHour - 1, 16));
    _scroll = ScrollController(
      initialScrollOffset: (firstHour < 7 ? firstHour : 7) * _hourHeight,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (_isWeek) _WeekHeader(days: widget.days, time: widget.time),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            // Scrolling then moves an already painted layer instead of
            // repainting every hour line and booking on each frame.
            child: RepaintBoundary(
              child: SizedBox(
                height: 24 * _hourHeight + 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Stack(
                        children: [
                          for (var h = 1; h < 24; h++)
                            Positioned(
                              top: h * _hourHeight - 7,
                              right: 6,
                              child: Text(
                                HouseTime.minuteLabel(h * 60),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final day in widget.days)
                      Expanded(child: _dayColumn(context, day)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayColumn(BuildContext context, tz.TZDateTime day) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nextDay = widget.time.addDays(day, 1);
    final hours = widget.hours.where((h) => h.weekday == day.weekday);
    final open = hours.isEmpty ? null : hours.first;
    final now = widget.time.now();

    double y(int minute) => minute / 60 * _hourHeight;
    int minuteIn(DateTime t) => t.isBefore(day)
        ? 0
        : t.isAfter(nextDay)
        ? 1440
        : min(1440, t.difference(day).inMinutes);

    final shaded = <(int, int)>[
      if (open == null) (0, 1440),
      if (open != null && open.openMinute > 0) (0, open.openMinute),
      if (open != null && open.closeMinute < 1440) (open.closeMinute, 1440),
      for (final c in widget.closures)
        if (c.startAt.isBefore(nextDay) && c.endAt.isAfter(day))
          (minuteIn(c.startAt), minuteIn(c.endAt)),
    ];

    final dayBookings = widget.bookings.where(
      (v) =>
          v.booking.startAt.isBefore(nextDay) && v.booking.endAt.isAfter(day),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final minute = (details.localPosition.dy / _hourHeight * 60).floor();
        final slot = (minute - minute % widget.slotMinutes).clamp(0, 1439);
        // Closed hours, closures and time that has already passed cannot be
        // booked, so a tap there does nothing.
        if (shaded.any((r) => slot >= r.$1 && slot < r.$2)) return;
        final start = widget.time.at(day, slot);
        final slotEnd = start.add(Duration(minutes: widget.slotMinutes));
        if (!slotEnd.isAfter(now)) return;
        widget.onTapSlot(start);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Stack(
          children: [
            for (final (from, to) in shaded)
              Positioned(
                top: y(from),
                height: y(to) - y(from),
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _HourLines(
                  hourHeight: _hourHeight,
                  color: scheme.outlineVariant,
                ),
              ),
            ),
            if (widget.time.sameDay(now, day))
              Positioned(
                top: y(widget.time.minuteOfDay(now)),
                left: 0,
                right: 0,
                child: Container(height: 2, color: scheme.error),
              ),
            for (final view in dayBookings)
              _bookingBlock(
                context,
                view,
                top: y(minuteIn(view.booking.startAt)),
                bottom: y(minuteIn(view.booking.endAt)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bookingBlock(
    BuildContext context,
    BookingView view, {
    required double top,
    required double bottom,
  }) {
    final color = hexColor(view.userColor);
    final pending = view.booking.status == BookingStatus.pending;
    final textColor = pending
        ? Theme.of(context).colorScheme.onSurface
        : onColor(color);
    final height = max(bottom - top, 18.0);
    final b = view.booking;
    return Positioned(
      top: top + 1,
      height: height - 2,
      left: 2,
      right: 2,
      child: GestureDetector(
        onTap: () => widget.onTapBooking(view),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: pending ? color.withValues(alpha: 0.25) : color,
            borderRadius: BorderRadius.circular(6),
            border: pending ? Border.all(color: color, width: 1.5) : null,
          ),
          child: ClipRect(
            child: Text(
              _isWeek
                  ? view.userName
                  : '${view.userName} · ${widget.time.hm(b.startAt)}–'
                        '${widget.time.endHm(b.endAt, b.startAt)}'
                        '${pending ? ' · ${context.s.status(b.status)}' : ''}'
                        '${b.purpose == null ? '' : '\n${b.purpose}'}',
              style: TextStyle(color: textColor, fontSize: _isWeek ? 10 : 12),
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ),
    );
  }
}

/// The 23 hour lines of one day column, painted in one go.
class _HourLines extends CustomPainter {
  const _HourLines({required this.hourHeight, required this.color});

  final double hourHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var h = 1; h < 24; h++) {
      canvas.drawRect(Rect.fromLTWH(0, h * hourHeight, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_HourLines old) =>
      old.hourHeight != hourHeight || old.color != color;
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.days, required this.time});

  final List<tz.TZDateTime> days;
  final HouseTime time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = time.now();
    return Padding(
      padding: const EdgeInsets.only(left: 44, bottom: 4),
      child: Row(
        children: [
          for (final d in days)
            Expanded(
              child: Text(
                '${time.dayLabel(d).split(' ').first}\n${d.day}',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: time.sameDay(d, today) ? FontWeight.bold : null,
                  color: time.sameDay(d, today)
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
