import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/sensor_reading.dart';
import 'sensor_repository.dart';

const _activityLabels = {
  'standing': 'Bình thường',
  'near_fall': 'Suýt ngã',
  'fall': 'Té ngã',
};

const _causeLabels = {
  'mechanical_instability': 'Mất ổn định cơ học',
  'sudden_acceleration': 'Gia tốc đột ngột',
  'loss_of_balance': 'Mất thăng bằng',
};

const _postureLabels = {
  'on_ground': 'Nằm dưới sàn',
  'assisted_recovery': 'Được hỗ trợ phục hồi',
  'recovered_standing': 'Đã tự phục hồi',
};

class DashboardScreen extends StatefulWidget {
  final String deviceId;

  const DashboardScreen({super.key, required this.deviceId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = SensorRepository();
  SensorReading? _dismissedFall;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorReading?>(
      stream: _repo.watchLatest(widget.deviceId),
      builder: (context, snapshot) {
        final latest = snapshot.data;
        final showBanner = latest != null &&
            (latest.isFall || latest.isRisk) &&
            latest.timestamp != _dismissedFall?.timestamp;

        return RefreshIndicator(
          onRefresh: () async {}, // stream tự cập nhật; kéo để tạo cảm giác quen thuộc
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _StatusHeader(latest: latest),
              if (showBanner) ...[
                const SizedBox(height: 16),
                _FallBanner(
                  reading: latest,
                  onDismiss: () => setState(() => _dismissedFall = latest),
                ),
              ],
              const SizedBox(height: 16),
              _RiskCard(latest: latest),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _MetricCard(
                    label: 'Gia tốc tổng',
                    value: latest?.accMag?.toStringAsFixed(2) ?? '--',
                    unit: 'g',
                    color: AppColors.imuAcc,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _MetricCard(
                    label: 'Góc nghiêng',
                    value: latest?.tiltAngle?.toStringAsFixed(1) ?? '--',
                    unit: '°',
                    color: AppColors.imuGyro,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _MetricCard(
                label: 'Toạ độ 3 trục (Ax, Ay, Az)',
                value: latest == null
                    ? '--'
                    : '${latest.axG?.toStringAsFixed(2)}, ${latest.ayG?.toStringAsFixed(2)}, ${latest.azG?.toStringAsFixed(2)}',
                unit: 'g',
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final SensorReading? latest;

  const _StatusHeader({required this.latest});

  @override
  Widget build(BuildContext context) {
    final reading = latest;
    final batteryOk = (reading?.batteryPct ?? 0) > 25;
    final batteryLabel = reading?.batteryPct == null ? '--' : '${reading!.batteryPct}%';
    final updatedAt = reading == null
        ? 'Đang đợi dữ liệu từ cảm biến...'
        : 'Cập nhật lúc ${DateFormat.Hms().format(
            DateTime.fromMillisecondsSinceEpoch(reading.timestamp * 1000),
          )}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HealthTrack Monitor', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(updatedAt, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        _Chip(
          label: batteryLabel,
          color: batteryOk ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }
}

class _FallBanner extends StatelessWidget {
  final SensorReading reading;
  final VoidCallback onDismiss;

  const _FallBanner({required this.reading, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = reading.isFall ? AppColors.danger : AppColors.warning;
    return Card(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activityLabels[reading.activityLabel] ?? reading.activityLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Nguyên nhân: ${_causeLabels[reading.causeHint] ?? reading.causeHint}'),
            Text('Trạng thái sau sự cố: ${_postureLabels[reading.postureAfterEvent] ?? reading.postureAfterEvent}'),
            Text('Gia tốc cực đại: ${reading.accMag?.toStringAsFixed(2) ?? '--'} g'),
            Text('Góc nghiêng cực đại: ${reading.tiltAngle?.toStringAsFixed(1) ?? '--'}°'),
          ],
        ),
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final SensorReading? latest;

  const _RiskCard({required this.latest});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (latest?.prediction) {
      null => ('Không có dữ liệu', AppColors.textMuted),
      0 => ('An toàn', AppColors.success),
      1 => ('Nguy cơ cao', AppColors.warning),
      _ => ('NGUY HIỂM', AppColors.danger),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trạng thái phát hiện ngã', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  latest?.event ?? 'Normal',
                  style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                _Chip(label: label, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cảm biến MPU: ${latest?.mpuStatus == true ? "Hoạt động tốt" : "Mất kết nối"}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
