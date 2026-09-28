import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:homeslot_client/homeslot_client.dart';

/// App strings in Thai and English (SRS 4.7). Every string is a member of
/// [S], so a missing translation is a compile error.
abstract class S {
  const S();

  static const supportedLocales = [Locale('th'), Locale('en')];

  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const _Th();

  static S forLocale(String code) => code == 'en' ? const _En() : const _Th();

  static const delegate = _SDelegate();

  String get localeCode;

  // General
  String get appName => 'HomeSlot';
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get close;
  String get retry;
  String get confirm;
  String get errorGeneric;
  String get errorNetwork;
  String get offlineBanner;
  String get offlineAction;
  String get today;
  String get saved;
  String duration(int minutes);
  String minutes(int n);
  String hours(double h);

  // Navigation
  String get navHome;
  String get navCalendar;
  String get navBookings;
  String get navMore;

  // Sign in and household setup
  String get signInTitle;
  String get signInSubtitle;
  String get welcomeTitle;
  String get welcomeSubtitle;
  String get createHousehold;
  String get householdName;
  String get timeZone;
  String get joinHousehold;
  String get inviteCode;
  String get scanQr;
  String get join;
  String get create;
  String get scanTitle;
  String get scanHint;
  String get invalidQr;

  // Home
  String hello(String name);
  String get roomsNow;
  String get statusFree;
  String statusBusyUntil(String name, String time);
  String statusClosed(String reason);
  String get statusNotOpen;
  String nextBooking(String range, String name);
  String get noNextBooking;
  String get myNextBookings;
  String get noUpcoming;
  String get noRooms;
  String get noRoomsOwnerHint;
  String pendingRequests(int n);
  String get book;

  // Calendar
  String get dayView;
  String get weekView;
  String get tapToBook;
  String get closedHours;
  String bookedBy(String name);
  String get purpose;
  String get note;

  // Booking form
  String get newBooking;
  String get editBooking;
  String get room;
  String get date;
  String get startTime;
  String get endTime;
  String get endDate;
  String get purposeHint;
  String get repeatWeekly;
  String repeatWeeks(int n);
  String get confirmBooking;
  String get saveChanges;
  String get bookingCreated;
  String get bookingPendingCreated;
  String get bookingUpdated;
  String seriesCreated(int n);
  String get suggestionsTitle;
  String get conflictsTitle;
  String get conflictsBody;
  String skipAndBook(int n);
  String get cancelSeries;
  String get requiresApprovalNote;
  String roomRules(int slot, String min, String max, int advance);
  String quotaRule(String quota);
  String get scopeTitle;
  String get scopeSingle;
  String get scopeSeries;
  String get pickRoom;

  // My bookings
  String get upcoming;
  String get past;
  String get cancelBooking;
  String get cancelConfirm;
  String get releaseRoom;
  String get releaseConfirm;
  String get released;
  String cancelled(int n);
  String get noPast;
  String get inUse;
  String get recurring;
  String reasonLabel(String reason);
  String status(BookingStatus status);

  // Approvals
  String get approvals;
  String get noApprovals;
  String get approve;
  String get reject;
  String get rejectReason;
  String get applyToSeries;
  String get approved;
  String get rejected;
  String requestedBy(String name);

  // Rooms
  String get manageRooms;
  String get newRoom;
  String get editRoom;
  String get roomName;
  String get roomType;
  String roomTypeName(RoomType type);
  String get capacity;
  String get description;
  String get photo;
  String get changePhoto;
  String get openingHours;
  String get closedDay;
  String get bookingRules;
  String get slotSize;
  String get minDuration;
  String get maxDuration;
  String get advanceDays;
  String get weeklyQuota;
  String get unlimited;
  String get quotaHours;
  String get requiresApproval;
  String get requiresApprovalHint;
  String get closures;
  String get addClosure;
  String get closureReason;
  String get closureStart;
  String get closureEnd;
  String get closureAdded;
  String get deleteRoom;
  String get deleteRoomConfirm;
  String get roomSaved;

