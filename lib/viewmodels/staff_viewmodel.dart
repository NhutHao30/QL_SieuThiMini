import 'package:flutter/material.dart';
import '../models/staff_model.dart';
import '../services/staff_service.dart';

class StaffViewModel extends ChangeNotifier {
  final StaffService _service = StaffService();

  List<StaffModel> staffs = [];
  List<Map<String, dynamic>> availableRoles = [];
  List<Map<String, dynamic>> availableShifts = [];

  List<StaffModel> get filteredStaffs {
    return staffs.where((staff) {
      final matchSearch = _searchQuery.isEmpty || 
          staff.hoten.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          staff.username.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchRole = _filterRole == null || staff.chucvu == _filterRole;
      final matchShift = _filterShift == null || staff.shifts.contains(_filterShift);
      return matchSearch && matchRole && matchShift;
    }).toList();
  }

  bool isLoading = false;
  String _searchQuery = '';
  String? _filterRole;
  String? _filterShift;
  String? errorMessage;

  Future<void> loadStaffs() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      staffs = await _service.getStaffs();
      availableRoles = await _service.getRoles();
      availableShifts = await _service.getShifts();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterRole(String? role) {
    _filterRole = role;
    notifyListeners();
  }

  void setFilterShift(String? shift) {
    _filterShift = shift;
    notifyListeners();
  }

  Future<void> toggleStatus(String username, bool currentStatus) async {
    try {
      await _service.toggleStaffStatus(username, !currentStatus);
      await loadStaffs();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteStaff(String username) async {
    try {
      // Vì ràng buộc khóa ngoại (foreign key constraint) từ bảng phancongca sang nhanvien
      // Cần xóa phancongca trước, nhưng để an toàn và gọn thì ta xóa tài khoản vì tài khoản reference nhanvien hay ngược lại?
      // Lược đồ: nhanvien.username REFERENCES taikhoan.username
      // phancongca.username REFERENCES nhanvien.username
      // Nên xóa theo thứ tự: phancongca -> nhanvien -> taikhoan
      await _service.deleteStaffCascade(username);
      staffs.removeWhere((s) => s.username == username);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }
}