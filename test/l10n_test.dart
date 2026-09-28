import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/core/l10n.dart';
import 'package:homeslot/screens/scan_screen.dart';
import 'package:homeslot_client/homeslot_client.dart';

void main() {
  group('Thai and English strings (SRS 4.7)', () {
    final th = S.forLocale('th');
    final en = S.forLocale('en');

    test('durations are readable', () {
      expect(th.duration(30), '30 นาที');
      expect(th.duration(90), '1 ชม. 30 นาที');
      expect(th.duration(2880), '2 วัน');
      expect(en.duration(240), '4 h');
      expect(en.duration(1440 + 60), '1 day 1 h');
    });

    test('every booking status has a label in both languages', () {
      for (final status in BookingStatus.values) {
        expect(th.status(status), isNotEmpty);
        expect(en.status(status), isNotEmpty);
      }
      expect(th.status(BookingStatus.pending), 'รออนุมัติ');
      expect(en.status(BookingStatus.completed), 'Completed');
    });

    test('every room type has a name in both languages', () {
      for (final type in RoomType.values) {
        expect(th.roomTypeName(type), isNotEmpty);
        expect(en.roomTypeName(type), isNotEmpty);
      }
    });
  });

  group('Invite QR codes (SRS 2.1.5)', () {
    test('accept 6 digits or an invite link', () {
      expect(inviteCodeFrom('123456'), '123456');
      expect(inviteCodeFrom(' 654321 '), '654321');
      expect(inviteCodeFrom('homeslot://app/join?code=042042'), '042042');
    });

    test('reject anything else', () {
      expect(inviteCodeFrom('12345'), isNull);
      expect(inviteCodeFrom('https://example.com'), isNull);
      expect(inviteCodeFrom('homeslot://app/join?code=abc123'), isNull);
    });
  });
}