  // Members
  String get members;
  String role(MemberRole role);
  String get makeOwner;
  String get makeMember;
  String get removeMember;
  String removeMemberConfirm(String name);
  String get invite;
  String get createInvite;
  String inviteExpires(String time);
  String get revoke;
  String get share;
  String inviteShareText(String code, String link);
  String get you;
  String get activeInvites;
  String get inviteHint;

  // Statistics
  String get stats;
  String get week;
  String get month;
  String totalHours(String hours);
  String get byRoom;
  String get byMember;
  String get byDay;
  String get peakHours;
  String get allRooms;
  String get last30Days;
  String get noData;

  // Notifications and settings
  String get notifications;
  String get noNotifications;
  String get markAllRead;
  String get settings;
  String get profile;
  String get displayName;
  String get myColor;
  String get language;
  String get theme;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get reminders;
  String reminderMinutes(int n);
  String get household;
  String get editHousehold;
  String get leaveHousehold;
  String get leaveConfirm;
  String get signOut;
  String get deleteAccount;
  String get deleteAccountConfirm;
  String get about;
  String get server;
  String get formerMember;
  String get pushDisabled;
  String get more;
}

class _Th extends S {
  const _Th();

  @override
  String get localeCode => 'th';
  @override
  String get ok => 'ตกลง';
  @override
  String get cancel => 'ยกเลิก';
  @override
  String get save => 'บันทึก';
  @override
  String get delete => 'ลบ';
  @override
  String get edit => 'แก้ไข';
  @override
  String get close => 'ปิด';
  @override
  String get retry => 'ลองใหม่';
  @override
  String get confirm => 'ยืนยัน';
  @override
  String get errorGeneric => 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง';
  @override
  String get errorNetwork =>
      'เชื่อมต่อ server ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';
  @override
  String get offlineBanner => 'กำลังออฟไลน์ · แสดงตารางล่าสุดแบบอ่านอย่างเดียว';
  @override
  String get offlineAction => 'ออฟไลน์อยู่ ทำรายการนี้ไม่ได้';
  @override
  String get today => 'วันนี้';
  @override
  String get saved => 'บันทึกแล้ว';
  @override
  String duration(int minutes) {
    final d = minutes ~/ 1440;
    final h = (minutes % 1440) ~/ 60;
    final m = minutes % 60;
    return [
      if (d > 0) '$d วัน',
      if (h > 0) '$h ชม.',
      if (m > 0 || minutes == 0) '$m นาที',
    ].join(' ');
  }

  @override
  String minutes(int n) => '$n นาที';
  @override
  String hours(double h) => '${_num(h)} ชม.';

  @override
  String get navHome => 'หน้าแรก';
  @override
  String get navCalendar => 'ปฏิทิน';
  @override
  String get navBookings => 'การจองของฉัน';
  @override
  String get navMore => 'เพิ่มเติม';

  @override
  String get signInTitle => 'จองห้องในบ้าน ไม่ชนกันอีกต่อไป';
  @override
  String get signInSubtitle => 'เข้าสู่ระบบหรือสมัครสมาชิกเพื่อเริ่มใช้งาน';
  @override
  String get welcomeTitle => 'ยินดีต้อนรับสู่ HomeSlot';
  @override
  String get welcomeSubtitle =>
      'สร้างบ้านใหม่เพื่อเป็นผู้ดูแลบ้าน หรือเข้าร่วมบ้านด้วยรหัสเชิญ';
  @override
  String get createHousehold => 'สร้างบ้าน';
  @override
  String get householdName => 'ชื่อบ้าน';
  @override
  String get timeZone => 'โซนเวลา';
  @override
  String get joinHousehold => 'เข้าร่วมบ้าน';
  @override
  String get inviteCode => 'รหัสเชิญ 6 หลัก';
  @override
  String get scanQr => 'สแกน QR Code';
  @override
  String get join => 'เข้าร่วม';
  @override
  String get create => 'สร้าง';
  @override
  String get scanTitle => 'สแกน QR รหัสเชิญ';
  @override
  String get scanHint => 'เล็ง QR Code ที่ผู้ดูแลบ้านแสดงให้อยู่ในกรอบ';
  @override
  String get invalidQr => 'QR Code นี้ไม่ใช่รหัสเชิญของ HomeSlot';

