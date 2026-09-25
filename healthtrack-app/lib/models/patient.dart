/// Bệnh nhân đang được theo dõi (bảng `patients`, liên kết qua `patient_members`).
class Patient {
  final String id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? notes;
  final String role; // owner | family | caregiver — vai trò của user hiện tại

  const Patient({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.notes,
    required this.role,
  });

  factory Patient.fromMap(Map<String, dynamic> row) {
    return Patient(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      dateOfBirth: row['date_of_birth'] != null
          ? DateTime.tryParse(row['date_of_birth'] as String)
          : null,
      notes: row['notes'] as String?,
      role: (row['patient_members'] as List?)?.isNotEmpty == true
          ? (row['patient_members'] as List).first['role'] as String
          : 'family',
    );
  }
}

/// Thiết bị đeo (bảng `devices`) đã được gán cho 1 patient.
class DeviceInfo {
  final String id;
  final String? patientId;
  final String? name;
  final String? macAddress;

  const DeviceInfo({
    required this.id,
    this.patientId,
    this.name,
    this.macAddress,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> row) {
    return DeviceInfo(
      id: row['id'] as String,
      patientId: row['patient_id'] as String?,
      name: row['name'] as String?,
      macAddress: row['mac_address'] as String?,
    );
  }
}
