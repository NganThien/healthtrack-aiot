import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../main_shell.dart';
import 'patient_list_screen.dart';
import 'patient_repository.dart';

/// Điểm vào sau khi đăng nhập: tải danh sách bệnh nhân của user rồi cho chọn.
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  final _repo = PatientRepository();
  late Future<List<Patient>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchMyPatients();
  }

  void _reload() => setState(() => _future = _repo.fetchMyPatients());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Patient>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Không tải được danh sách bệnh nhân:\n${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _reload, child: const Text('Thử lại')),
                  ],
                ),
              ),
            ),
          );
        }

        final patients = snapshot.data ?? const [];
        return PatientListScreen(
          patients: patients,
          onPatientAdded: _reload,
          onSelect: (patient) => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MainShell(patient: patient)),
          ),
        );
      },
    );
  }
}
