import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../patients/patient_shell.dart';
import 'login_screen.dart';

/// Lắng nghe trạng thái đăng nhập Supabase Auth và điều hướng tương ứng.
/// Đặt widget này làm home của MaterialApp.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseConfig.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? SupabaseConfig.client.auth.currentSession;
        if (session != null) return const PatientShell();
        return const LoginScreen();
      },
    );
  }
}
