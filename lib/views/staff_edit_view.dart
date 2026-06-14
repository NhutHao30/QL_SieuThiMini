import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../models/staff_model.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:intl/intl.dart';

class StaffEditView extends StatefulWidget {
  final StaffModel staff;
  const StaffEditView({super.key, required this.staff});

  @override
  State<StaffEditView> createState() => _StaffEditViewState();
}

class _StaffEditViewState extends State<StaffEditView> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _hotenController;
  late final TextEditingController _sdtController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _luongController = TextEditingController();
  
  int? _selectedRole;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _shifts = [];
  List<String> _selectedShifts = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hotenController = TextEditingController(text: widget.staff.hoten);
    _sdtController = TextEditingController(text: widget.staff.sdt);
    _emailController = TextEditingController(text: widget.staff.email);
    
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final roleData = await SupabaseService.client.from('vaitro').select();
      if (mounted) setState(() => _roles = roleData);
    } catch (_) {}

    try {
      final shiftData = await SupabaseService.client.from('calamviec').select();
      if (mounted) setState(() => _shifts = shiftData);
    } catch (_) {}

    try {
      final resLuong = await SupabaseService.client.from('nhanvien').select('luong').eq('username', widget.staff.username).single();
      if (mounted && resLuong != null && resLuong['luong'] != null) {
        double val = double.parse(resLuong['luong'].toString());
        setState(() {
          _luongController.text = val == val.toInt() ? val.toInt().toString() : val.toString();
        });
      }
    } catch (_) {}

    try {
      final resTaiKhoan = await SupabaseService.client.from('taikhoan').select('marole').eq('username', widget.staff.username).single();
      if (mounted && resTaiKhoan != null) {
        setState(() {
          _selectedRole = resTaiKhoan['marole'] as int?;
        });
      }
    } catch (_) {}

    try {
      final resShifts = await SupabaseService.client.from('phancongca').select('maca').eq('username', widget.staff.username);
      if (mounted) {
        setState(() {
          _selectedShifts = resShifts.map((e) => e['maca'].toString()).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _hotenController.dispose();
    _sdtController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _luongController.dispose();
    super.dispose();
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String chucvuText = 'Nhân viên';
      if (_selectedRole != null) {
        final roleObj = _roles.firstWhere((r) => r['marole'] == _selectedRole, orElse: () => {'mota': 'Nhân viên'});
        chucvuText = roleObj['mota'] ?? 'Nhân viên';
        if (chucvuText.length > 10) chucvuText = chucvuText.substring(0, 10);
      }

      // 1. Cập nhật nhanvien
      await SupabaseService.client.from('nhanvien').update({
        'hoten': _hotenController.text.trim(),
        'sdt': _sdtController.text.trim(),
        'chucvu': chucvuText,
        'luong': double.tryParse(_luongController.text.trim()) ?? 0,
      }).eq('username', widget.staff.username);

      // 2. Cập nhật taikhoan
      final taikhoanUpdate = <String, dynamic>{
        'marole': _selectedRole ?? 2,
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.trim().isNotEmpty) {
        taikhoanUpdate['password'] = BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt());
      }

      await SupabaseService.client.from('taikhoan').update(taikhoanUpdate).eq('username', widget.staff.username);

      // 3. Cập nhật phân công ca (Xóa cũ, Thêm mới)
      await SupabaseService.client.from('phancongca').delete().eq('username', widget.staff.username);
      
      if (_selectedShifts.isNotEmpty) {
        final List<Map<String, dynamic>> phancongData = [];
        final nowStr = DateTime.now().toIso8601String().split('T').first;
        for (String maca in _selectedShifts) {
          phancongData.add({
            'username': widget.staff.username,
            'maca': maca,
            'ngayphancong': nowStr,
          });
        }
        await SupabaseService.client.from('phancongca').insert(phancongData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật nhân viên thành công!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập Nhật Nhân Viên'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('THÔNG TIN CÔNG VIỆC', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hotenController,
                      decoration: const InputDecoration(labelText: 'Họ và tên *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sdtController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Chức vụ', border: OutlineInputBorder()),
                      items: _roles.map((r) => DropdownMenuItem<int>(
                        value: r['marole'] as int,
                        child: Text(r['mota'].toString()),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedRole = v),
                      validator: (v) => v == null ? 'Vui lòng chọn chức vụ' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _luongController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Mức lương cơ bản', border: OutlineInputBorder(), suffixText: 'đ'),
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          if (double.tryParse(v) == null || double.parse(v) < 0) {
                            return 'Lương không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phân công ca
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Phân công ca làm việc', border: OutlineInputBorder()),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _shifts.map((s) {
                          final maca = s['maca'].toString();
                          final isSelected = _selectedShifts.contains(maca);
                          return FilterChip(
                            label: Text(s['tenca']),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedShifts.add(maca);
                                } else {
                                  _selectedShifts.remove(maca);
                                }
                              });
                            },
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                            checkmarkColor: AppTheme.primary,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('THÔNG TIN TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty || !v.contains('@') ? 'Email không hợp lệ' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Đổi mật khẩu (để trống nếu không đổi)', border: OutlineInputBorder()),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveStaff,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CẬP NHẬT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
