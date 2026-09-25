import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../models/emg_reading.dart';
import '../../models/sensor_reading.dart';

/// Đọc dữ liệu sensor_data/emg_data.
///
/// Lưu ý về Supabase Realtime: giao thức "postgres_changes" chỉ hỗ trợ MỘT
/// điều kiện lọc dạng column=eq.value, không hỗ trợ IN/OR. Vì vậy:
/// - watchLatest / watchHistory (chỉ lọc theo device_id) dùng .stream() —
///   tự cập nhật realtime, không cần WebSocket/polling thủ công như bên web.
/// - fetchFallEvents (lọc prediction IN (1,2)) phải query PostgREST thường,
///   gọi lại định kỳ từ UI (giống cách sensorService.getFallEventHistory
///   polling mỗi vài giây bên healthtrack-frontend).
class SensorRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  /// Luồng realtime bản ghi motion mới nhất của 1 thiết bị.
  Stream<SensorReading?> watchLatest(String deviceId) {
    return _client
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : SensorReading.fromMap(rows.first));
  }

  /// Luồng realtime N bản ghi gần nhất (dùng vẽ biểu đồ), trả về theo thứ tự
  /// thời gian TĂNG DẦN (đã đảo lại) để vẽ trực tiếp lên LineChart.
  Stream<List<SensorReading>> watchHistory(String deviceId, {int limit = 120}) {
    return _client
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(limit)
        .map((rows) => rows.reversed.map(SensorReading.fromMap).toList());
  }

  Stream<EmgReading?> watchLatestEmg(String deviceId) {
    return _client
        .from('emg_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((rows) => rows.isEmpty ? null : EmgReading.fromMap(rows.first));
  }

  /// Sự cố té ngã / suýt ngã gần đây (prediction 1 hoặc 2). Gọi lại định kỳ
  /// từ UI vì Realtime không lọc được nhiều giá trị cùng lúc (xem ghi chú ở trên).
  Future<List<SensorReading>> fetchFallEvents(String deviceId, {int limit = 20}) async {
    final rows = await _client
        .from('sensor_data')
        .select()
        .eq('device_id', deviceId)
        .inFilter('prediction', [1, 2])
        .order('timestamp', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
