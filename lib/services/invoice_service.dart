import '../models/invoice_model.dart';
import '../models/invoice_detail_model.dart';
import 'supabase_service.dart';

class InvoiceService {
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final response = await SupabaseService.client
          .from('hdban')
          .select('mahd, ngaylap, username, ghichu, makh, tongtien, khachhang(hoten), chitiethdban(masp)')
          .order('ngaylap', ascending: false);

      return response
          .map<InvoiceModel>((item) => InvoiceModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách hóa đơn: $e');
    }
  }

  Future<List<InvoiceDetailModel>> getInvoiceDetails(String mahd) async {
    try {
      final response = await SupabaseService.client
          .from('chitiethdban')
          .select('mahd, masp, soluong, dongia, thanhtien, sanpham(tensp)')
          .eq('mahd', mahd);
          
      return response
          .map<InvoiceDetailModel>((item) => InvoiceDetailModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết hóa đơn: $e');
    }
  }

  Future<List<InvoiceModel>> getImportInvoices() async {
    try {
      final response = await SupabaseService.client
          .from('hdnhap')
          .select('mahdnhap, ngaylap, username, ghichu, mancc, nhacungcap(tenncc), chitiethdnhap(masp), congno!inner(sotienphaitra)')
          .order('ngaylap', ascending: false);

      return response
          .map<InvoiceModel>((item) => InvoiceModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách hóa đơn nhập: $e');
    }
  }

  Future<List<InvoiceDetailModel>> getImportInvoiceDetails(String mahdnhap) async {
    try {
      final response = await SupabaseService.client
          .from('chitiethdnhap')
          .select('mahdnhap, masp, soluongtct, soluongtn, dongianhap, thanhtienn, sanpham(tensp)')
          .eq('mahdnhap', mahdnhap);
          
      return response
          .map<InvoiceDetailModel>((item) => InvoiceDetailModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải chi tiết hóa đơn nhập: $e');
    }
  }

  Future<void> createInvoice(InvoiceModel invoice, List<Map<String, dynamic>> details) async {
    try {
      // Sử dụng Stored Procedure (RPC) để đảm bảo Transaction toàn vẹn
      final invoiceData = {
        'mahd': invoice.mahd,
        'ngaylap': invoice.ngaylap,
        'username': invoice.username,
        'ghichu': invoice.ghichu,
        'makh': invoice.makh,
        'tongtien': invoice.tongtien,
      };

      await SupabaseService.client.rpc(
        'checkout_transaction',
        params: {
          'invoice_data': invoiceData,
          'details_data': details,
        },
      );
    } catch (e) {
      throw Exception('Lỗi khi tạo hóa đơn: $e');
    }
  }

  Future<void> deleteInvoice(String mahd) async {
    try {
      // Return stock first
      final details = await SupabaseService.client.from('chitiethdban').select('masp, soluong').eq('mahd', mahd);
      for (var detail in details) {
        final masp = detail['masp'];
        final soluongTra = detail['soluong'] as int;
        final prod = await SupabaseService.client.from('sanpham').select('soluong').eq('masp', masp).single();
        int currentStock = int.tryParse(prod['soluong'].toString()) ?? 0;
        await SupabaseService.client.from('sanpham').update({'soluong': currentStock + soluongTra}).eq('masp', masp);
      }
      
      await SupabaseService.client.from('chitiethdban').delete().eq('mahd', mahd);
      await SupabaseService.client.from('hdban').delete().eq('mahd', mahd);
    } catch (e) {
      throw Exception('Lỗi khi xóa hóa đơn bán: $e');
    }
  }

  Future<void> deleteImportInvoice(String mahdnhap) async {
    try {
      // Return stock (decrease stock for import deletion)
      final details = await SupabaseService.client.from('chitiethdnhap').select('masp, soluongtn').eq('mahdnhap', mahdnhap);
      for (var detail in details) {
        final masp = detail['masp'];
        final soluongTru = detail['soluongtn'] as int;
        final prod = await SupabaseService.client.from('sanpham').select('soluong').eq('masp', masp).single();
        int currentStock = int.tryParse(prod['soluong'].toString()) ?? 0;
        await SupabaseService.client.from('sanpham').update({'soluong': currentStock - soluongTru}).eq('masp', masp);
      }
      
      await SupabaseService.client.from('chitiethdnhap').delete().eq('mahdnhap', mahdnhap);
      await SupabaseService.client.from('congno').delete().eq('mahd_nhap', mahdnhap);
      await SupabaseService.client.from('hdnhap').delete().eq('mahdnhap', mahdnhap);
    } catch (e) {
      throw Exception('Lỗi khi xóa hóa đơn nhập: $e');
    }
  }
}
