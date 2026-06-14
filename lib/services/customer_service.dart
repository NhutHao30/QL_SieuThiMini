import '../models/customer_model.dart';
import 'supabase_service.dart';

class CustomerService {
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final response = await SupabaseService.client
          .from('khachhang')
          .select()
          .order('makh', ascending: true);

      return response
          .map<CustomerModel>((item) => CustomerModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách khách hàng: $e');
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await SupabaseService.client.from('khachhang').insert({
        'makh': customer.makh,
        'loaikh': customer.loaikh,
        'hoten': customer.hoten,
        'ngaysinh': customer.ngaysinh,
        'sdt': customer.sdt,
        'gioitinh': customer.gioitinh,
        'diachi': customer.diachi,
        'diemtichluy': customer.diemtichluy,
      });
    } catch (e) {
      throw Exception('Lỗi khi thêm khách hàng: $e');
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await SupabaseService.client
          .from('khachhang')
          .update({
            'loaikh': customer.loaikh,
            'hoten': customer.hoten,
            'ngaysinh': customer.ngaysinh,
            'sdt': customer.sdt,
            'gioitinh': customer.gioitinh,
            'diachi': customer.diachi,
            'diemtichluy': customer.diemtichluy,
          })
          .eq('makh', customer.makh);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật khách hàng: $e');
    }
  }

  Future<void> deleteCustomer(CustomerModel customer) async {
    try {
      final makh = customer.makh;

      // 1. Kiểm tra công nợ đối với khách hàng đại lý
      if (customer.loaikh == 'DaiLy') {
        final congnoList = await SupabaseService.client
            .from('congno')
            .select('conlai')
            .eq('makh', makh);
        
        double totalDebt = 0;
        for (var cn in congnoList) {
          totalDebt += double.parse(cn['conlai'].toString());
        }
        
        if (totalDebt > 0) {
          throw Exception('Không thể xóa! Khách hàng đại lý này còn nợ ${totalDebt.toStringAsFixed(0)}đ.');
        }
      }

      // 2. Tìm tất cả mã công nợ của khách hàng này
      final congnoRecords = await SupabaseService.client
          .from('congno')
          .select('macongno')
          .eq('makh', makh);
          
      final List<String> congnoIds = congnoRecords.map<String>((c) => c['macongno'] as String).toList();

      // 3. Xóa tất cả phiếu thanh toán liên kết với các công nợ này
      if (congnoIds.isNotEmpty) {
        await SupabaseService.client
            .from('phieuthanhtoan')
            .delete()
            .inFilter('macongno', congnoIds);
      }

      // 4. Xóa tất cả công nợ của khách hàng
      await SupabaseService.client
          .from('congno')
          .delete()
          .eq('makh', makh);

      // 3. Tìm tất cả các hóa đơn của khách hàng này
      final invoices = await SupabaseService.client
          .from('hdban')
          .select('mahd')
          .eq('makh', makh);

      final List<String> invoiceIds = invoices.map<String>((i) => i['mahd'] as String).toList();

      // 4. Xóa chi tiết hóa đơn của các hóa đơn đó
      if (invoiceIds.isNotEmpty) {
        await SupabaseService.client
            .from('chitiethdban')
            .delete()
            .inFilter('mahd', invoiceIds);
            
        // 5. Xóa các hóa đơn đó
        await SupabaseService.client
            .from('hdban')
            .delete()
            .eq('makh', makh);
      }

      // 6. Cuối cùng, xóa khách hàng
      await SupabaseService.client
          .from('khachhang')
          .delete()
          .eq('makh', makh);
    } catch (e) {
      throw Exception('$e'); // Thay vì throw bọc chuỗi thì ném thẳng ra để giữ nguyên message
    }
  }

  Future<List<CustomerModel>> searchCustomers(String keyword) async {
    try {
      final response = await SupabaseService.client
          .from('khachhang')
          .select()
          .or(
            'makh.ilike.%$keyword%,hoten.ilike.%$keyword%,sdt.ilike.%$keyword%',
          )
          .order('makh', ascending: true);

      return response
          .map<CustomerModel>((item) => CustomerModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm khách hàng: $e');
    }
  }
}