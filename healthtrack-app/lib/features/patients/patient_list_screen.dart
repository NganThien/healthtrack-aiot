import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';
import '../../models/patient.dart';
import 'add_patient_screen.dart';

/// Danh sách bệnh nhân mà user hiện tại đang theo dõi. Chọn 1 để vào Dashboard,
/// hoặc thêm mới / đăng xuất.
class PatientListScreen extends StatelessWidget {
  final List<Patient> patients;
  final ValueChanged<Patient> onSelect;
  final VoidCallback onPatientAdded;

  const PatientListScreen({
    super.key,
    required this.patients,
    required this.onSelect,
    required this.onPatientAdded,
  });

  static const _roleLabels = {
    'owner': 'Chủ hồ sơ',
    'family': 'Người thân',
    'caregiver': 'Người chăm sóc',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bệnh nhân đang theo dõi'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => SupabaseConfig.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<Patient>(
            MaterialPageRoute(builder: (_) => const AddPatientScreen()),
          );
          if (created != null) onPatientAdded();
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm bệnh nhân'),
      ),
      body: patients.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có bệnh nhân nào. Bấm "Thêm bệnh nhân" để tạo hồ sơ '
                  'và ghép thiết bị đeo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: patients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(patient.fullName),
                    subtitle: Text(_roleLabels[patient.role] ?? patient.role),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onSelect(patient),
                  ),
                );
              },
            ),
    );
  }
}
