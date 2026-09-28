import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:intl/intl.dart';

import '../core/client.dart';
import '../core/errors.dart';
import '../core/l10n.dart';
import '../core/time.dart';
import '../core/upload.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Screen 8 (owners): room details, opening hours per weekday, booking
/// rules and temporary closures (SRS 2.2.1 - 2.2.5, rule table in 2.3).
class RoomEditScreen extends ConsumerStatefulWidget {
  const RoomEditScreen({super.key, this.detail});

  final RoomDetail? detail;

  @override
  ConsumerState<RoomEditScreen> createState() => _RoomEditScreenState();
}

class _RoomEditScreenState extends ConsumerState<RoomEditScreen> {
  static const _slotOptions = [5, 10, 15, 20, 30, 60];
  static const _durationOptions = [
    5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720, 1440, //
    2880, 4320, 7200, 10080, 20160,
  ];
  static const _advanceOptions = [1, 3, 7, 14, 30, 60, 90, 180, 365];
  static const _quotaHourOptions = [
    1,
    2,
    3,
    4,
    5,
    6,
    8,
    10,
    12,
    15,
    20,
    30,
    40,
  ];

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _capacity = TextEditingController(text: '1');

  RoomType _type = RoomType.office;
  String? _imageUrl;
  bool _uploading = false;
  bool _saving = false;

  /// weekday (1-7) -> (open, close) minutes; missing = closed that day.
  final Map<int, (int, int)> _hours = {
    for (var d = 1; d <= 7; d++) d: (0, 1440),
  };

  int _slot = 15;
  int _min = 30;
  int _max = 240;
  int _advance = 30;
  int? _quota;
  bool _approval = false;
  List<RoomClosure> _closures = [];