  @override
  String hello(String name) => 'สวัสดี $name';
  @override
  String get roomsNow => 'ห้องตอนนี้';
  @override
  String get statusFree => 'ว่าง';
  @override
  String statusBusyUntil(String name, String time) => '$name ใช้อยู่ถึง $time';
  @override
  String statusClosed(String reason) => 'ปิดชั่วคราว: $reason';
  @override
  String get statusNotOpen => 'ไม่เปิดให้จองตอนนี้';
  @override
  String nextBooking(String range, String name) => 'ถัดไป $range · $name';
  @override
  String get noNextBooking => 'ยังไม่มีการจองถัดไป';
  @override
  String get myNextBookings => 'การจองถัดไปของฉัน';
  @override
  String get noUpcoming => 'ยังไม่มีการจอง แตะห้องที่ว่างเพื่อจองได้เลย';
  @override
  String get noRooms => 'ยังไม่มีห้องในบ้านนี้';
  @override
  String get noRoomsOwnerHint => 'เพิ่มห้องแรกได้ที่ เพิ่มเติม › จัดการห้อง';
  @override
  String pendingRequests(int n) => 'มีคำขอรออนุมัติ $n รายการ';
  @override
  String get book => 'จองห้อง';

  @override
  String get dayView => 'รายวัน';
  @override
  String get weekView => 'รายสัปดาห์';
  @override
  String get tapToBook => 'แตะช่องว่างเพื่อจอง';
  @override
  String get closedHours => 'ไม่เปิดให้จอง';
  @override
  String bookedBy(String name) => 'จองโดย $name';
  @override
  String get purpose => 'จุดประสงค์';
  @override
  String get note => 'หมายเหตุ';

  @override
  String get newBooking => 'จองห้อง';
  @override
  String get editBooking => 'แก้ไขการจอง';
  @override
  String get room => 'ห้อง';
  @override
  String get date => 'วันที่';
  @override
  String get startTime => 'เวลาเริ่ม';
  @override
  String get endTime => 'เวลาสิ้นสุด';
  @override
  String get endDate => 'วันที่สิ้นสุด';
  @override
  String get purposeHint => 'เช่น ประชุมงาน เรียนออนไลน์';
  @override
  String get repeatWeekly => 'จองประจำทุกสัปดาห์';
  @override
  String repeatWeeks(int n) => 'จำนวน $n สัปดาห์';
  @override
  String get confirmBooking => 'ยืนยันการจอง';
  @override
  String get saveChanges => 'บันทึกการแก้ไข';
  @override
  String get bookingCreated => 'จองสำเร็จ';
  @override
  String get bookingPendingCreated => 'ส่งคำขอแล้ว รอผู้ดูแลบ้านอนุมัติ';
  @override
  String get bookingUpdated => 'บันทึกการแก้ไขแล้ว';
  @override
  String seriesCreated(int n) => 'จองประจำสำเร็จ $n ครั้ง';
  @override
  String get suggestionsTitle => 'ช่วงว่างที่ใกล้ที่สุด';
  @override
  String get conflictsTitle => 'บางสัปดาห์จองไม่ได้';
  @override
  String get conflictsBody =>
      'ข้ามวันที่ชนแล้วจองวันที่เหลือ หรือยกเลิกทั้งชุด';
  @override
  String skipAndBook(int n) => 'ข้าม $n วันแล้วจอง';
  @override
  String get cancelSeries => 'ยกเลิกทั้งชุด';
  @override
  String get requiresApprovalNote =>
      'ห้องนี้ต้องรอผู้ดูแลบ้านอนุมัติก่อนยืนยัน';
  @override
  String roomRules(int slot, String min, String max, int advance) =>
      'ช่องละ $slot นาที · $min–$max · ล่วงหน้าได้ $advance วัน';
  @override
  String quotaRule(String quota) => 'โควตา $quota ต่อสัปดาห์';
  @override
  String get scopeTitle => 'ใช้กับการจองไหน';
  @override
  String get scopeSingle => 'เฉพาะครั้งนี้';
  @override
  String get scopeSeries => 'ทุกครั้งที่เหลือในชุดนี้';
  @override
  String get pickRoom => 'เลือกห้อง';

