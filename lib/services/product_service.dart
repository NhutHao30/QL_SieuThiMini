import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  Future<List<ProductModel>> getProducts({
    required int page,
    required int limit,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await SupabaseService.client
          .from('sanpham')
          .select('*')
          .order('masp', ascending: true)
          .range(from, to);

      return response
          .map<ProductModel>((item) => ProductModel.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Supabase lỗi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi khi tải sản phẩm: $e');
    }
  }

  Future<List<ProductModel>> searchProducts(String keyword) async {
    try {
      final key = keyword.trim();

      final response = await SupabaseService.client
          .from('sanpham')
          .select('*')
          .or('masp.ilike.%$key%,tensp.ilike.%$key%')
          .order('masp', ascending: true)
          .limit(50);

      return response
          .map<ProductModel>((item) => ProductModel.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Supabase lỗi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm sản phẩm: $e');
    }
  }

  Future<void> deleteProduct(String masp) async {
    try {
      await SupabaseService.client.from('sanpham').delete().eq('masp', masp);
    } on PostgrestException catch (e) {
      if (e.code == '23503') { // Foreign key violation
        // Delete related records in invoice details first (Cascade Delete)
        await SupabaseService.client.from('chitiethdban').delete().eq('masp', masp);
        await SupabaseService.client.from('chitiethdnhap').delete().eq('masp', masp);
        
        // Then try deleting the product again
        await SupabaseService.client.from('sanpham').delete().eq('masp', masp);
      } else {
        throw Exception('Lỗi xóa sản phẩm từ Database: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định khi xóa sản phẩm: $e');
    }
  }

  Future<void> toggleProductStatus(String masp, bool newStatus) async {
    try {
      await SupabaseService.client.from('sanpham').update({'trangthai': newStatus}).eq('masp', masp);
    } catch (e) {
      throw Exception('Lỗi khi thay đổi trạng thái sản phẩm: $e');
    }
  }
}