  bool get _isNew => widget.detail == null;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    if (d == null) return;
    final r = d.room;
    _name.text = r.name;
    _description.text = r.description ?? '';
    _capacity.text = '${r.capacity}';
    _type = r.type;
    _imageUrl = r.imageUrl;
    _hours
      ..clear()
      ..addAll({
        for (final h in d.hours) h.weekday: (h.openMinute, h.closeMinute),
      });
    _slot = r.slotMinutes;
    _min = r.minMinutes;
    _max = r.maxMinutes;
    _advance = r.advanceDays;
    _quota = r.weeklyQuotaMinutes;
    _approval = r.requiresApproval;
    _closures = [...d.closures];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _capacity.dispose();
    super.dispose();
  }

  List<int> _withValue(List<int> options, int value) =>
      ({...options, value}.toList()..sort());

  Future<void> _pickPhoto() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadImage(kind: 'room');
      if (url != null) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final s = context.s;
    setState(() => _saving = true);
    try {
      final base =
          widget.detail?.room ??
          Room(householdId: 0, name: '', type: RoomType.office);
      final room = base.copyWith(
        name: _name.text,
        type: _type,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text,
        capacity: int.tryParse(_capacity.text) ?? 1,
        imageUrl: _imageUrl,
        slotMinutes: _slot,
        minMinutes: _min,
        maxMinutes: _max,
        advanceDays: _advance,
        weeklyQuotaMinutes: _quota,
        requiresApproval: _approval,
      );
      final hours = [
        for (final e in _hours.entries)
          RoomHours(
            weekday: e.key,
            openMinute: e.value.$1,
            closeMinute: e.value.$2,
          ),
      ];
      if (_isNew) {
        await client.room.create(room, hours);
      } else {
        await client.room.update(room, hours);
      }
      ref.invalidate(roomsProvider);
      ref.invalidate(roomStatusProvider);
      if (!mounted) return;
      showMessage(context, s.roomSaved);
      context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = context.s;
    if (!await confirmDialog(
      context,
      message: s.deleteRoomConfirm,
      confirmLabel: s.deleteRoom,
      destructive: true,
    )) {
      return;
    }
    try {
      await client.room.delete(widget.detail!.room.id!);
      ref.invalidate(roomsProvider);
      ref.invalidate(roomStatusProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final time = ref.read(houseTimeProvider);
    final local = time.local(initial);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(local.year, local.month, local.day),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final clock = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (clock == null) return null;
    return HouseTime.utc(
      time.at(
        time.day(date.year, date.month, date.day),
        clock.hour * 60 + clock.minute,
      ),
    );
  }

  Future<void> _addClosure() async {
    final s = context.s;
    final time = ref.read(houseTimeProvider);
    final now = time.now();
    final start = await _pickDateTime(now);
    if (start == null || !mounted) return;
    final end = await _pickDateTime(start.add(const Duration(hours: 4)));
    if (end == null || !mounted) return;
    final reason = await textDialog(
      context,
      title: s.addClosure,
      label: s.closureReason,
      required: true,
    );
    if (reason == null) return;
    try {
      final closure = await client.room.close(
        widget.detail!.room.id!,
        start,
        end,
        reason,
      );
      setState(() => _closures = [..._closures, closure]);
      ref.invalidate(roomsProvider);
      ref.invalidate(calendarProvider);
      if (mounted) showMessage(context, s.closureAdded);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _removeClosure(RoomClosure closure) async {
    try {
      await client.room.removeClosure(closure.id!);
      setState(
        () => _closures = _closures.where((c) => c.id != closure.id).toList(),
      );
      ref.invalidate(roomsProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final time = ref.watch(houseTimeProvider);
    final weekdayFormat = DateFormat.EEEE(s.localeCode);
    // 1 Jan 2024 was a Monday.
    String weekdayName(int d) => weekdayFormat.format(DateTime(2024, 1, d));

    final minOptions = _withValue(
      _durationOptions.where((m) => m >= _slot && m % _slot == 0).toList(),
      _min,
    );
    final maxOptions = _withValue(
      _durationOptions.where((m) => m >= _min && m % _slot == 0).toList(),
      _max,
    );
    final dayMinutes = [for (var m = 0; m <= 1440; m += _slot) m];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? s.newRoom : s.editRoom),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: s.deleteRoom,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 160,
                      height: 110,
                      color: theme.colorScheme.secondaryContainer,
                      child: _imageUrl == null
                          ? Icon(roomIcon(_type), size: 48)
                          : Image.network(_imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: s.changePhoto,
                    onPressed: _uploading ? null : _pickPhoto,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(labelText: s.roomName),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RoomType>(
                    isExpanded: true,
                    initialValue: _type,
                    decoration: InputDecoration(labelText: s.roomType),
                    items: [
                      for (final t in RoomType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(s.roomTypeName(t)),
                        ),
                    ],
                    onChanged: (t) => setState(() => _type = t ?? _type),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _capacity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: s.capacity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(labelText: s.description),
            ),
            SectionHeader(s.bookingRules),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _slot,
              decoration: InputDecoration(labelText: s.slotSize),
              items: [
                for (final m in _slotOptions)
                  DropdownMenuItem(value: m, child: Text(s.minutes(m))),
              ],
              onChanged: (m) => setState(() {
                _slot = m ?? _slot;
                _min = ((_min / _slot).ceil() * _slot).clamp(_slot, 20160);
                _max = ((_max / _slot).ceil() * _slot).clamp(_min, 20160);
                _hours.updateAll(
                  (_, v) => (v.$1 - v.$1 % _slot, v.$2 - v.$2 % _slot),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: ValueKey('min-$_slot-$_min'),
                    initialValue: _min,
                    decoration: InputDecoration(labelText: s.minDuration),
                    items: [
                      for (final m in minOptions)
                        DropdownMenuItem(value: m, child: Text(s.duration(m))),
                    ],
                    onChanged: (m) => setState(() {
                      _min = m ?? _min;
                      if (_max < _min) _max = _min;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: ValueKey('max-$_slot-$_min-$_max'),
                    initialValue: _max,
                    decoration: InputDecoration(labelText: s.maxDuration),
                    items: [
                      for (final m in maxOptions)
                        DropdownMenuItem(value: m, child: Text(s.duration(m))),
                    ],
                    onChanged: (m) => setState(() => _max = m ?? _max),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _advance,
              decoration: InputDecoration(labelText: s.advanceDays),
              items: [
                for (final d in _withValue(_advanceOptions, _advance))
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (d) => setState(() => _advance = d ?? _advance),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _quota == null ? 0 : _quota! ~/ 60,
              decoration: InputDecoration(labelText: s.weeklyQuota),
              items: [
                DropdownMenuItem(value: 0, child: Text(s.unlimited)),
                for (final h in _withValue(
                  _quotaHourOptions,
                  _quota == null ? 1 : _quota! ~/ 60,
                ))
                  DropdownMenuItem(
                    value: h,
                    child: Text(s.hours(h.toDouble())),
                  ),
              ],
              onChanged: (h) =>
                  setState(() => _quota = h == null || h == 0 ? null : h * 60),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.requiresApproval),
              subtitle: Text(s.requiresApprovalHint),
              value: _approval,
              onChanged: (v) => setState(() => _approval = v),
            ),
            SectionHeader(s.openingHours),
            for (var d = 1; d <= 7; d++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: Text(weekdayName(d))),
                    Switch(
                      value: _hours.containsKey(d),
                      onChanged: (open) => setState(() {
                        if (open) {
                          _hours[d] = (0, 1440);
                        } else {
                          _hours.remove(d);
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                    if (_hours[d] case (final open, final close)) ...[
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: open,
                          menuMaxHeight: 300,
                          items: [
                            for (final m in dayMinutes.where((m) => m < close))
                              DropdownMenuItem(
                                value: m,
                                child: Text(HouseTime.minuteLabel(m)),
                              ),
                          ],
                          onChanged: (m) =>
                              setState(() => _hours[d] = (m ?? open, close)),
                        ),
                      ),
                      const Text('  –  '),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: close,
                          menuMaxHeight: 300,
                          items: [
                            for (final m in dayMinutes.where((m) => m > open))
                              DropdownMenuItem(
                                value: m,
                                child: Text(HouseTime.minuteLabel(m)),
                              ),
                          ],
                          onChanged: (m) =>
                              setState(() => _hours[d] = (open, m ?? close)),
                        ),
                      ),
                    ] else
                      Text(
                        s.closedDay,
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
            if (!_isNew) ...[
              SectionHeader(
                s.closures,
                trailing: TextButton.icon(
                  onPressed: _addClosure,
                  icon: const Icon(Icons.add),
                  label: Text(s.addClosure),
                ),
              ),
              for (final c in _closures)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.construction),
                  title: Text(c.reason),
                  subtitle: Text(time.range(c.startAt, c.endAt)),
                  trailing: IconButton(
                    tooltip: s.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeClosure(c),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}