  @override
  String get upcoming => 'กำลังจะถึง';
  @override
  String get past => 'ที่ผ่านมา';
  @override
  String get cancelBooking => 'ยกเลิกการจอง';
  @override
  String get cancelConfirm => 'ยกเลิกการจองนี้?';
  @override
  String get releaseRoom => 'คืนห้อง';
  @override
  String get releaseConfirm =>
      'คืนห้องตอนนี้? เวลาที่เหลือจะว่างให้คนอื่นจองได้';
  @override
  String get released => 'คืนห้องแล้ว';
  @override
  String cancelled(int n) => 'ยกเลิกแล้ว $n รายการ';
  @override
  String get noPast => 'ยังไม่มีประวัติการจอง';
  @override
  String get inUse => 'กำลังใช้งาน';
  @override
  String get recurring => 'จองประจำ';
  @override
  String reasonLabel(String reason) => 'เหตุผล: $reason';
  @override
  String status(BookingStatus status) => switch (status) {
    BookingStatus.pending => 'รออนุมัติ',
    BookingStatus.confirmed => 'ยืนยันแล้ว',
    BookingStatus.rejected => 'ถูกปฏิเสธ',
    BookingStatus.expired => 'หมดอายุ',
    BookingStatus.cancelled => 'ยกเลิก',
    BookingStatus.completed => 'เสร็จสิ้น',
  };

  @override
  String get approvals => 'คำขออนุมัติ';
  @override
  String get noApprovals => 'ไม่มีคำขอที่รออนุมัติ';
  @override
  String get approve => 'อนุมัติ';
  @override
  String get reject => 'ปฏิเสธ';
  @override
  String get rejectReason => 'เหตุผลที่ปฏิเสธ';
  @override
  String get applyToSeries => 'ใช้กับทุกครั้งในชุดนี้';
  @override
  String get approved => 'อนุมัติแล้ว';
  @override
  String get rejected => 'ปฏิเสธแล้ว';
  @override
  String requestedBy(String name) => 'ขอโดย $name';

  @override
  String get manageRooms => 'จัดการห้อง';
  @override
  String get newRoom => 'เพิ่มห้อง';
  @override
  String get editRoom => 'แก้ไขห้อง';
  @override
  String get roomName => 'ชื่อห้อง';
  @override
  String get roomType => 'ประเภท';
  @override
  String roomTypeName(RoomType type) => switch (type) {
    RoomType.office => 'ห้องทำงาน',
    RoomType.living => 'ห้องนั่งเล่น',
    RoomType.guest => 'ห้องรับแขก',
    RoomType.meeting => 'ห้องประชุม',
    RoomType.other => 'อื่น ๆ',
  };
  @override
  String get capacity => 'ความจุ (คน)';
  @override
  String get description => 'คำอธิบาย';
  @override
  String get photo => 'รูปภาพ';
  @override
  String get changePhoto => 'เลือกรูป';
  @override
  String get openingHours => 'เวลาเปิดให้จอง';
  @override
  String get closedDay => 'ปิด';
  @override
  String get bookingRules => 'กฎการจอง';
  @override
  String get slotSize => 'ความละเอียดของเวลา';
  @override
  String get minDuration => 'ระยะเวลาขั้นต่ำ';
  @override
  String get maxDuration => 'ระยะเวลาสูงสุด';
  @override
  String get advanceDays => 'จองล่วงหน้าได้สูงสุด (วัน)';
  @override
  String get weeklyQuota => 'โควตาต่อสมาชิกต่อสัปดาห์';
  @override
  String get unlimited => 'ไม่จำกัด';
  @override
  String get quotaHours => 'ชั่วโมงต่อสัปดาห์';
  @override
  String get requiresApproval => 'ต้องขออนุมัติ';
  @override
  String get requiresApprovalHint =>
      'การจองของสมาชิกต้องรอผู้ดูแลบ้านอนุมัติก่อน';
  @override
  String get closures => 'ปิดห้องชั่วคราว';
  @override
  String get addClosure => 'ปิดห้องชั่วคราว';
  @override
  String get closureReason => 'เหตุผล เช่น ซ่อมแอร์';
  @override
  String get closureStart => 'เริ่มปิด';
  @override
  String get closureEnd => 'ปิดถึง';
  @override
  String get closureAdded =>
      'ปิดห้องแล้ว การจองในช่วงนี้ถูกยกเลิกและแจ้งผู้จองแล้ว';
  @override
  String get deleteRoom => 'ลบห้อง';
  @override
  String get deleteRoomConfirm =>
      'ลบห้องนี้? ประวัติการจองของห้องนี้จะถูกลบไปด้วย';
  @override
  String get roomSaved => 'บันทึกห้องแล้ว';

