import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/log_service.dart';

class UserViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  static UserModel? currentUserStatic;
  
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _currentUser != null;

  // Role permissions
  bool get isAdmin => _currentUser?.marole == 1; // Admin
  bool get isStaff => _currentUser?.marole == 2; // Nhan vien
  bool get isCashier => _currentUser?.marole == 3; // Thu ngan
  bool get isWarehouse => _currentUser?.marole == 4; // Quan kho
  bool get isManager => _currentUser?.marole == 5; // Quan ly

  // Permission checks
  bool get canSell => isAdmin || isCashier || isManager;
  bool get canManageInventory => isAdmin || isWarehouse || isManager;
  bool get canManageStaff => isAdmin || isManager;
  
  // Nhan vien (Role 2) can view invoices, products, customers.
  bool get canViewOnly => isStaff || isCashier || isWarehouse || isManager || isAdmin;

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(identifier, password);
      currentUserStatic = _currentUser;
      
      // Ghi log đăng nhập
      LogService.logAction(_currentUser?.username, 'ĐĂNG NHẬP', 'Đăng nhập vào hệ thống');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      LogService.logAction(_currentUser!.username, 'ĐĂNG XUẤT', 'Đăng xuất khỏi hệ thống');
      // Set offline asynchronously
      await _authService.setOffline(_currentUser!.username);
    }
    _currentUser = null;
    currentUserStatic = null;
    notifyListeners();
  }
}
