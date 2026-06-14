import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DashboardViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  double todayRevenue = 0.0;
  int todayOrders = 0;
  int lowStockItems = 0;
  List<Map<String, dynamic>> recentSales = [];

  Future<void> loadDashboardStats() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // 1. Fetch Today's Orders & Revenue
      final ordersResponse = await SupabaseService.client
          .from('hdban')
          .select('tongtien, ngaylap')
          .gte('ngaylap', startOfDay)
          .lte('ngaylap', endOfDay);

      todayOrders = ordersResponse.length;
      todayRevenue = 0.0;
      for (var order in ordersResponse) {
        if (order['tongtien'] != null) {
          todayRevenue += double.tryParse(order['tongtien'].toString()) ?? 0.0;
        }
      }

      // 2. Fetch Low Stock Items (Threshold < 10)
      final lowStockResponse = await SupabaseService.client
          .from('sanpham')
          .select('masp')
          .lt('soluong', 10);

      lowStockItems = lowStockResponse.length;

      // 3. Fetch Recent Sales
      final recentSalesResponse = await SupabaseService.client
          .from('hdban')
          .select('mahd, tongtien, ngaylap, chitiethdban(soluong)')
          .order('ngaylap', ascending: false)
          .limit(3);

      recentSales = List<Map<String, dynamic>>.from(recentSalesResponse);

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
