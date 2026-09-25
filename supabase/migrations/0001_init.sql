-- HealthTrack — Supabase schema (multi-user theo dõi chung 1 bệnh nhân)
-- Chạy trong Supabase SQL editor (hoặc `supabase db push`) trên project Cloud đã tạo.

-- ============================================================
-- 1. PROFILES — hồ sơ người dùng, 1-1 với auth.users
-- ============================================================
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text,
  phone      text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_self" on public.profiles
  for select using (id = auth.uid());
create policy "profiles_update_self" on public.profiles
  for update using (id = auth.uid());
create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

-- Tự tạo profile khi có user đăng ký mới qua Supabase Auth
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 2. PATIENTS — bệnh nhân được theo dõi (không phải tài khoản đăng nhập)
-- ============================================================
create table public.patients (
  id             uuid primary key default gen_random_uuid(),
  full_name      text not null,
  date_of_birth  date,
  notes          text,
  created_by     uuid references auth.users(id),
  created_at     timestamptz not null default now()
);

alter table public.patients enable row level security;

-- ============================================================
-- 3. PATIENT_MEMBERS — liên kết nhiều user với 1 patient (owner/family/caregiver)
-- ============================================================
create type public.patient_role as enum ('owner', 'family', 'caregiver');

create table public.patient_members (
  patient_id  uuid not null references public.patients(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  role        public.patient_role not null default 'family',
  invited_at  timestamptz not null default now(),
  primary key (patient_id, user_id)
);

alter table public.patient_members enable row level security;

-- Hàm SECURITY DEFINER để tránh RLS đệ quy khi policy tự query lại chính bảng patient_members
create or replace function public.is_patient_member(p_patient_id uuid)
returns boolean
language sql security definer stable
as $$
  select exists (
    select 1 from public.patient_members pm
    where pm.patient_id = p_patient_id and pm.user_id = auth.uid()
  );
$$;

create or replace function public.is_patient_owner(p_patient_id uuid)
returns boolean
language sql security definer stable
as $$
  select exists (
    select 1 from public.patient_members pm
    where pm.patient_id = p_patient_id and pm.user_id = auth.uid() and pm.role = 'owner'
  );
$$;

create policy "patients_select_members" on public.patients
  for select using (public.is_patient_member(id));
create policy "patients_insert_creator" on public.patients
  for insert with check (created_by = auth.uid());
create policy "patients_update_owner" on public.patients
  for update using (public.is_patient_owner(id));

create policy "patient_members_select" on public.patient_members
  for select using (public.is_patient_member(patient_id));
create policy "patient_members_insert_owner" on public.patient_members
  for insert with check (public.is_patient_owner(patient_id));
create policy "patient_members_delete_owner" on public.patient_members
  for delete using (public.is_patient_owner(patient_id));

-- Tự thêm người tạo patient làm 'owner' (bypass RLS vì hàm chạy SECURITY DEFINER)
create or replace function public.handle_new_patient()
returns trigger
language plpgsql security definer
as $$
begin
  insert into public.patient_members (patient_id, user_id, role)
  values (new.id, new.created_by, 'owner');
  return new;
end;
$$;

create trigger on_patient_created
  after insert on public.patients
  for each row execute function public.handle_new_patient();

-- ============================================================
-- 4. DEVICES — thiết bị đeo (device_id lấy từ firmware, vd 'health_device')
-- ============================================================
create table public.devices (
  id           text primary key,
  patient_id   uuid references public.patients(id) on delete set null,
  name         text,
  mac_address  text,
  created_at   timestamptz not null default now()
);

alter table public.devices enable row level security;

create or replace function public.device_patient_id(p_device_id text)
returns uuid
language sql security definer stable
as $$
  select patient_id from public.devices where id = p_device_id;
$$;

create policy "devices_select_members" on public.devices
  for select using (patient_id is not null and public.is_patient_member(patient_id));

-- Thiết bị chưa được ghép (bridge tự tạo khi lần đầu nhận MQTT, patient_id NULL) phải
-- SELECT được thì app mới cho người dùng "nhập device ID để ghép" tìm ra nó. Không lộ
-- dữ liệu nhạy cảm vì thiết bị unclaimed chưa gắn với patient/bệnh nhân nào.
create policy "devices_select_unclaimed" on public.devices
  for select using (patient_id is null);

-- Ghép thiết bị (device do bridge tạo sẵn với patient_id NULL) vào patient mình đang là thành viên,
-- hoặc cập nhật thiết bị đã thuộc patient mình đang là thành viên.
create policy "devices_claim_or_manage" on public.devices
  for update
  using (patient_id is null or public.is_patient_member(patient_id))
  with check (patient_id is not null and public.is_patient_member(patient_id));

-- Cho phép tự thêm thiết bị mới và gán thẳng cho patient mình sở hữu/thuộc về
create policy "devices_insert_members" on public.devices
  for insert with check (patient_id is not null and public.is_patient_member(patient_id));

-- ============================================================
-- 5. SENSOR_DATA — dữ liệu Node1 (MPU6050 / fall detection), giữ nguyên cấu trúc cột cũ
-- ============================================================
create table public.sensor_data (
  id              bigint generated always as identity primary key,
  device_id       text not null references public.devices(id),
  "timestamp"     bigint not null,
  timestamp_ms    bigint,
  seq             int,
  mpu_status      boolean,
  battery_pct     int,
  voltage         real,
  prediction      int,
  event           varchar(50),
  clock_synced    boolean,
  delayed_upload  boolean,
  acc_mag         real,
  angle           real,
  ax_g            real,
  ay_g            real,
  az_g            real,
  created_at      timestamptz not null default now()
);

create index idx_sensor_data_device_time on public.sensor_data (device_id, "timestamp" desc);

alter table public.sensor_data enable row level security;

create policy "sensor_data_select_members" on public.sensor_data
  for select using (public.is_patient_member(public.device_patient_id(device_id)));

-- ============================================================
-- 6. EMG_DATA — dữ liệu Node2 (AD8232 / rehab EMG)
-- ============================================================
create table public.emg_data (
  id             bigint generated always as identity primary key,
  device_id      text not null references public.devices(id),
  "timestamp"    bigint not null,
  timestamp_ms   bigint,
  seq            int,
  emg_status     boolean,
  emg_raw_list   jsonb,
  emg_rms_list   jsonb,
  created_at     timestamptz not null default now()
);

create index idx_emg_data_device_time on public.emg_data (device_id, "timestamp" desc);

alter table public.emg_data enable row level security;

create policy "emg_data_select_members" on public.emg_data
  for select using (public.is_patient_member(public.device_patient_id(device_id)));

-- ============================================================
-- 7. Bật Realtime cho các bảng app Flutter cần subscribe trực tiếp
-- ============================================================
alter publication supabase_realtime add table public.sensor_data;
alter publication supabase_realtime add table public.emg_data;

-- ============================================================
-- Ghi chú:
-- - Việc INSERT vào devices/sensor_data/emg_data từ MQTT-bridge dùng SERVICE ROLE KEY
--   nên bỏ qua toàn bộ RLS phía trên (chỉ áp dụng cho client Flutter/React dùng anon key).
-- - "Fall events" KHÔNG có bảng riêng ở bản MVP này: app đọc trực tiếp
--   sensor_data WHERE prediction IN (1,2), giống cách backend cũ đang làm
--   (xem healthtrack-backend/src/controllers/sensor.controller.js).
--   Có thể tách bảng fall_events + trigger phát hiện transition ở giai đoạn 2
--   khi cần push notification (FCM) chống báo trùng lặp.
-- ============================================================
