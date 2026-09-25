import 'package:flutter/material.dart';

import 'patient_repository.dart';

/// Ghép 1 thiết bị đeo (device_id lấy từ firmware ESP32) vào patient đã chọn.
/// Dùng khi patient chưa có thiết bị nào, hoặc muốn thêm thiết bị thứ 2.
class LinkDeviceScreen extends StatefulWidget {
  final String patientId;

  const LinkDeviceScreen({super.key, required this.patientId});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = PatientRepository();
  final _deviceIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.linkDevice(
        deviceId: _deviceIdCtrl.text.trim(),
        patientId: widget.patientId,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghép thiết bị đeo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập Device ID được in trên thiết bị hoặc xem trong log Serial '
                  'của firmware (biến DEVICE_ID, mặc định "health_device").',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _deviceIdCtrl,
                  decoration: const InputDecoration(labelText: 'Device ID'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên gợi nhớ (tuỳ chọn)'),
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
                      : const Text('Ghép thiết bị'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
