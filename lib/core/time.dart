import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Time helpers in the household time zone (SRS 4.3): times are always shown
/// in the household's zone, even when a member is abroad.
class HouseTime {
  HouseTime(String zone, this.locale) : location = _location(zone);

  static tz.Location _location(String zone) {
    init();
    return tz.timeZoneDatabase.locations[zone] ??
        tz.getLocation('Asia/Bangkok');
  }

  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  final tz.Location location;
  final String locale;

  // Building a DateFormat parses its pattern and looks up the locale, so
  // each one is created once per HouseTime instead of on every call.
  late final _hm = DateFormat.Hm(locale);
  late final _day = DateFormat('EEE d MMM', locale);
  late final _fullDay = DateFormat('EEEE d MMMM y', locale);
  late final _month = DateFormat('MMMM y', locale);

  tz.TZDateTime now() => tz.TZDateTime.now(location);

  tz.TZDateTime local(DateTime instant) =>
      tz.TZDateTime.from(instant, location);

  tz.TZDateTime startOfDay(DateTime instant) {
    final t = local(instant);
    return tz.TZDateTime(location, t.year, t.month, t.day);
  }

  tz.TZDateTime day(int year, int month, int day) =>
      tz.TZDateTime(location, year, month, day);

  /// [minute] minutes after local midnight of [day] (may exceed 1440).
  tz.TZDateTime at(DateTime day, int minute) {
    final d = local(day);
    return tz.TZDateTime(location, d.year, d.month, d.day, 0, minute);
  }

  tz.TZDateTime addDays(DateTime day, int days) {
    final d = local(day);
    return tz.TZDateTime(location, d.year, d.month, d.day + days);
  }

  tz.TZDateTime startOfWeek(DateTime instant) {
    final d = startOfDay(instant);
    return addDays(d, -(d.weekday - 1));
  }

  int minuteOfDay(DateTime instant) {
    final t = local(instant);
    return t.hour * 60 + t.minute;
  }

  bool sameDay(DateTime a, DateTime b) {
    final x = local(a);
    final y = local(b);
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  /// Converts to a plain UTC [DateTime] for the API.
  static DateTime utc(DateTime t) => DateTime.fromMicrosecondsSinceEpoch(
    t.microsecondsSinceEpoch,
    isUtc: true,
  );

  String hm(DateTime instant) => _hm.format(local(instant));

  String endHm(DateTime end, DateTime start) {
    final e = local(end);
    if (e.hour == 0 && e.minute == 0 && !sameDay(start, end)) return '24:00';
    return hm(end);
  }

  String dayLabel(DateTime instant) => _day.format(local(instant));

  String fullDay(DateTime instant) => _fullDay.format(local(instant));

  String monthLabel(DateTime instant) => _month.format(local(instant));

  String range(DateTime start, DateTime end) {
    final sameDayOrMidnight =
        sameDay(start, end) ||
        (minuteOfDay(end) == 0 &&
            end.difference(start) <= const Duration(days: 1));
    if (sameDayOrMidnight) {
      return '${dayLabel(start)} ${hm(start)}–${endHm(end, start)}';
    }
    return '${dayLabel(start)} ${hm(start)} – ${dayLabel(end)} ${hm(end)}';
  }

  static String minuteLabel(int minute) {
    final h = minute ~/ 60;
    final m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// Common IANA zones offered when creating a household.
const commonTimeZones = [
  'Asia/Bangkok',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Asia/Seoul',
  'Asia/Kolkata',
  'Asia/Dubai',
  'Australia/Sydney',
  'Europe/London',
  'Europe/Berlin',
  'America/New_York',
  'America/Los_Angeles',
];
