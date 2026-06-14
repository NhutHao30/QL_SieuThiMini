import 'supabase_service.dart';
import '../models/log_model.dart';

class LogService {
  static Future<void> logAction(String? username, String hanhdong, String chitiet) async {
    if (username == null || username.isEmpty) return;
    
    try {
      await SupabaseService.client.from('nhatky_hethong').insert({
        'username': username,
        'hanhdong': hanhdong,
        'chitiet': chitiet,
      });
    } catch (e) {
      print('Lỗi ghi log: $e');
    }
  }

  Future<List<LogModel>> getLogs() async {
    final response = await SupabaseService.client
        .from('nhatky_hethong')
        .select('*, taikhoan(nhanvien(hoten, chucvu))')
        .order('thoigian', ascending: false)
        .limit(100);
        
    return response.map<LogModel>((item) => LogModel.fromJson(item)).toList();
  }
}
