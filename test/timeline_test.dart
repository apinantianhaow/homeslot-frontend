import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/core/l10n.dart';
import 'package:homeslot/core/time.dart';
import 'package:homeslot/widgets/timeline.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    HouseTime.init();
    await initializeDateFormatting();
  });

  testWidgets('shows bookings with the booker name and books a tapped slot', (
    tester,
  ) async {
    final time = HouseTime('Asia/Bangkok', 'en');
    final day = time.addDays(time.startOfDay(DateTime.now()), 1);
    final booking = BookingView(
      booking: Booking(
        householdId: 1,
        roomId: 1,
        userId: 2,
        startAt: HouseTime.utc(time.at(day, 9 * 60)),
        endAt: HouseTime.utc(time.at(day, 10 * 60)),
        status: BookingStatus.confirmed,
        purpose: 'Standup',
      ),
      roomName: 'Office',
      userName: 'Nok',
      userColor: '#4FC3F7',
    );
    DateTime? tapped;
    BookingView? opened;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Timeline(
            days: [day],
            bookings: [booking],
            hours: [
              for (var d = 1; d <= 7; d++)
                RoomHours(weekday: d, openMinute: 0, closeMinute: 1440),
            ],
            closures: const [],
            slotMinutes: 15,
            time: time,
            onTapSlot: (start) => tapped = start,
            onTapBooking: (v) => opened = v,
          ),
        ),
      ),
    );

    expect(find.textContaining('Nok'), findsOneWidget);
    await tester.tap(find.textContaining('Nok'));
    expect(opened, booking);

    // Tap 11:20 in the day column (60 px per hour from 00:00).
    final dayColumn = find
        .ancestor(
          of: find.textContaining('Nok'),
          matching: find.byType(GestureDetector),
        )
        .last;
    final top = tester.getTopLeft(dayColumn);
    await tester.tapAt(top + const Offset(20, 11 * 60 + 20));
    expect(tapped, isNotNull);
    expect(time.hm(tapped!), '11:15');
  });
}
