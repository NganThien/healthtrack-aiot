/// Một bản ghi từ bảng `sensor_data` (Node1 - MPU6050 / fall detection).
/// Field naming và logic suy ra activity_label/cause_hint/posture khớp với
/// healthtrack-backend/src/utils/mapRow.js để 2 nền tảng hiển thị nhất quán.
class SensorReading {
  final String deviceId;
  final int timestamp; // epoch seconds
  final int? seq;
  final bool? mpuStatus;
  final int? batteryPct;
  final double? voltage;
  final int? prediction;
  final String? event;
  final double? accMag;
  final double? tiltAngle;
  final double? axG;
  final double? ayG;
  final double? azG;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    this.seq,
    this.mpuStatus,
    this.batteryPct,
    this.voltage,
    this.prediction,
    this.event,
    this.accMag,
    this.tiltAngle,
    this.axG,
    this.ayG,
    this.azG,
  });

  factory SensorReading.fromMap(Map<String, dynamic> row) {
    return SensorReading(
      deviceId: row['device_id'] as String,
      timestamp: _asInt(row['timestamp']) ?? 0,
      seq: _asInt(row['seq']),
      mpuStatus: row['mpu_status'] as bool?,
      batteryPct: _asInt(row['battery_pct']),
      voltage: _asDouble(row['voltage']),
      prediction: _asInt(row['prediction']),
      event: row['event'] as String?,
      accMag: _asDouble(row['acc_mag']),
      tiltAngle: _asDouble(row['angle']),
      axG: _asDouble(row['ax_g']),
      ayG: _asDouble(row['ay_g']),
      azG: _asDouble(row['az_g']),
    );
  }

  /// standing | near_fall | fall — giống mapActivityLabel() bên Node backend.
  String get activityLabel {
    if (prediction == 2 || event == '!!! FALL !!!') return 'fall';
    if (prediction == 1 || event == 'Risk') return 'near_fall';
    return 'standing';
  }

  /// mechanical_instability | sudden_acceleration | loss_of_balance
  String get causeHint {
    final angle = tiltAngle ?? 0;
    final acc = accMag ?? 0;
    if (angle > 60) return 'mechanical_instability';
    if (acc > 2.5) return 'sudden_acceleration';
    return 'loss_of_balance';
  }

  /// on_ground | assisted_recovery | recovered_standing
  String get postureAfterEvent {
    final angle = tiltAngle ?? 0;
    if (angle > 70) return 'on_ground';
    if (angle > 45) return 'assisted_recovery';
    return 'recovered_standing';
  }

  bool get isFall => prediction == 2 || event == '!!! FALL !!!';
  bool get isRisk => prediction == 1 || event == 'Risk';
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
