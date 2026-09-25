# HealthTrack App (Flutter)

Ứng dụng di động cho hệ thống HealthTrack — cho phép nhiều người dùng (chủ hồ sơ,
người thân, người chăm sóc) cùng theo dõi realtime một bệnh nhân đang đeo thiết bị
phát hiện ngã, xem lịch sử cảm biến, và (MVP) theo dõi tín hiệu EMG phục hồi chức năng.

## Kiến trúc

```
[ESP32 Node1/Node2] --MQTT--> [healthtrack-backend bridge, Docker] --Postgres--> [Supabase Cloud]
                                                                                        |
                                                        Auth + Realtime + PostgREST + RLS
                                                                                        |
                                                                [Flutter app] & [React web]
```

- **Supabase Cloud** đóng vai trò backend chính cho app: Auth (đăng ký/đăng nhập),
  Postgres (bảng `patients`, `patient_members`, `devices`, `sensor_data`, `emg_data`),
  Realtime (app subscribe trực tiếp, không cần WebSocket tự viết) và Row Level Security
  (mỗi user chỉ thấy dữ liệu của bệnh nhân mình được gán).
- **healthtrack-backend** (thư mục gốc repo) được giữ lại, đóng vai trò cầu nối
  MQTT → Postgres của Supabase (xem `healthtrack-backend/src/mqtt.js`), đồng thời vẫn
  phục vụ web React qua REST/WebSocket như trước.
- App Flutter **không gọi qua backend Node** — dùng thẳng `supabase_flutter` SDK.

## Thiết lập Supabase (làm 1 lần)

1. Tạo project mới tại [supabase.com](https://supabase.com).
2. Vào **SQL Editor**, chạy toàn bộ nội dung file
   [`../supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql).
3. Vào **Project Settings → API Keys**, lấy `Project URL` và `anon public key`
   (Supabase gần đây đổi tên thành "publishable key" — cùng một giá trị).
4. Vào **Project Settings → Database → Connection string**, lấy connection string
   ở mục **Session pooler** (port 5432) — dùng cho `healthtrack-backend` (xem
   `healthtrack-backend/.env.example`), KHÔNG dùng Transaction pooler (6543).

## Chạy app

```powershell
cd healthtrack-app
cp .env.example .env
# Điền SUPABASE_URL và SUPABASE_ANON_KEY vào .env

flutter pub get
flutter run
```

Build APK để cài trực tiếp lên điện thoại test:

```powershell
flutter build apk --debug
# APK nằm ở build\app\outputs\flutter-apk\app-debug.apk
```

> **Lưu ý Windows nhiều ổ đĩa:** nếu Flutter SDK và project nằm khác ổ đĩa
> (vd SDK ở `C:`, project ở `D:`), Kotlin incremental compiler có thể lỗi
> `"this and base files have different roots"` khi build Android. Đã tắt sẵn
> bằng `kotlin.incremental=false` trong `android/gradle.properties`.

## Cấu trúc thư mục

```
lib/
  core/               # Supabase client + theme dùng chung
  models/             # SensorReading, EmgReading, Patient, DeviceInfo
  features/
    auth/             # Đăng nhập / đăng ký (Supabase Auth)
    patients/         # Chọn/tạo bệnh nhân, ghép thiết bị, mời thành viên
    dashboard/         # Trạng thái realtime + repository đọc sensor_data/emg_data
    stats/            # Biểu đồ lịch sử (fl_chart) + lịch sử sự cố té ngã
    rehab/            # MVP đồng hồ đo RMS EMG (chưa phải game đầy đủ)
```

## Việc còn thiếu / hướng phát triển tiếp (Phase 2)

- **Push notification khi té ngã** khi app đang đóng: cần bảng `fall_events` +
  trigger DB phát hiện transition (0 → 1/2) + Supabase Edge Function gọi FCM.
  Hiện tại cảnh báo chỉ hoạt động khi app đang mở (qua Realtime stream).
- **Port đầy đủ game "Sit-to-Stand"** từ
  `healthtrack-frontend/src/pages/SitToStandGamePage.jsx` (canvas + state machine)
  sang Flutter (CustomPainter hoặc package game engine).
- **Đổi bệnh nhân đang xem** ngay trong `MainShell` (hiện phải quay lại danh sách).
- **Trang quản lý thành viên** (mời/xoá family/caregiver) cho `patient_members`.
- **Export CSV** dữ liệu lịch sử (giống nút "Xuất file CSV" bên web).
