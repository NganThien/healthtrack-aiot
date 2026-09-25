/// Một bản ghi từ bảng `emg_data` (Node2 - AD8232 / rehab EMG), batch 50 mẫu/giây.
class EmgReading {
  final String deviceId;
  final int timestamp;
  final int? seq;
  final bool? emgStatus;
  final List<double> emgRawList;
  final List<double> emgRmsList;

  const EmgReading({
    required this.deviceId,
    required this.timestamp,
    this.seq,
    this.emgStatus,
    this.emgRawList = const [],
    this.emgRmsList = const [],
  });

  factory EmgReading.fromMap(Map<String, dynamic> row) {
    return EmgReading(
      deviceId: row['device_id'] as String,
      timestamp: (row['timestamp'] as num?)?.toInt() ?? 0,
      seq: (row['seq'] as num?)?.toInt(),
      emgStatus: row['emg_status'] as bool?,
      emgRawList: _asDoubleList(row['emg_raw_list']),
      emgRmsList: _asDoubleList(row['emg_rms_list']),
    );
  }
}

List<double> _asDoubleList(dynamic value) {
  if (value is List) {
    return value.map((e) => (e as num).toDouble()).toList();
  }
  return const [];
}
