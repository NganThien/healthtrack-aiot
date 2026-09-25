import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'dashboard/dashboard_screen.dart';
import 'patients/link_device_screen.dart';
import 'patients/patient_repository.dart';
import 'rehab/rehab_screen.dart';
import 'stats/stats_screen.dart';

/// Sau khi chọn 1 patient: tải thiết bị của patient đó rồi hiển thị
/// Dashboard / Stats / Rehab qua BottomNavigationBar, giống 3 tab bên web
/// (Health / Stats / Rehab — xem healthtrack-frontend/src/components/Navbar.jsx).
class MainShell extends StatefulWidget {
  final Patient patient;

  const MainShell({super.key, required this.patient});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _repo = PatientRepository();
  late Future<List<DeviceInfo>> _devicesFuture;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    _devicesFuture = _repo.fetchDevicesForPatient(widget.patient.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.patient.fullName)),
      body: FutureBuilder<List<DeviceInfo>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? const [];
          if (devices.isEmpty) {
            return _NoDeviceView(
              patientId: widget.patient.id,
              onLinked: () => setState(_loadDevices),
            );
          }

          final deviceId = devices.first.id;
          return IndexedStack(
            index: _tabIndex,
            children: [
              DashboardScreen(deviceId: deviceId),
              StatsScreen(deviceId: deviceId),
              RehabScreen(deviceId: deviceId),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.accessibility_new), label: 'Rehab'),
        ],
      ),
    );
  }
}

class _NoDeviceView extends StatelessWidget {
  final String patientId;
  final VoidCallback onLinked;

  const _NoDeviceView({required this.patientId, required this.onLinked});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Bệnh nhân này chưa được ghép thiết bị đeo nào.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final linked = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => LinkDeviceScreen(patientId: patientId)),
                );
                if (linked == true) onLinked();
              },
              child: const Text('Ghép thiết bị'),
            ),
          ],
        ),
      ),
    );
  }
}
