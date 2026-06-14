import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/invoice_detail_model.dart';
import '../services/invoice_service.dart';

enum InvoiceFilterType { all, today, thisWeek, thisMonth }
enum InvoiceViewType { sales, import }

class InvoiceViewModel extends ChangeNotifier {
  final InvoiceService _service = InvoiceService();

  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> filteredInvoices = [];

  bool isLoading = false;
  String? errorMessage;

  String _searchQuery = '';
  InvoiceFilterType _currentFilter = InvoiceFilterType.all;
  InvoiceViewType _viewType = InvoiceViewType.sales;

  InvoiceFilterType get currentFilter => _currentFilter;
  InvoiceViewType get viewType => _viewType;

  Future<void> loadInvoices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_viewType == InvoiceViewType.sales) {
        _allInvoices = await _service.getInvoices();
      } else {
        _allInvoices = await _service.getImportInvoices();
      }
      _applyFilters();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setViewType(InvoiceViewType type) {
    if (_viewType != type) {
      _viewType = type;
      loadInvoices();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void setFilterType(InvoiceFilterType type) {
    _currentFilter = type;
    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    filteredInvoices = _allInvoices.where((inv) {
      // 1. Text Search
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = inv.mahd.toLowerCase().contains(_searchQuery) ||
            inv.customerName.toLowerCase().contains(_searchQuery);
      }

      // 2. Date Filter
      bool matchesDate = true;
      if (_currentFilter != InvoiceFilterType.all) {
        try {
          final invDate = DateTime.parse(inv.ngaylap);
          if (_currentFilter == InvoiceFilterType.today) {
            matchesDate = invDate.year == now.year &&
                invDate.month == now.month &&
                invDate.day == now.day;
          } else if (_currentFilter == InvoiceFilterType.thisWeek) {
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            matchesDate = invDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                invDate.isBefore(now.add(const Duration(days: 1)));
          } else if (_currentFilter == InvoiceFilterType.thisMonth) {
            matchesDate = invDate.year == now.year && invDate.month == now.month;
          }
        } catch (_) {}
      }

      return matchesSearch && matchesDate;
    }).toList();
    
    notifyListeners();
  }

  Future<List<InvoiceDetailModel>> getInvoiceDetails(String mahd, bool isImport) async {
    try {
      if (isImport) {
        return await _service.getImportInvoiceDetails(mahd);
      }
      return await _service.getInvoiceDetails(mahd);
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  Future<void> deleteInvoice(String mahd, bool isImport) async {
    try {
      if (isImport) {
        await _service.deleteImportInvoice(mahd);
      } else {
        await _service.deleteInvoice(mahd);
      }
      loadInvoices(); // Reload
    } catch (e) {
      throw Exception('Lỗi xóa hóa đơn: $e');
    }
  }
}
