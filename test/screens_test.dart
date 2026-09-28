import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeslot/core/l10n.dart';
import 'package:homeslot/core/time.dart';
import 'package:homeslot/screens/booking_form_screen.dart';
import 'package:homeslot/screens/calendar_screen.dart';
import 'package:homeslot/screens/home_screen.dart';
import 'package:homeslot/screens/members_screen.dart';
import 'package:homeslot/screens/my_bookings_screen.dart';
import 'package:homeslot/screens/notifications_screen.dart';
import 'package:homeslot/screens/room_edit_screen.dart';
import 'package:homeslot/screens/settings_screen.dart';
import 'package:homeslot/screens/stats_screen.dart';
import 'package:homeslot/state/data.dart';
import 'package:homeslot/state/session.dart';
import 'package:homeslot/state/settings.dart';
import 'package:homeslot_client/homeslot_client.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every main screen at phone size with realistic data, in Thai and
/// English, so layout errors (overflows, unbounded sizes) fail the build.
void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    HouseTime.init();
    await initializeDateFormatting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final time = HouseTime('Asia/Bangkok', 'th');
  final today = time.startOfDay(DateTime.now());
  DateTime at(int days, int minute) =>
      HouseTime.utc(time.at(time.addDays(today, days), minute));

  final household = Household(
    id: 1,
    name: 'บ้านสุขใจ',
    timezone: 'Asia/Bangkok',
  );
  final me = MeInfo(
    user: AppUser(
      id: 1,
      displayName: 'Aphinan',
      color: '#E57373',
      email: 'aphinan@example.com',
    ),
    household: household,
    role: MemberRole.owner,
  );
  final office = Room(
    id: 1,
    householdId: 1,
    name: 'ห้องทำงาน',
    type: RoomType.office,
    weeklyQuotaMinutes: 600,
  );
  final guest = Room(
    id: 2,
    householdId: 1,
    name: 'ห้องรับแขก',
    type: RoomType.guest,
    requiresApproval: true,
    maxMinutes: 4320,
  );
  final allDay = [
    for (var d = 1; d <= 7; d++)
      RoomHours(roomId: 1, weekday: d, openMinute: 480, closeMinute: 1320),
  ];
  final rooms = [
    RoomDetail(room: office, hours: allDay, closures: []),
    RoomDetail(
      room: guest,
      hours: [],
      closures: [
        RoomClosure(
          id: 1,
          roomId: 2,
          startAt: at(1, 540),
          endAt: at(2, 540),
          reason: 'ซ่อมแอร์',
          createdById: 1,
        ),
      ],
    ),
  ];
  BookingView view(
    int id,
    Room room,
    DateTime start,
    DateTime end, {
    BookingStatus status = BookingStatus.confirmed,
    String user = 'Nok',
    int userId = 2,
    int? seriesId,
  }) => BookingView(
    booking: Booking(
      id: id,
      householdId: 1,
      roomId: room.id!,
      userId: userId,
      seriesId: seriesId,
      startAt: start,
      endAt: end,
      status: status,
      purpose: 'ประชุมออนไลน์กับทีมงานต่างประเทศ',
    ),
    roomName: room.name,
    userName: user,
    userColor: '#4FC3F7',
  );
  final bookings = [
    view(1, office, at(0, 0), at(0, 60)),
    view(2, office, at(1, 600), at(1, 720), status: BookingStatus.pending),
    view(
      3,
      office,
      at(2, 1140),
      at(2, 1260),
      userId: 1,
      user: 'Aphinan',
      seriesId: 1,
    ),
  ];

  List<Override> overrides() => [
    sharedPrefsProvider.overrideWithValue(prefs),
    signedInProvider.overrideWith(_SignedIn.new),
    meProvider.overrideWith(() => _Me(me)),
    roomsProvider.overrideWith((ref) async => rooms),
    roomStatusProvider.overrideWith(
      (ref) async => [
        RoomStatus(
          room: office,
          current: bookings.first,
          next: bookings[1],
          openNow: true,
        ),
        RoomStatus(
          room: guest,
          closure: rooms[1].closures.first,
          openNow: false,
        ),
      ],
    ),
    calendarProvider.overrideWith((ref, q) async => bookings),
    myBookingsProvider.overrideWith(
      (ref, upcoming) async =>
          upcoming ? bookings.sublist(1) : [bookings.first],
    ),
    pendingApprovalsProvider.overrideWith((ref) async => [bookings[1]]),
    membersProvider.overrideWith(
      (ref) async => [
        MemberInfo(
          userId: 1,
          displayName: 'Aphinan',
          color: '#E57373',
          email: 'aphinan@example.com',
          role: MemberRole.owner,
          joinedAt: DateTime.now(),
        ),
        MemberInfo(
          userId: 2,
          displayName: 'Nok',
          color: '#4FC3F7',
          role: MemberRole.member,
          joinedAt: DateTime.now(),
        ),
      ],
    ),
    invitesProvider.overrideWith(
      (ref) async => [
        Invitation(
          id: 1,
          code: '042042',
          householdId: 1,
          createdById: 1,
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
        ),
      ],
    ),
    notificationsProvider.overrideWith(
      (ref) async => [
        AppNotification(
          id: 1,
          userId: 1,
          type: NotificationType.approvalRequested,
          title: 'คำขอจองใหม่: ห้องรับแขก',
          body: 'Nok ขอจอง ศ. 3 ต.ค. 14:00 – อา. 5 ต.ค. 12:00',
        ),
      ],
    ),
    usageProvider.overrideWith(
      (ref, q) async => UsageStats(
        period: q.period,
        from: at(-3, 0),
        to: at(4, 0),
        totalMinutes: 750,
        byRoom: [
          UsageEntry(id: 1, label: 'ห้องทำงาน', minutes: 600, bookings: 5),
          UsageEntry(id: 2, label: 'ห้องรับแขก', minutes: 150, bookings: 1),
        ],
        byMember: [
          UsageEntry(
            id: 1,
            label: 'Aphinan',
            color: '#E57373',
            minutes: 450,
            bookings: 3,
          ),
          UsageEntry(
            id: 2,
            label: 'Nok',
            color: '#4FC3F7',
            minutes: 300,
            bookings: 3,
          ),
        ],
        byDay: [
          for (var i = 0; i < 7; i++)
            DailyUsage(date: at(i - 3, 0), minutes: i * 30),
        ],
      ),
    ),
    peakHoursProvider.overrideWith(
      (ref, roomId) async => PeakHours(
        from: at(-30, 0),
        to: at(1, 0),
        hourly: [for (var h = 0; h < 24; h++) h * 10],
        heatmap: List.filled(168, 5),
      ),
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    String locale = 'th',
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'calendar': () => const CalendarScreen(),
    'booking form': () => const BookingFormScreen(),
    'booking form (edit)': () =>
        BookingFormScreen(args: BookingFormArgs(edit: bookings[2])),
    'my bookings': () => const MyBookingsScreen(),
    'room edit (new)': () => const RoomEditScreen(),
    'room edit (existing)': () => RoomEditScreen(detail: rooms[1]),
    'members': () => const MembersScreen(),
    'stats': () => const StatsScreen(),
    'notifications': () => const NotificationsScreen(),
    'settings': () => const SettingsScreen(),
  };

  // A typical phone (390 x 844) and a small Android phone (360 x 640).
  for (final size in const [Size(390, 844), Size(360, 640)]) {
    for (final locale in ['th', 'en']) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} renders ($locale, ${size.width.toInt()} px)',
          (tester) async {
            await pumpScreen(tester, entry.value(), locale: locale, size: size);
          },
        );
      }
    }
  }

  testWidgets('home shows who uses a room and the pending requests', (
    tester,
  ) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.textContaining('Nok ใช้อยู่ถึง'), findsOneWidget);
    expect(find.text('ปิดชั่วคราว: ซ่อมแอร์'), findsOneWidget);
    expect(find.text('มีคำขอรออนุมัติ 1 รายการ'), findsOneWidget);
  });

  testWidgets('booking form shows room rules and the weekly option', (
    tester,
  ) async {
    await pumpScreen(tester, const BookingFormScreen());
    expect(find.textContaining('โควตา 10 ชม.'), findsOneWidget);
    await tester.tap(find.text('จองประจำทุกสัปดาห์'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('จำนวน 4 สัปดาห์'), findsOneWidget);
  });

  testWidgets('calendar week view shows every booking', (tester) async {
    await pumpScreen(tester, const CalendarScreen());
    await tester.tap(find.text('รายสัปดาห์'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _SignedIn extends SignedInNotifier {
  @override
  bool build() => true;
}

class _Me extends MeNotifier {
  _Me(this.value);

  final MeInfo value;

  @override
  Future<MeInfo?> build() async => value;
}
