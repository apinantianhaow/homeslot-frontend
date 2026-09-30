import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/state/data.dart';
import 'package:homeslot_client/homeslot_client.dart';

/// The home screen's "in use" / "free" status reloads itself when it is due
/// to change, because the server sends no event when a booking starts.
void main() {
  final now = DateTime.utc(2030, 1, 7, 8);
  const hour = Duration(hours: 1);
  final office = Room(
    id: 1,
    householdId: 1,
    name: 'Office',
    type: RoomType.office,
  );

  BookingView view(DateTime start, DateTime end) => BookingView(
    booking: Booking(
      householdId: 1,
      roomId: 1,
      userId: 2,
      startAt: start,
      endAt: end,
      status: BookingStatus.confirmed,
    ),
    roomName: office.name,
    userName: 'Nok',
    userColor: '#4FC3F7',
  );

  RoomStatus status({
    DateTime? currentEnd,
    DateTime? nextStart,
    DateTime? closureEnd,
  }) => RoomStatus(
    room: office,
    current: currentEnd == null ? null : view(now.subtract(hour), currentEnd),
    next: nextStart == null ? null : view(nextStart, nextStart.add(hour)),
    closure: closureEnd == null
        ? null
        : RoomClosure(
            roomId: 1,
            startAt: now.subtract(hour),
            endAt: closureEnd,
            reason: 'Painting',
            createdById: 1,
          ),
    openNow: true,
  );

  test('nothing coming up needs no reload', () {
    expect(nextStatusChange([], now), isNull);
    expect(nextStatusChange([status()], now), isNull);
  });

  test('the earliest start or end of any room comes first', () {
    expect(
      nextStatusChange([
        status(nextStart: now.add(const Duration(minutes: 30))),
        status(currentEnd: now.add(const Duration(minutes: 10))),
      ], now),
      now.add(const Duration(minutes: 10)),
    );
    expect(
      nextStatusChange([
        status(
          closureEnd: now.add(const Duration(minutes: 5)),
          nextStart: now.add(hour),
        ),
      ], now),
      now.add(const Duration(minutes: 5)),
    );
  });

  test('times already passed never schedule a reload', () {
    // E.g. the server's clock is a little behind this device's.
    expect(
      nextStatusChange([
        status(currentEnd: now.subtract(const Duration(seconds: 1))),
      ], now),
      isNull,
    );
  });
}
