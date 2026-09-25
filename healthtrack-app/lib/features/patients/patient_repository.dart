import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../models/patient.dart';

/// Truy vấn bảng patients / patient_members / devices.
/// Toàn bộ quyền truy cập do RLS ở Supabase quyết định (xem
/// supabase/migrations/0001_init.sql) — repository này chỉ gọi query trần.
class PatientRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Chưa đăng nhập.');
    return user.id;
  }

  /// Danh sách bệnh nhân mà user hiện tại là thành viên (owner/family/caregiver).
  Future<List<Patient>> fetchMyPatients() async {
    final rows = await _client
        .from('patients')
        .select('id, full_name, date_of_birth, notes, patient_members!inner(role)')
        .eq('patient_members.user_id', _userId)
        .order('created_at');

    return (rows as List)
        .map((row) => Patient.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Tạo bệnh nhân mới — trigger DB sẽ tự thêm user hiện tại làm 'owner'.
  Future<Patient> createPatient({
    required String fullName,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    final row = await _client
        .from('patients')
        .insert({
          'full_name': fullName,
          'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
          'notes': notes,
          'created_by': _userId,
        })
        .select()
        .single();

    return Patient.fromMap({...row, 'patient_members': []});
  }

  /// Mời thêm 1 người dùng khác (đã có tài khoản) vào theo dõi cùng patient.
  /// Chỉ owner mới được phép (thực thi bởi RLS policy patient_members_insert_owner).
  Future<void> inviteMember({
    required String patientId,
    required String memberUserId,
    String role = 'family',
  }) async {
    await _client.from('patient_members').insert({
      'patient_id': patientId,
      'user_id': memberUserId,
      'role': role,
    });
  }

  Future<List<DeviceInfo>> fetchDevicesForPatient(String patientId) async {
    final rows = await _client
        .from('devices')
        .select()
        .eq('patient_id', patientId)
        .order('created_at');

    return (rows as List)
        .map((row) => DeviceInfo.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Ghép thiết bị đeo (theo device_id in firmware, vd 'health_device') vào 1 patient.
  /// - Nếu thiết bị đã tồn tại (đã có dữ liệu MQTT gửi lên) nhưng chưa được ghép: UPDATE.
  /// - Nếu thiết bị chưa từng gửi dữ liệu (đăng ký trước phần cứng): INSERT mới.
  Future<void> linkDevice({
    required String deviceId,
    required String patientId,
    String? name,
  }) async {
    final existing = await _client
        .from('devices')
        .select('id, patient_id')
        .eq('id', deviceId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('devices').insert({
        'id': deviceId,
        'patient_id': patientId,
        if (name != null) 'name': name,
      });
      return;
    }

    if (existing['patient_id'] != null && existing['patient_id'] != patientId) {
      throw StateError('Thiết bị "$deviceId" đã được ghép với bệnh nhân khác.');
    }

    await _client.from('devices').update({
      'patient_id': patientId,
      if (name != null) 'name': name,
    }).eq('id', deviceId);
  }
}
