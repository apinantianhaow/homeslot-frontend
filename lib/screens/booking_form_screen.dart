import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/client.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../core/time.dart';
import '../data/cached.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'booking_actions.dart';

/// What the booking form starts with.
class BookingFormArgs {
  const BookingFormArgs({this.roomId, this.start, this.edit});

  final int? roomId;
  final DateTime? start;

  /// When set, the form edits this booking.
  final BookingView? edit;
}

/// Screen 5: book a room for a time range, optionally every week for up to
/// 12 weeks (SRS 2.3.2 - 2.3.6). Three taps from the home screen: room,
/// time, confirm (SRS 4.7).
class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, this.args});

  final BookingFormArgs? args;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _purpose = TextEditingController();
  final _note = TextEditingController();

  int? _roomId;
  tz.TZDateTime? _startDay;
  int _startMinute = 0;
  tz.TZDateTime? _endDay;
  int _endMinute = 60;
  bool _repeat = false;
  int _weeks = 4;
  bool _busy = false;
  BookingException? _error;

  BookingView? get _editing => widget.args?.edit;
  HouseTime get _time => ref.read(houseTimeProvider);

  @override
  void initState() {
    super.initState();
    final edit = _editing;
    if (edit != null) {
      final b = edit.booking;
      _roomId = b.roomId;
      _setRange(b.startAt, b.endAt);
      _purpose.text = b.purpose ?? '';
      _note.text = b.note ?? '';
    } else {
      _roomId = widget.args?.roomId;
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setRange(DateTime start, DateTime end) {
    final time = _time;
    _startDay = time.startOfDay(start);
    _startMinute = start.difference(_startDay!).inMinutes;
    var endDay = time.startOfDay(end);
    var endMinute = end.difference(endDay).inMinutes;
    if (endMinute == 0 && endDay.isAfter(_startDay!)) {
      endDay = time.addDays(endDay, -1);
      endMinute = 1440;
    }
    _endDay = endDay;
    _endMinute = endMinute;
  }

  /// Sets a sensible default range for [room]: the requested start or the
  /// next free slot from now, for one hour (within the room's limits).
  void _initFor(Room room) {
    final time = _time;
    final slot = room.slotMinutes;
    DateTime start;
    if (widget.args?.start != null) {
      start = widget.args!.start!;
    } else {
      final now = time.now();
      final minute = time.minuteOfDay(now);
      start = time.at(now, (minute ~/ slot + 1) * slot);
    }
    final length = min(max(60, room.minMinutes), room.maxMinutes);
    _setRange(start, start.add(Duration(minutes: length)));
  }

  DateTime get _startAt => HouseTime.utc(_time.at(_startDay!, _startMinute));
  DateTime get _endAt => HouseTime.utc(_time.at(_endDay!, _endMinute));

  Future<void> _pickDate(Room room, {required bool end}) async {
    final time = _time;
    final today = time.startOfDay(DateTime.now());
    final current = end ? _endDay! : _startDay!;
    final first = end ? _startDay! : today;
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOnly(current.isBefore(first) ? first : current),
      firstDate: dateOnly(first),
      lastDate: DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: room.advanceDays + (end ? 14 : 0))),
    );
    if (picked == null) return;
    setState(() {
      final day = time.day(picked.year, picked.month, picked.day);
      if (end) {
        _endDay = day;
      } else {
        // Move the end by the same number of calendar days (not hours, which
        // would be off by one around daylight saving changes).
        final days = DateTime.utc(day.year, day.month, day.day)
            .difference(
              DateTime.utc(_startDay!.year, _startDay!.month, _startDay!.day),
            )
            .inDays;
        _startDay = day;
        _endDay = time.addDays(_endDay!, days);
      }
      _error = null;
    });
  }

  List<int> _minutes(int slot, {required int from, required int to}) => [
    for (var m = from; m <= to; m += slot) m,
  ];

  Future<void> _submit(Room room) async {
    if (!ensureOnline(context, ref)) return;
    final s = context.s;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final purpose = _purpose.text.trim().isEmpty ? null : _purpose.text;
      final note = _note.text.trim().isEmpty ? null : _note.text;
      String message;
      final edit = _editing;
      if (edit != null) {
        var scope = EditScope.single;
        if (edit.booking.seriesId != null) {
          final picked = await BookingActions.askScope(context);
          if (picked == null) return;
          scope = picked;
        }
        final saved = await client.booking.update(
          edit.booking.id!,
          _startAt,
          _endAt,
          purpose,
          note,
          scope,
        );
        message = saved.first.booking.status == BookingStatus.pending
            ? s.bookingPendingCreated
            : s.bookingUpdated;
      } else if (_repeat) {
        final created = await _createSeries(room, purpose, note);
        if (created == null) return;
        message = s.seriesCreated(created.length);
      } else {
        final view = await client.booking.create(
          BookingRequest(
            roomId: room.id!,
            startAt: _startAt,
            endAt: _endAt,
            purpose: purpose,
            note: note,
          ),
        );
        message = view.booking.status == BookingStatus.pending
            ? s.bookingPendingCreated
            : s.bookingCreated;
      }
      ref.invalidate(calendarProvider);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(roomStatusProvider);
      if (!mounted) return;
      showMessage(context, message);
      context.pop();
    } on BookingException catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Books every week; if some weeks clash, lets the user skip those dates
  /// or cancel the whole series (SRS 2.3.5).
  Future<List<BookingView>?> _createSeries(
    Room room,
    String? purpose,
    String? note,
  ) async {
    final request = SeriesRequest(
      roomId: room.id!,
      startAt: _startAt,
      endAt: _endAt,
      weeks: _weeks,
      purpose: purpose,
      note: note,
      skipStarts: [],
    );
    final preview = await client.booking.previewSeries(request);
    final conflicts = preview.where((o) => !o.ok).toList();
    if (conflicts.isEmpty) return client.booking.createSeries(request);
    if (!mounted) return null;
    final skip = await _askSkip(conflicts);
    if (skip != true) return null;
    return client.booking.createSeries(
      request.copyWith(skipStarts: [for (final c in conflicts) c.startAt]),
    );
  }

  Future<bool?> _askSkip(List<SeriesOccurrence> conflicts) {
    final s = context.s;
    final time = _time;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.conflictsTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.conflictsBody),
              const SizedBox(height: 12),
              for (final c in conflicts)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy),
                  title: Text(time.range(c.startAt, c.endAt)),
                  subtitle: c.message == null ? null : Text(c.message!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancelSeries),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.skipAndBook(conflicts.length)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final rooms = ref.watch(roomsProvider);
    final offline = ref.watch(offlineProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? s.newBooking : s.editBooking),
      ),
      body: AsyncView(
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
          final room = detail.room;
          if (_roomId != room.id || _startDay == null) {
            _roomId = room.id;
            _initFor(room);
          }
          return _form(context, rooms, room, offline);
        },
      ),
    );
  }

  Widget _form(
    BuildContext context,
    List<RoomDetail> rooms,
    Room room,
    bool offline,
  ) {
    final s = context.s;
    final time = _time;
    final theme = Theme.of(context);
    final slot = room.slotMinutes;
    final multiDay = room.maxMinutes > 1440;
    final sameDay = !_endDay!.isAfter(_startDay!);
    final startOptions = _minutes(slot, from: 0, to: 1440 - slot);
    final endOptions = _minutes(
      slot,
      from: sameDay ? _startMinute + slot : 0,
      to: 1440,
    );
    if (!startOptions.contains(_startMinute)) {
      _startMinute = _startMinute - _startMinute % slot;
    }
    if (!endOptions.contains(_endMinute)) {
      _endMinute = endOptions.firstWhere(
        (m) => m >= _endMinute,
        orElse: () => endOptions.last,
      );
    }
    final length = _endAt.difference(_startAt).inMinutes;

    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            key: ValueKey('room-${room.id}'),
            initialValue: room.id,
            decoration: InputDecoration(labelText: s.room),
            items: [
              for (final r in rooms)
                DropdownMenuItem(value: r.room.id, child: Text(r.room.name)),
            ],
            onChanged: _editing != null
                ? null
                : (id) => setState(() {
                    _roomId = id;
                    _startDay = null;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 8),
          Text(
            [
              s.roomRules(
                slot,
                s.duration(room.minMinutes),
                s.duration(room.maxMinutes),
                room.advanceDays,
              ),
              if (room.weeklyQuotaMinutes != null)
                s.quotaRule(s.duration(room.weeklyQuotaMinutes!)),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          if (room.requiresApproval)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.requiresApprovalNote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(s.date),
            subtitle: Text(time.fullDay(_startDay!)),
            onTap: () => _pickDate(room, end: false),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: ValueKey('start-$_startDay-$_startMinute'),
                  initialValue: _startMinute,
                  decoration: InputDecoration(labelText: s.startTime),
                  menuMaxHeight: 320,
                  items: [
                    for (final m in startOptions)
                      DropdownMenuItem(
                        value: m,
                        child: Text(HouseTime.minuteLabel(m)),
                      ),
                  ],
                  onChanged: (m) => setState(() {
                    final previous = _endAt.difference(_startAt);
                    _startMinute = m ?? _startMinute;
                    final end = _time
                        .at(_startDay!, _startMinute)
                        .add(previous);
                    _setRange(_time.at(_startDay!, _startMinute), end);
                    _error = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: ValueKey(
                    'end-$_startDay-$_startMinute-$_endDay-$_endMinute',
                  ),
                  initialValue: _endMinute,
                  decoration: InputDecoration(labelText: s.endTime),
                  menuMaxHeight: 320,
                  items: [
                    for (final m in endOptions)
                      DropdownMenuItem(
                        value: m,
                        child: Text(HouseTime.minuteLabel(m)),
                      ),
                  ],
                  onChanged: (m) => setState(() {
                    _endMinute = m ?? _endMinute;
                    _error = null;
                  }),
                ),
              ),
            ],
          ),
          if (multiDay)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available),
              title: Text(s.endDate),
              subtitle: Text(time.fullDay(_endDay!)),
              onTap: () => _pickDate(room, end: true),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              length > 0 ? s.duration(length) : '',
              style: theme.textTheme.labelLarge,
            ),
          ),
          TextField(
            controller: _purpose,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: s.purpose,
              hintText: s.purposeHint,
            ),
          ),
          TextField(
            controller: _note,
            maxLength: 500,
            maxLines: 2,
            decoration: InputDecoration(labelText: s.note),
          ),
          if (_editing == null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.repeatWeekly),
              subtitle: _repeat ? Text(s.repeatWeeks(_weeks)) : null,
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            if (_repeat)
              Slider(
                value: _weeks.toDouble(),
                min: 2,
                max: 12,
                divisions: 10,
                label: s.repeatWeeks(_weeks),
                onChanged: (v) => setState(() => _weeks = v.round()),
              ),
          ],
          if (_error != null) _errorCard(context, _error!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: offline || _busy ? null : () => _submit(room),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_editing == null ? s.confirmBooking : s.saveChanges),
          ),
        ],
      ),
    );
  }

  /// Why the booking failed, with the nearest free slots (SRS 2.3.3, 4.7).
  Widget _errorCard(BuildContext context, BookingException error) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final suggestions = error.suggestions ?? const <TimeSlot>[];
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error.message,
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.suggestionsTitle,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final slot in suggestions)
                    ActionChip(
                      avatar: const Icon(Icons.schedule, size: 18),
                      label: Text(_time.range(slot.startAt, slot.endAt)),
                      onPressed: () => setState(() {
                        _setRange(slot.startAt, slot.endAt);
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
