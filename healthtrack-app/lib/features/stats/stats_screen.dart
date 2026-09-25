import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/sensor_reading.dart';
import '../dashboard/sensor_repository.dart';

enum _ChartMetric { axG, ayG, azG, accMag, tiltAngle }

const _metricLabels = {
  _ChartMetric.axG: 'Trục X',
  _ChartMetric.ayG: 'Trục Y',
  _ChartMetric.azG: 'Trục Z',
  _ChartMetric.accMag: 'Gia tốc tổng',
  _ChartMetric.tiltAngle: 'Góc nghiêng',
};

class StatsScreen extends StatefulWidget {
  final String deviceId;

  const StatsScreen({super.key, required this.deviceId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _repo = SensorRepository();
  _ChartMetric _metric = _ChartMetric.accMag;

  late Future<List<SensorReading>> _fallEventsFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fallEventsFuture = _repo.fetchFallEvents(widget.deviceId);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _fallEventsFuture = _repo.fetchFallEvents(widget.deviceId));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  double? _valueOf(SensorReading r, _ChartMetric metric) {
    switch (metric) {
      case _ChartMetric.axG:
        return r.axG;
      case _ChartMetric.ayG:
        return r.ayG;
      case _ChartMetric.azG:
        return r.azG;
      case _ChartMetric.accMag:
        return r.accMag;
      case _ChartMetric.tiltAngle:
        return r.tiltAngle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('Biến thiên tín hiệu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _ChartMetric.values.map((m) {
            return ChoiceChip(
              label: Text(_metricLabels[m]!),
              selected: _metric == m,
              onSelected: (_) => setState(() => _metric = m),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 240,
              child: StreamBuilder<List<SensorReading>>(
                stream: _repo.watchHistory(widget.deviceId, limit: 100),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? const [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: AppColors.textMuted)));
                  }

                  final spots = <FlSpot>[];
                  for (var i = 0; i < data.length; i++) {
                    final v = _valueOf(data[i], _metric);
                    if (v != null) spots.add(FlSpot(i.toDouble(), v));
                  }

                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.imuAcc,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Lịch sử sự cố', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FutureBuilder<List<SensorReading>>(
          future: _fallEventsFuture,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const [];
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Không có sự cố nào được ghi nhận.', style: TextStyle(color: AppColors.textMuted)),
              );
            }

            return Column(
              children: events.map((e) {
                final color = e.isFall ? AppColors.danger : AppColors.warning;
                final time = DateFormat('dd/MM HH:mm:ss')
                    .format(DateTime.fromMillisecondsSinceEpoch(e.timestamp * 1000));
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: color),
                    title: Text(e.isFall ? 'Té ngã' : 'Suýt ngã', style: TextStyle(color: color)),
                    subtitle: Text(
                      'Gia tốc ${e.accMag?.toStringAsFixed(2) ?? '--'} g · '
                      'Góc ${e.tiltAngle?.toStringAsFixed(1) ?? '--'}°',
                    ),
                    trailing: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
