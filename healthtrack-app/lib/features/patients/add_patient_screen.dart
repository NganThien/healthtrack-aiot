import 'package:flutter/material.dart';

import 'patient_repository.dart';

/// Form tạo bệnh nhân mới (đồng thời tự trở thành 'owner') và tuỳ chọn
/// ghép ngay 1 thiết bị đeo (device_id lấy từ firmware, vd 'health_device').
class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PatientRepository();
  final _nameCtrl = TextEditingController();
  final _deviceIdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deviceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patient = await _repo.createPatient(fullName: _nameCtrl.text.trim());

      final deviceId = _deviceIdCtrl.text.trim();
      if (deviceId.isNotEmpty) {
        await _repo.linkDevice(deviceId: deviceId, patientId: patient.id);
      }

      if (mounted) Navigator.of(context).pop(patient);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bệnh nhân')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tạo hồ sơ người cần theo dõi. Bạn có thể mời thêm người thân/'
                  'người chăm sóc cùng theo dõi sau khi tạo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ tên bệnh nhân'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device ID (tuỳ chọn)',
                    hintText: 'vd: health_device — có thể ghép sau',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tạo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
