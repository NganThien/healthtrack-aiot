import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Khởi tạo kết nối Supabase cho toàn app. Gọi 1 lần trong main() trước
/// khi runApp(). URL/anon key đọc từ file .env (không commit, xem .env.example).
class SupabaseConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || url.contains('xxxxxxxxxxxx')) {
      throw StateError(
        'Chưa cấu hình SUPABASE_URL/SUPABASE_ANON_KEY. '
        'Sao chép .env.example thành .env và điền thông tin project Supabase.',
      );
    }

    // publishableKey = tên mới của "anon/public key" trên Supabase Dashboard
    // (Project Settings > API Keys). Cùng giá trị, chỉ đổi tên tham số.
    await Supabase.initialize(url: url, publishableKey: anonKey!);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
