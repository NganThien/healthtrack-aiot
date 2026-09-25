import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/emg_reading.dart';
import '../dashboard/sensor_repository.dart';

/// MVP cho tab Phục hồi chức năng: hiển thị RMS EMG realtime dạng đồng hồ đo
/// + sóng RMS gần nhất. Bản đầy đủ (game "Sit-to-Stand" như bên web, xem
/// healthtrack-frontend/src/pages/SitToStandGamePage.jsx) sẽ port ở giai đoạn 2
/// vì cần dựng lại toàn bộ state machine + canvas game trên Flutter.
class RehabScreen extends StatelessWidget {
  final String deviceId;
  final double rmsThreshold;

  RehabScreen({super.key, required this.deviceId, this.rmsThreshold = 300});

  final SensorRepository _repo = SensorRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EmgReading?>(
      stream: _repo.watchLatestEmg(deviceId),
      builder: (context, snapshot) {
        final emg = snapshot.data;
        final rmsList = emg?.emgRmsList ?? const <double>[];
        final currentRms = rmsList.isNotEmpty ? rmsList.last : 0.0;
        final progress = (currentRms / rmsThreshold).clamp(0.0, 1.0);
        final active = currentRms >= rmsThreshold;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text('Phục hồi chức năng — Co cơ đùi (EMG)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Co cơ đùi để vượt ngưỡng RMS bên dưới. Bản game đầy đủ đang phát triển cho Flutter.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 14,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(active ? AppColors.success : AppColors.emg),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentRms.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.emg),
                        ),
                        Text('/ ${rmsThreshold.toStringAsFixed(0)} µV', style: const TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trạng thái', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      active ? 'Đang co cơ' : 'Thả lỏng',
                      style: TextStyle(
                        color: active ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emg == null ? 'Chưa có dữ liệu EMG' : 'Seq ${emg.seq ?? '--'} · ${rmsList.length} mẫu RMS/giây',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

