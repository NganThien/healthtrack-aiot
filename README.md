# HealthTrack System - Overview

Hệ thống theo dõi sức khỏe và cảnh báo té ngã tích hợp IoT, Backend và Frontend.

## Giới thiệu tổng quan
HealthTrack là một giải pháp toàn diện cho phép theo dõi các chỉ số sinh tồn (nhịp tim, SpO2, HRV) và các thông số vật lý (gia tốc, góc nghiêng, EMG) của người dùng theo thời gian thực. Hệ thống đặc biệt tập trung vào khả năng phát hiện và cảnh báo các sự kiện té ngã hoặc suýt té ngã dựa trên dữ liệu từ cảm biến.

Hệ thống bao gồm ba thành phần chính:
1.  **[HealthTrack Backend](./healthtrack-backend):** Cầu nối MQTT → Postgres (Supabase), kèm REST/WebSocket phục vụ web.
2.  **[HealthTrack Frontend](./healthtrack-frontend):** Giao diện web trực quan để theo dõi dữ liệu và quản lý thiết bị.
3.  **[HealthTrack App](./healthtrack-app):** Ứng dụng Flutter cho nhiều người dùng (gia đình/người chăm sóc) cùng theo dõi một bệnh nhân, đọc trực tiếp qua Supabase.

## Kiến trúc hệ thống
```text
[Thiết bị IoT] --(MQTT)--> [HiveMQ Cloud] <--(MQTT)--> [Backend bridge (Node.js, Docker)]
                                                            |
                                                  Postgres của Supabase Cloud
                                                            |
                                    +---------------+---------------------+---------------+
                                    |                                                     |
                          Auth + Realtime + RLS                                  [WebSocket (Real-time)]
                                    |                                                     |
                          [App Flutter (mobile)]                                [Frontend web (React)]
```

Schema Supabase (bảng, RLS, trigger) nằm ở [supabase/migrations/0001_init.sql](./supabase/migrations/0001_init.sql).
Hướng dẫn thiết lập/chạy app Flutter xem [healthtrack-app/README.md](./healthtrack-app/README.md).

## Các tính năng nổi bật
- **Theo dõi thời gian thực:** Hiển thị dữ liệu nhịp tim, SpO2, EMG và các chỉ số khác ngay lập tức qua WebSocket.
- **Cảnh báo té ngã:** Tự động tính toán điểm rủi ro (Risk Score) và gửi cảnh báo khi phát hiện sự cố.
- **Biểu đồ lịch sử:** Trực quan hóa xu hướng sức khỏe qua các biểu đồ Recharts.
- **Quản lý thiết bị:** Quản lý trạng thái online/offline, pin và cấu hình thiết bị.
- **Xuất dữ liệu:** Hỗ trợ xuất lịch sử cảm biến ra file CSV để phân tích.

## Công nghệ sử dụng
- **Backend:** Node.js, Express, MQTT (HiveMQ), WebSocket (ws), Docker.
- **Dữ liệu & Auth:** Supabase Cloud (PostgreSQL, Auth, Realtime, Row Level Security).
- **Frontend web:** React, Vite, Recharts, Axios.
- **App di động:** Flutter, supabase_flutter, fl_chart.
- **Hạ tầng:** MQTT Broker (HiveMQ Cloud), Docker cho backend bridge.

## Hướng dẫn cài đặt nhanh

### 1. Chuẩn bị
- Tạo project **Supabase Cloud** và chạy migration [supabase/migrations/0001_init.sql](./supabase/migrations/0001_init.sql) (SQL Editor).
- Cài **Node.js** (chạy backend trực tiếp) hoặc **Docker** (chạy qua container — xem `docker-compose.yml`).
- Cài **Flutter SDK** nếu muốn build app di động.

### 2. Khởi chạy Backend (MQTT-bridge)
```powershell
cd healthtrack-backend
cp .env.example .env
# Điền DATABASE_URL (Session pooler của Supabase) vào .env
npm install
npm run dev
```
Hoặc chạy bằng Docker từ thư mục gốc:
```powershell
docker compose up -d --build
```

### 3. Khởi chạy Frontend
```powershell
cd healthtrack-frontend
npm install
# Cấu hình file .env
npm run dev
```

Truy cập giao diện tại: `http://localhost:5173`

### 4. Khởi chạy App Flutter
```powershell
cd healthtrack-app
cp .env.example .env
# Điền SUPABASE_URL và SUPABASE_ANON_KEY vào .env
flutter pub get
flutter run
```

---
*Chi tiết cụ thể về từng phần có thể tìm thấy trong thư mục con tương ứng:*
- [Tài liệu Backend](./healthtrack-backend/README.md)
- [Tài liệu Frontend](./healthtrack-frontend/README.md)
- [Tài liệu App Flutter](./healthtrack-app/README.md)
### 5. Thiết kế node MPU
- Node MPU được thiết kế sử dụng ESP32C3, MPU6050, mạch sạc TP4056 và Pin 3.7v được thiết kế như sau:
<img width="1322" height="920" alt="image" src="https://github.com/user-attachments/assets/29d290c6-04b0-4261-ace8-3a3f5394ccd8" />
