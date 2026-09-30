import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/colors.dart';
import '../core/l10n.dart';
import '../core/time.dart';
import '../state/data.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Screen 10 (owners): booked hours per room and member by week or month,
/// and peak hours (SRS 2.6.2, 2.6.3).
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;
  int _offset = 0;
  int? _peakRoom;

  /// The last statistics loaded, shown dimmed while another period loads,
  /// so the page does not collapse to a spinner and jump back.
  UsageStats? _lastUsage;

  tz.TZDateTime _anchor(HouseTime time) {
    final now = time.now();
    if (_period == StatsPeriod.week) {
      return time.addDays(time.startOfWeek(now), 7 * _offset);
    }
    return tz.TZDateTime(time.location, now.year, now.month + _offset);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final time = ref.watch(houseTimeProvider);
    final anchor = _anchor(time);
    final query = (period: _period, anchor: HouseTime.utc(anchor));
    final usage = ref.watch(usageProvider(query));
    if (usage.value case final value?) _lastUsage = value;
    final shown = usage.value ?? _lastUsage;
    final peak = ref.watch(peakHoursProvider(_peakRoom));
    final rooms = ref.watch(roomsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(s.stats)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<StatsPeriod>(
            segments: [
              ButtonSegment(value: StatsPeriod.week, label: Text(s.week)),
              ButtonSegment(value: StatsPeriod.month, label: Text(s.month)),
            ],
            selected: {_period},
            onSelectionChanged: (v) => setState(() {
              _period = v.first;
              _offset = 0;
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _offset--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _period == StatsPeriod.week
                      ? '${time.dayLabel(anchor)} – ${time.dayLabel(time.addDays(anchor, 6))}'
                      : time.monthLabel(anchor),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _offset++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (usage.hasError && !usage.hasValue)
            ErrorView(
              error: usage.error!,
              onRetry: () => ref.invalidate(usageProvider(query)),
            )
          else if (shown == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            AnimatedOpacity(
              opacity: usage.hasValue ? 1 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.totalHours(_hours(shown.totalMinutes)),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SectionHeader(s.byRoom),
                  _Bars(
                    entries: shown.byRoom,
                    colorOf: (_) => Theme.of(context).colorScheme.primary,
                  ),
                  SectionHeader(s.byMember),
                  _Bars(
                    entries: shown.byMember,
                    colorOf: (e) => hexColor(e.color),
                  ),
                  SectionHeader(s.byDay),
                  SizedBox(
                    height: 180,
                    child: _DayChart(
                      days: shown.byDay,
                      time: time,
                      period: shown.period,
                    ),
                  ),
                ],
              ),
            ),
          SectionHeader(
            '${s.peakHours} · ${s.last30Days}',
            trailing: DropdownButton<int?>(
              value: _peakRoom,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: null, child: Text(s.allRooms)),
                for (final r in rooms)
                  DropdownMenuItem(value: r.room.id, child: Text(r.room.name)),
              ],
              onChanged: (id) => setState(() => _peakRoom = id),
            ),
          ),
          SizedBox(
            height: 180,
            child: AsyncView(
              value: peak,
              data: (p) => _PeakChart(peak: p),
            ),
          ),
        ],
      ),
    );
  }
}

String _hours(int minutes) {
  final h = minutes / 60;
  return h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);
}

class _Bars extends StatelessWidget {
  const _Bars({required this.entries, required this.colorOf});

  final List<UsageEntry> entries;
  final Color Function(UsageEntry entry) colorOf;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (entries.isEmpty || entries.every((e) => e.minutes == 0)) {
      return Text(s.noData, textAlign: TextAlign.center);
    }
    final maxMinutes = entries.map((e) => e.minutes).reduce(max);
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(e.label, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxMinutes == 0 ? 0 : e.minutes / maxMinutes,
                      minHeight: 14,
                      color: colorOf(e),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    s.hours(e.minutes / 60),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayChart extends StatelessWidget {
  const _DayChart({
    required this.days,
    required this.time,
    required this.period,
  });

  final List<DailyUsage> days;
  final HouseTime time;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                if (period == StatsPeriod.month && i % 5 != 0) {
                  return const SizedBox.shrink();
                }
                final d = time.local(days[i].date);
                final label = period == StatsPeriod.week
                    ? time.dayLabel(d).split(' ').first
                    : '${d.day}';
                return SideTitleWidget(
                  meta: meta,
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].minutes / 60,
                  color: color,
                  width: period == StatsPeriod.week ? 18 : 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PeakChart extends StatelessWidget {
  const _PeakChart({required this.peak});

  final PeakHours peak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = peak.hourly.reduce(max);
    return BarChart(
      BarChartData(
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                if (h % 3 != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text('$h', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var h = 0; h < 24; h++)
            BarChartGroupData(
              x: h,
              barRods: [
                BarChartRodData(
                  toY: peak.hourly[h] / 60,
                  width: 8,
                  color: top > 0 && peak.hourly[h] == top
                      ? scheme.tertiary
                      : scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
