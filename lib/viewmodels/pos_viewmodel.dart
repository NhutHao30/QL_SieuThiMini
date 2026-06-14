import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/invoice_model.dart';
import '../services/product_service.dart';
import '../services/invoice_service.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/log_service.dart';
import 'user_viewmodel.dart';
import 'package:intl/intl.dart';

class PosViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final InvoiceService _invoiceService = InvoiceService();

  List<ProductModel> products = [];
  List<CartItemModel> cart = [];
  bool isLoading = false;
  bool isCheckingOut = false;
  String? errorMessage;

  double get subtotal => cart.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.08; // 8% tax
  double get total => subtotal + tax;

  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      final allProducts = await _productService.getProducts(page: 1, limit: 100); 
      products = allProducts.where((p) => p.trangthai).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      return loadProducts();
    }
    isLoading = true;
    notifyListeners();
    try {
      final allProducts = await _productService.searchProducts(keyword);
      products = allProducts.where((p) => p.trangthai).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProductByBarcode(String barcode) async {
    try {
       final result = await _productService.searchProducts(barcode);
       if (result.isNotEmpty) {
          final product = result.firstWhere((p) => p.masp == barcode, orElse: () => result.first);
          final error = await addToCart(product);
          if (error != null) {
            errorMessage = error;
            notifyListeners();
            return false;
          }
          return true;
       }
       return false;
    } catch (e) {
       return false;
    }
  }

  Future<String?> addToCart(ProductModel product) async {
    if (!product.trangthai) {
      return 'Sản phẩm "${product.tensp}" đã bị vô hiệu hóa và không thể thêm vào giỏ hàng.';
    }

    try {
      final dbCheck = await _productService.searchProducts(product.masp);
      if (dbCheck.isNotEmpty && !dbCheck.first.trangthai) {
        return 'Sản phẩm "${product.tensp}" vừa bị vô hiệu hóa bởi một nhân viên khác.';
      }
    } catch (_) {}
    
    try {
      final existing = cart.firstWhere((item) => item.product.masp == product.masp);
      existing.quantity++;
    } catch (e) {
      cart.add(CartItemModel(product: product));
    }
    notifyListeners();
    return null;
  }

  void updateQuantity(String masp, int newQuantity) {
    if (newQuantity <= 0) {
      cart.removeWhere((item) => item.product.masp == masp);
    } else {
      try {
        final item = cart.firstWhere((item) => item.product.masp == masp);
        item.quantity = newQuantity;
      } catch (e) {
        // Not found
      }
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Future<String?> checkout({CustomerModel? customer}) async {
    if (cart.isEmpty) return null;

    isCheckingOut = true;
    notifyListeners();

    try {
      // Validate stock
      for (var item in cart) {
        if (item.quantity > item.product.soluong) {
          throw Exception('Sản phẩm "${item.product.tensp}" không đủ số lượng (còn lại: ${item.product.soluong}).');
        }
      }

      // Create a unique ID like HD + timestamp
      final String mahd = 'HD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final invoice = InvoiceModel(
        mahd: mahd,
        ngaylap: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        tongtien: total,
        ghichu: 'Thanh toán tại quầy',
        makh: customer?.makh,
      );

      final details = cart.map((item) => {
        'mahd': mahd,
        'masp': item.product.masp,
        'soluong': item.quantity,
        'dongia': item.product.giaban,
      }).toList();

      await _invoiceService.createInvoice(invoice, details);
      
      // Update customer points
      if (customer != null) {
        int earnedPoints = total ~/ 1000;
        final updatedCustomer = CustomerModel(
          makh: customer.makh,
          hoten: customer.hoten,
          sdt: customer.sdt,
          gioitinh: customer.gioitinh,
          diachi: customer.diachi,
          ngaysinh: customer.ngaysinh,
          loaikh: customer.loaikh,
          diemtichluy: customer.diemtichluy + earnedPoints,
        );
        final customerService = CustomerService();
        await customerService.updateCustomer(updatedCustomer);
      }

      // Record log
      LogService.logAction(
        UserViewModel.currentUserStatic?.username, 
        'TẠO HÓA ĐƠN', 
        'Hóa đơn mã $mahd tổng tiền $total đ',
      );

      clearCart();
      return mahd;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      isCheckingOut = false;
      notifyListeners();
    }
  }
}