  @override
  String get members => 'สมาชิก';
  @override
  String role(MemberRole role) =>
      role == MemberRole.owner ? 'ผู้ดูแลบ้าน' : 'สมาชิก';
  @override
  String get makeOwner => 'ตั้งเป็นผู้ดูแลบ้าน';
  @override
  String get makeMember => 'เปลี่ยนเป็นสมาชิก';
  @override
  String get removeMember => 'นำออกจากบ้าน';
  @override
  String removeMemberConfirm(String name) =>
      'นำ $name ออกจากบ้าน? การจองในอนาคตของ $name จะถูกยกเลิก';
  @override
  String get invite => 'เชิญสมาชิก';
  @override
  String get createInvite => 'สร้างรหัสเชิญ';
  @override
  String inviteExpires(String time) => 'หมดอายุ $time';
  @override
  String get revoke => 'ยกเลิกรหัส';
  @override
  String get share => 'แชร์';
  @override
  String inviteShareText(String code, String link) =>
      'เข้าร่วมบ้านของเราใน HomeSlot ด้วยรหัส $code หรือเปิดลิงก์ $link';
  @override
  String get you => '(คุณ)';
  @override
  String get activeInvites => 'รหัสเชิญที่ใช้งานได้';
  @override
  String get inviteHint =>
      'รหัสใช้ได้ 48 ชั่วโมง ให้สมาชิกกรอกรหัสหรือสแกน QR ในหน้าเข้าร่วมบ้าน';

  @override
  String get stats => 'สถิติการใช้ห้อง';
  @override
  String get week => 'สัปดาห์';
  @override
  String get month => 'เดือน';
  @override
  String totalHours(String hours) => 'รวม $hours ชั่วโมง';
  @override
  String get byRoom => 'ตามห้อง';
  @override
  String get byMember => 'ตามสมาชิก';
  @override
  String get byDay => 'รายวัน';
  @override
  String get peakHours => 'ช่วงเวลาที่ใช้มากที่สุด';
  @override
  String get allRooms => 'ทุกห้อง';
  @override
  String get last30Days => '30 วันล่าสุด';
  @override
  String get noData => 'ยังไม่มีข้อมูล';

  @override
  String get notifications => 'การแจ้งเตือน';
  @override
  String get noNotifications => 'ยังไม่มีการแจ้งเตือน';
  @override
  String get markAllRead => 'อ่านทั้งหมด';
  @override
  String get settings => 'ตั้งค่า';
  @override
  String get profile => 'โปรไฟล์';
  @override
  String get displayName => 'ชื่อที่แสดง';
  @override
  String get myColor => 'สีประจำตัวบนปฏิทิน';
  @override
  String get language => 'ภาษา';
  @override
  String get theme => 'ธีม';
  @override
  String get themeSystem => 'ตามระบบ';
  @override
  String get themeLight => 'สว่าง';
  @override
  String get themeDark => 'มืด';
  @override
  String get reminders => 'เตือนก่อนถึงเวลาจอง';
  @override
  String reminderMinutes(int n) => 'เตือนก่อน $n นาที';
  @override
  String get household => 'บ้าน';
  @override
  String get editHousehold => 'แก้ไขข้อมูลบ้าน';
  @override
  String get leaveHousehold => 'ออกจากบ้าน';
  @override
  String get leaveConfirm =>
      'ออกจากบ้านนี้? การจองในอนาคตของคุณจะถูกยกเลิกทั้งหมด';
  @override
  String get signOut => 'ออกจากระบบ';
  @override
  String get deleteAccount => 'ลบบัญชี';
  @override
  String get deleteAccountConfirm =>
      'ลบบัญชีและข้อมูลส่วนตัวทั้งหมด? ประวัติการจองจะแสดงเป็น "อดีตสมาชิก" และย้อนกลับไม่ได้';
  @override
  String get about => 'เกี่ยวกับแอป';
  @override
  String get server => 'Server';
  @override
  String get formerMember => 'อดีตสมาชิก';
  @override
  String get pushDisabled =>
      'ยังไม่ได้ตั้งค่า Push Notification ดูการแจ้งเตือนได้ในแอป';
  @override
  String get more => 'เพิ่มเติม';
}

