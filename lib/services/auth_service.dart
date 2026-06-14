import 'supabase_service.dart';
import '../models/user_model.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  Future<UserModel> login(String identifier, String password) async {
    try {
      // Find user by username or email
      final response = await SupabaseService.client
          .from('taikhoan')
          .select('username, email, marole, password, is_active, nhanvien(hoten)')
          .or('username.eq.$identifier,email.eq.$identifier')
          .maybeSingle();

      if (response == null) {
        throw Exception('Tên đăng nhập không chính xác.');
      }

      final isActive = response['is_active'] ?? true;
      if (!isActive) {
        throw Exception('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản lý.');
      }

      final dbPassword = response['password'] as String;
      bool isMatch = false;

      // Kiểm tra xem password trong DB có phải là hash BCrypt hay text thường (cho tài khoản cũ)
      if (dbPassword.startsWith('\$2a\$') || dbPassword.startsWith('\$2b\$')) {
        try {
          isMatch = BCrypt.checkpw(password, dbPassword);
        } catch (_) {}
      } else {
        isMatch = (dbPassword == password);
      }

      if (!isMatch) {
        throw Exception('Mật khẩu không chính xác.');
      }

      // Update online status
      await SupabaseService.client
          .from('taikhoan')
          .update({'is_online': true})
          .eq('username', response['username']);

      return UserModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('Tên đăng nhập hoặc mật khẩu')) {
        rethrow;
      }
      throw Exception('Đã xảy ra lỗi khi đăng nhập: $e');
    }
  }

  Future<void> setOffline(String username) async {
    try {
      await SupabaseService.client
          .from('taikhoan')
          .update({'is_online': false})
          .eq('username', username);
    } catch (_) {
      // Ignore background error
    }
  }
}
