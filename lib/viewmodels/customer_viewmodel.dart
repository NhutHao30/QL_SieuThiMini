import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/log_service.dart';
import 'user_viewmodel.dart';

class CustomerViewModel extends ChangeNotifier {
  final CustomerService _service = CustomerService();

  List<CustomerModel> customers = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadCustomers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      customers = await _service.getCustomers();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchCustomers(String keyword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (keyword.trim().isEmpty) {
        await loadCustomers();
        return;
      }
      customers = await _service.searchCustomers(keyword);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.addCustomer(customer);
      LogService.logAction(
        UserViewModel.currentUserStatic?.username,
        'THÊM KHÁCH HÀNG',
        'Đã thêm khách hàng mới: ${customer.hoten} - Số ĐT: ${customer.sdt}',
      );
      await loadCustomers(); // Reload list after adding
    } catch (e) {
      errorMessage = e.toString();
      throw e; // Rethrow so UI can show error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.updateCustomer(customer);
      LogService.logAction(
        UserViewModel.currentUserStatic?.username,
        'CẬP NHẬT KHÁCH HÀNG',
        'Đã cập nhật thông tin khách hàng: ${customer.hoten}',
      );
      await loadCustomers();
    } catch (e) {
      errorMessage = e.toString();
      throw e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(CustomerModel customer) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteCustomer(customer);
      LogService.logAction(
        UserViewModel.currentUserStatic?.username,
        'XÓA KHÁCH HÀNG',
        'Đã xóa khách hàng: ${customer.hoten}',
      );
      await loadCustomers();
    } catch (e) {
      errorMessage = e.toString();
      throw e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