class _En extends S {
  const _En();

  @override
  String get localeCode => 'en';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
  @override
  String get confirm => 'Confirm';
  @override
  String get errorGeneric => 'Something went wrong. Please try again.';
  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your connection and try again.';
  @override
  String get offlineBanner => 'Offline · showing the last schedule, read-only';
  @override
  String get offlineAction => 'You are offline. This is not available.';
  @override
  String get today => 'Today';
  @override
  String get saved => 'Saved';
  @override
  String duration(int minutes) {
    final d = minutes ~/ 1440;
    final h = (minutes % 1440) ~/ 60;
    final m = minutes % 60;
    return [
      if (d > 0) '$d ${d == 1 ? 'day' : 'days'}',
      if (h > 0) '$h h',
      if (m > 0 || minutes == 0) '$m min',
    ].join(' ');
  }

  @override
  String minutes(int n) => '$n min';
  @override
  String hours(double h) => '${_num(h)} h';

  @override
  String get navHome => 'Home';
  @override
  String get navCalendar => 'Calendar';
  @override
  String get navBookings => 'My bookings';
  @override
  String get navMore => 'More';

  @override
  String get signInTitle => 'Share rooms at home without clashes';
  @override
  String get signInSubtitle => 'Sign in or create an account to start';
  @override
  String get welcomeTitle => 'Welcome to HomeSlot';
  @override
  String get welcomeSubtitle =>
      'Create a household and become its owner, or join one with an invite code';
  @override
  String get createHousehold => 'Create a household';
  @override
  String get householdName => 'Household name';
  @override
  String get timeZone => 'Time zone';
  @override
  String get joinHousehold => 'Join a household';
  @override
  String get inviteCode => '6-digit invite code';
  @override
  String get scanQr => 'Scan QR code';
  @override
  String get join => 'Join';
  @override
  String get create => 'Create';
  @override
  String get scanTitle => 'Scan invite QR code';
  @override
  String get scanHint => 'Point the camera at the QR code shown by the owner';
  @override
  String get invalidQr => 'This QR code is not a HomeSlot invite';

  @override
  String hello(String name) => 'Hi $name';
  @override
  String get roomsNow => 'Rooms right now';
  @override
  String get statusFree => 'Free';
  @override
  String statusBusyUntil(String name, String time) => '$name until $time';
  @override
  String statusClosed(String reason) => 'Closed: $reason';
  @override
  String get statusNotOpen => 'Not open now';
  @override
  String nextBooking(String range, String name) => 'Next $range · $name';
  @override
  String get noNextBooking => 'No upcoming booking';
  @override
  String get myNextBookings => 'My next bookings';
  @override
  String get noUpcoming => 'No bookings yet. Tap a free room to book.';
  @override
  String get noRooms => 'This household has no rooms yet';
  @override
  String get noRoomsOwnerHint => 'Add the first room in More › Manage rooms';
  @override
  String pendingRequests(int n) =>
      '$n ${n == 1 ? 'request' : 'requests'} waiting for approval';
  @override
  String get book => 'Book';

  @override
  String get dayView => 'Day';
  @override
  String get weekView => 'Week';
  @override
  String get tapToBook => 'Tap a free slot to book';
  @override
  String get closedHours => 'Closed';
  @override
  String bookedBy(String name) => 'Booked by $name';
  @override
  String get purpose => 'Purpose';
  @override
  String get note => 'Note';

