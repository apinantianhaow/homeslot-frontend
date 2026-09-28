import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/core/time.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    HouseTime.init();
    await initializeDateFormatting();
  });

  group('HouseTime (SRS 4.3: always the household time zone)', () {
    test('converts UTC instants to household wall-clock time', () {
      final time = HouseTime('Asia/Bangkok', 'en');
      final utc = DateTime.utc(2030, 1, 7, 3, 30);
      expect(time.hm(utc), '10:30');
      expect(time.minuteOfDay(utc), 630);
    });

    test('builds UTC instants from a household day and minute', () {
      final time = HouseTime('Asia/Bangkok', 'en');
      final start = HouseTime.utc(time.at(time.day(2030, 1, 7), 19 * 60));
      expect(start, DateTime.utc(2030, 1, 7, 12));
      expect(start.isUtc, isTrue);
    });

    test('weeks start on Monday', () {
      final time = HouseTime('Asia/Bangkok', 'en');
      final sunday = HouseTime.utc(time.at(time.day(2030, 1, 13), 600));
      final monday = time.startOfWeek(sunday);
      expect(monday.weekday, DateTime.monday);
      expect(monday.day, 7);
    });

    test('a booking ending at midnight shows 24:00', () {
      final time = HouseTime('Asia/Bangkok', 'en');
      final start = HouseTime.utc(time.at(time.day(2030, 1, 7), 22 * 60));
      final end = HouseTime.utc(time.at(time.day(2030, 1, 8), 0));
      expect(time.range(start, end), endsWith('22:00–24:00'));
    });

    test('multi-day stays show both days', () {
      final time = HouseTime('Asia/Bangkok', 'en');
      final start = HouseTime.utc(time.at(time.day(2030, 1, 11), 14 * 60));
      final end = HouseTime.utc(time.at(time.day(2030, 1, 13), 12 * 60));
      expect(time.range(start, end), 'Fri 11 Jan 14:00 – Sun 13 Jan 12:00');
    });

    test('unknown zones fall back to Asia/Bangkok', () {
      expect(HouseTime('Not/AZone', 'th').location.name, 'Asia/Bangkok');
    });

    test('minute labels', () {
      expect(HouseTime.minuteLabel(0), '00:00');
      expect(HouseTime.minuteLabel(615), '10:15');
      expect(HouseTime.minuteLabel(1440), '24:00');
    });
  });
}
