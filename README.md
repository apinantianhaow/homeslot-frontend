# HomeSlot Frontend

แอปมือถือ (Android / iOS) ของ **HomeSlot – แอปจองห้องภายในบ้าน** เขียนด้วย Flutter ตามเอกสาร SRS-002 (28 ก.ย. 2569)

Backend อยู่ใน repository แยก: [`homeslot-backend`](../homeslot-backend) แอปคุยกับ server ผ่าน HTTPS และ WebSocket (Serverpod) เท่านั้น ไม่เชื่อมต่อฐานข้อมูลโดยตรง

## เริ่มพัฒนา

วาง repository ทั้งสองไว้ในโฟลเดอร์เดียวกัน เพราะแอปใช้แพ็กเกจ `homeslot_client` ที่ backend generate ไว้:

```
HomeSlot/
├── homeslot-backend/     ← git repo backend (มี homeslot_client)
└── homeslot-frontend/    ← git repo นี้
```

```bash
# 1) รัน backend ก่อน (ดู README ของ homeslot-backend)
cd ../homeslot-backend/homeslot_server && serverpod start

# 2) รันแอป
cd ../../homeslot-frontend
flutter pub get
flutter run                                    # ใช้ http://localhost:8080 (Android emulator ใช้ 10.0.2.2)
flutter run --dart-define=SERVER_URL=http://192.168.1.20:8080/   # มือถือจริงในวง LAN
```

ถ้าแยกเครื่องและไม่ได้วาง backend ไว้ข้างกัน ให้เปลี่ยน dependency ใน `pubspec.yaml` เป็น git:

```yaml
homeslot_client:
  git:
    url: https://github.com/<you>/homeslot-backend.git
    path: homeslot_client
```

### ตัวเลือกตอน build (`--dart-define`)

| ค่า | ใช้ทำอะไร |
|---|---|
| `SERVER_URL` | ที่อยู่ server เช่น `https://homeslot.example.com/` (หรือใส่ `apiUrl` ใน `assets/config.json`) |
| `GOOGLE_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` | เปิดปุ่มเข้าสู่ระบบด้วย Google (ต้องตั้ง `googleClientSecret` ที่ server ด้วย) |

### Push Notification (Firebase Cloud Messaging)

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # สร้าง google-services.json และ GoogleService-Info.plist
```

ถ้ายังไม่ตั้งค่า แอปยังใช้งานได้ปกติ และดูการแจ้งเตือนได้ในหน้า "การแจ้งเตือน" ส่วน iOS ต้องมีบัญชี Apple Developer Program เพื่อใช้ APNs

## หน้าจอ (SRS 3.1)

| # | หน้าจอ | ไฟล์ |
|---|---|---|
| 1 | เข้าสู่ระบบ / สมัครสมาชิก / รีเซ็ตรหัสผ่าน | `lib/screens/sign_in_screen.dart` |
| 2 | สร้างบ้าน / เข้าร่วมบ้าน (รหัส 6 หลัก หรือสแกน QR) | `welcome_screen.dart`, `scan_screen.dart` |
| 3 | หน้าแรก: สถานะทุกห้องตอนนี้ + การจองถัดไปของฉัน | `home_screen.dart` |
| 4 | ปฏิทินห้อง รายวัน/รายสัปดาห์ แตะช่องว่างเพื่อจอง | `calendar_screen.dart`, `widgets/timeline.dart` |
| 5 | ฟอร์มการจอง (ครั้งเดียว / ข้ามวัน / ประจำทุกสัปดาห์ ≤ 12 สัปดาห์) | `booking_form_screen.dart` |
| 6 | การจองของฉัน: กำลังจะถึง / ที่ผ่านมา, แก้ไข ยกเลิก คืนห้อง | `my_bookings_screen.dart` |
| 7 | คำขออนุมัติ (ผู้ดูแลบ้าน) | `approvals_screen.dart` |
| 8 | จัดการห้อง: ข้อมูล รูป เวลาเปิดรายวัน กฎการจอง ปิดชั่วคราว | `rooms_screen.dart`, `room_edit_screen.dart` |
| 9 | จัดการสมาชิก บทบาท และรหัสเชิญ / QR Code | `members_screen.dart` |
| 10 | สถิติการใช้ห้อง (ตามห้อง ตามสมาชิก รายวัน Peak Hours) | `stats_screen.dart` |
| 11 | การแจ้งเตือน และตั้งค่า (ภาษา ธีม เวลาเตือน โปรไฟล์ ลบบัญชี) | `notifications_screen.dart`, `settings_screen.dart` |

## โครงสร้าง

```
lib/
├── main.dart, app.dart, router.dart   เริ่มแอป, ธีม, ภาษา, เส้นทาง (go_router)
├── core/     client (Serverpod), เวลาในโซนของบ้าน, ข้อความไทย/อังกฤษ, error, upload รูป
├── data/     cache ตารางล่าสุดใน SQLite (drift) สำหรับโหมดออฟไลน์
├── state/    Riverpod providers, real-time (WebSocket), push notification
├── screens/  11 หน้าจอตาม SRS
└── widgets/  timeline ปฏิทิน, การ์ดการจอง ฯลฯ
```

- **Real-time (SRS 2.3.8):** `state/realtime.dart` เปิด stream `events.subscribe` ค้างไว้ เมื่อมีคนจอง แก้ไข หรือยกเลิก ปฏิทินและหน้าแรกจะอัปเดตเองภายในไม่กี่วินาที และต่อใหม่อัตโนมัติเมื่อหลุด
- **ออฟไลน์ (SRS 4.4):** ทุกการโหลดข้อมูลเก็บสำเนาไว้ใน drift ถ้าต่อ server ไม่ได้จะแสดงข้อมูลล่าสุดพร้อมแถบ "กำลังออฟไลน์" และปิดปุ่มที่ต้องแก้ข้อมูล
- **เวลา (SRS 4.3):** แสดงเวลาในโซนเวลาของบ้านเสมอ (`core/time.dart`) แม้เครื่องจะอยู่ต่างประเทศ
- **ภาษาและธีม (SRS 4.7):** ไทย/อังกฤษ (`core/l10n.dart`) และโหมดมืด เลือกได้ในหน้าตั้งค่า
- **Deep link เชิญเข้าบ้าน:** `homeslot://app/join?code=123456` (QR Code ในหน้าสมาชิกใช้ลิงก์นี้)

## ทดสอบ

```bash
flutter analyze
flutter test
```

`test/screens_test.dart` render ทุกหน้าจอด้วยข้อมูลจริงทั้งภาษาไทยและอังกฤษ บนจอ 390 และ 360 px เพื่อจับปัญหา layout (เช่น ข้อความล้นจอ) ก่อนถึงมือผู้ใช้

ถ้าแก้ตารางใน `lib/data/cache_db.dart` ให้รัน `dart run build_runner build --delete-conflicting-outputs`

CI (`.github/workflows/ci.yml`) checkout ทั้ง frontend และ backend แล้วรัน analyze, format และ test ทุกครั้งที่ push