  @override
  String get newBooking => 'New booking';
  @override
  String get editBooking => 'Edit booking';
  @override
  String get room => 'Room';
  @override
  String get date => 'Date';
  @override
  String get startTime => 'Start';
  @override
  String get endTime => 'End';
  @override
  String get endDate => 'End date';
  @override
  String get purposeHint => 'e.g. work call, online class';
  @override
  String get repeatWeekly => 'Repeat every week';
  @override
  String repeatWeeks(int n) => '$n weeks';
  @override
  String get confirmBooking => 'Confirm booking';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get bookingCreated => 'Booked';
  @override
  String get bookingPendingCreated =>
      'Request sent. Waiting for an owner to approve.';
  @override
  String get bookingUpdated => 'Changes saved';
  @override
  String seriesCreated(int n) => 'Booked $n weekly sessions';
  @override
  String get suggestionsTitle => 'Nearest free slots';
  @override
  String get conflictsTitle => 'Some weeks are not available';
  @override
  String get conflictsBody =>
      'Skip the conflicting dates and book the rest, or cancel the series.';
  @override
  String skipAndBook(int n) => 'Skip $n and book';
  @override
  String get cancelSeries => 'Cancel series';
  @override
  String get requiresApprovalNote =>
      'Bookings in this room need an owner\'s approval';
  @override
  String roomRules(int slot, String min, String max, int advance) =>
      '$slot-min steps · $min–$max · up to $advance days ahead';
  @override
  String quotaRule(String quota) => 'Quota $quota per week';
  @override
  String get scopeTitle => 'Apply to';
  @override
  String get scopeSingle => 'This booking only';
  @override
  String get scopeSeries => 'All upcoming in this series';
  @override
  String get pickRoom => 'Choose a room';

  @override
  String get upcoming => 'Upcoming';
  @override
  String get past => 'Past';
  @override
  String get cancelBooking => 'Cancel booking';
  @override
  String get cancelConfirm => 'Cancel this booking?';
  @override
  String get releaseRoom => 'Release room';
  @override
  String get releaseConfirm =>
      'Release the room now? The rest of the time becomes free for others.';
  @override
  String get released => 'Room released';
  @override
  String cancelled(int n) => 'Cancelled $n';
  @override
  String get noPast => 'No booking history yet';
  @override
  String get inUse => 'In use';
  @override
  String get recurring => 'Weekly';
  @override
  String reasonLabel(String reason) => 'Reason: $reason';
  @override
  String status(BookingStatus status) => switch (status) {
    BookingStatus.pending => 'Pending',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.rejected => 'Rejected',
    BookingStatus.expired => 'Expired',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.completed => 'Completed',
  };

  @override
  String get approvals => 'Approval requests';
  @override
  String get noApprovals => 'No pending requests';
  @override
  String get approve => 'Approve';
  @override
  String get reject => 'Reject';
  @override
  String get rejectReason => 'Reason for rejecting';
  @override
  String get applyToSeries => 'Apply to the whole series';
  @override
  String get approved => 'Approved';
  @override
  String get rejected => 'Rejected';
  @override
  String requestedBy(String name) => 'Requested by $name';

