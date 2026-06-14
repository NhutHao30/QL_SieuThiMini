import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<ProductModel> products = [];

  bool isLoading = false;
  String? errorMessage;

  int currentPage = 1;
  final int limit = 10;
  bool hasMore = true;

  Future<void> loadProducts() async {
    try {
      isLoading = true;
      notifyListeners();

      products = await _service.getProducts(
        page: currentPage,
        limit: limit,
      );

      hasMore = products.length == limit;

      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (!hasMore) return;

    currentPage++;
    await loadProducts();
  }

  Future<void> previousPage() async {
    if (currentPage <= 1) return;

    currentPage--;
    await loadProducts();
  }

  Future<void> refreshProducts() async {
    currentPage = 1;
    await loadProducts();
  }

  Future<void> searchProducts(String keyword) async {
    try {
      isLoading = true;
      notifyListeners();

      if (keyword.trim().isEmpty) {
        currentPage = 1;
        await loadProducts();
        return;
      }

      products = await _service.searchProducts(keyword);

      hasMore = false;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String currentCategory = 'Tất cả';
  bool? filterStatus; // null = all, true = active, false = disabled

  List<ProductModel> get filteredProducts {
    return products.where((p) {
      bool matchCategory = currentCategory == 'Tất cả' || p.maloai == currentCategory;
      bool matchStatus = filterStatus == null || p.trangthai == filterStatus;
      return matchCategory && matchStatus;
    }).toList();
  }

  void setCategoryFilter(String category) {
    currentCategory = category;
    notifyListeners();
  }

  void setStatusFilter(bool? status) {
    filterStatus = status;
    notifyListeners();
  }

  Future<void> deleteProduct(String masp) async {
    try {
      await _service.deleteProduct(masp);
      products.removeWhere((p) => p.masp == masp);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> toggleProductStatus(String masp, bool currentStatus) async {
    try {
      await _service.toggleProductStatus(masp, !currentStatus);
      final index = products.indexWhere((p) => p.masp == masp);
      if (index != -1) {
        final old = products[index];
        products[index] = ProductModel(
          masp: old.masp,
          maloai: old.maloai,
          tensp: old.tensp,
          dvt: old.dvt,
          giaban: old.giaban,
          soluong: old.soluong,
          mancc: old.mancc,
          ghichu: old.ghichu,
          trangthai: !currentStatus,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }
}