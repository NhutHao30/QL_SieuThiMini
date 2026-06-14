import '../models/staff_model.dart';
import 'supabase_service.dart';

class StaffService {
  Future<List<StaffModel>> getStaffs() async {
    final response = await SupabaseService.client
        .from('nhanvien')
        .select('username, hoten, chucvu, sdt, taikhoan(email, is_active, is_online), phancongca(maca, ngayphancong)')
        .order('username');

    return response
        .map<StaffModel>((item) => StaffModel.fromJson(item))
        .toList();
  }

  Future<void> toggleStaffStatus(String username, bool newStatus) async {
    await SupabaseService.client
        .from('taikhoan')
        .update({'is_active': newStatus})
        .eq('username', username);
  }

  Future<List<Map<String, dynamic>>> getShifts() async {
    return await SupabaseService.client.from('calamviec').select();
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    return await SupabaseService.client.from('vaitro').select();
  }

  Future<void> deleteStaffCascade(String username) async {
    try {
      // Delete in reverse order of dependencies: phancongca -> nhanvien -> taikhoan
      await SupabaseService.client.from('phancongca').delete().eq('username', username);
      await SupabaseService.client.from('nhanvien').delete().eq('username', username);
      await SupabaseService.client.from('taikhoan').delete().eq('username', username);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('violates foreign key constraint') || errorStr.contains('23503')) {
        throw Exception('Không thể xóa: Nhân viên này đã từng lập hóa đơn bán/nhập. Xóa sẽ làm mất dữ liệu lịch sử!');
      }
      rethrow;
    }
  }
}