  @override
  String get manageRooms => 'Manage rooms';
  @override
  String get newRoom => 'New room';
  @override
  String get editRoom => 'Edit room';
  @override
  String get roomName => 'Room name';
  @override
  String get roomType => 'Type';
  @override
  String roomTypeName(RoomType type) => switch (type) {
    RoomType.office => 'Office',
    RoomType.living => 'Living room',
    RoomType.guest => 'Guest room',
    RoomType.meeting => 'Meeting room',
    RoomType.other => 'Other',
  };
  @override
  String get capacity => 'Capacity (people)';
  @override
  String get description => 'Description';
  @override
  String get photo => 'Photo';
  @override
  String get changePhoto => 'Choose photo';
  @override
  String get openingHours => 'Opening hours';
  @override
  String get closedDay => 'Closed';
  @override
  String get bookingRules => 'Booking rules';
  @override
  String get slotSize => 'Time step';
  @override
  String get minDuration => 'Minimum length';
  @override
  String get maxDuration => 'Maximum length';
  @override
  String get advanceDays => 'Book ahead (days)';
  @override
  String get weeklyQuota => 'Weekly quota per member';
  @override
  String get unlimited => 'Unlimited';
  @override
  String get quotaHours => 'Hours per week';
  @override
  String get requiresApproval => 'Requires approval';
  @override
  String get requiresApprovalHint =>
      'Members\' bookings wait for an owner to approve them';
  @override
  String get closures => 'Temporary closures';
  @override
  String get addClosure => 'Close temporarily';
  @override
  String get closureReason => 'Reason, e.g. air conditioner repair';
  @override
  String get closureStart => 'Closed from';
  @override
  String get closureEnd => 'Closed until';
  @override
  String get closureAdded =>
      'Room closed. Bookings in this period were cancelled and their bookers notified.';
  @override
  String get deleteRoom => 'Delete room';
  @override
  String get deleteRoomConfirm =>
      'Delete this room? Its booking history is deleted too.';
  @override
  String get roomSaved => 'Room saved';

  @override
  String get members => 'Members';
  @override
  String role(MemberRole role) => role == MemberRole.owner ? 'Owner' : 'Member';
  @override
  String get makeOwner => 'Make owner';
  @override
  String get makeMember => 'Make member';
  @override
  String get removeMember => 'Remove from household';
  @override
  String removeMemberConfirm(String name) =>
      'Remove $name from the household? Their upcoming bookings are cancelled.';
  @override
  String get invite => 'Invite members';
  @override
  String get createInvite => 'Create invite code';
  @override
  String inviteExpires(String time) => 'Expires $time';
  @override
  String get revoke => 'Revoke';
  @override
  String get share => 'Share';
  @override
  String inviteShareText(String code, String link) =>
      'Join our household on HomeSlot with code $code or open $link';
  @override
  String get you => '(you)';
  @override
  String get activeInvites => 'Active invite codes';
  @override
  String get inviteHint =>
      'Codes work for 48 hours. New members enter the code or scan the QR code on the join screen.';

  @override
  String get stats => 'Usage statistics';
  @override
  String get week => 'Week';
  @override
  String get month => 'Month';
  @override
  String totalHours(String hours) => '$hours hours in total';
  @override
  String get byRoom => 'By room';
  @override
  String get byMember => 'By member';
  @override
  String get byDay => 'By day';
  @override
  String get peakHours => 'Peak hours';
  @override
  String get allRooms => 'All rooms';
  @override
  String get last30Days => 'Last 30 days';
  @override
  String get noData => 'No data yet';

  @override
  String get notifications => 'Notifications';
  @override
  String get noNotifications => 'No notifications yet';
  @override
  String get markAllRead => 'Mark all read';
  @override
  String get settings => 'Settings';
  @override
  String get profile => 'Profile';
  @override
  String get displayName => 'Display name';
  @override
  String get myColor => 'My calendar color';
  @override
  String get language => 'Language';
  @override
  String get theme => 'Theme';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get reminders => 'Booking reminders';
  @override
  String reminderMinutes(int n) => '$n minutes before';
  @override
  String get household => 'Household';
  @override
  String get editHousehold => 'Edit household';
  @override
  String get leaveHousehold => 'Leave household';
  @override
  String get leaveConfirm =>
      'Leave this household? All your upcoming bookings are cancelled.';
  @override
  String get signOut => 'Sign out';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get deleteAccountConfirm =>
      'Delete your account and personal data? Past bookings will show "Former member". This cannot be undone.';
  @override
  String get about => 'About';
  @override
  String get server => 'Server';
  @override
  String get formerMember => 'Former member';
  @override
  String get pushDisabled =>
      'Push notifications are not set up. You can still see notifications in the app.';
  @override
  String get more => 'More';
}

String _num(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'th' || locale.languageCode == 'en';

  @override
  Future<S> load(Locale locale) =>
      SynchronousFuture<S>(S.forLocale(locale.languageCode));

  @override
  bool shouldReload(_SDelegate old) => false;
}

extension SContext on BuildContext {
  S get s => S.of(this);
}
