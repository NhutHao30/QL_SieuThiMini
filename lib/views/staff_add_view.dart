import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:bcrypt/bcrypt.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';

class StaffAddView extends StatefulWidget {
  const StaffAddView({super.key});

  @override
  State<StaffAddView> createState() => _StaffAddViewState();
}

class _StaffAddViewState extends State<StaffAddView> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _hotenController = TextEditingController();
  final _sdtController = TextEditingController();
  final _diachiController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _luongController = TextEditingController();
  
  String? _gioitinh = 'Nam';
  int? _selectedRole;
  List<Map<String, dynamic>> _roles = [];
  List<String> _selectedShifts = [];
  List<Map<String, dynamic>> _shifts = [];
  DateTime? _ngaysinh;
  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final shiftData = await SupabaseService.client.from('calamviec').select();
      final roleData = await SupabaseService.client.from('vaitro').select();
      if (mounted) {
        setState(() {
           _shifts = shiftData;
           _roles = roleData;
           if (_roles.isNotEmpty) {
             _selectedRole = _roles.first['marole'];
           }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _hotenController.dispose();
    _sdtController.dispose();
    _diachiController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _luongController.dispose();
    super.dispose();
  }

  Future<void> _scanCCCD(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String rawText = recognizedText.text;
      
      // Heuristic parsing for Vietnamese CCCD
      // NOTE: Google ML Kit might return lines in unexpected orders.
      // We look for patterns.
      
      RegExp idRegExp = RegExp(r'\b\d{12}\b');
      Match? idMatch = idRegExp.firstMatch(rawText);
      if (idMatch != null) {
        _usernameController.text = idMatch.group(0)!; // Dùng CCCD làm username
        if (_passwordController.text.isEmpty) {
          _passwordController.text = idMatch.group(0)!; // Dùng CCCD làm mật khẩu mặc định
        }
      }

      // Giới tính
      if (rawText.toLowerCase().contains('nam') || rawText.toLowerCase().contains('sex: male')) {
        _gioitinh = 'Nam';
      } else if (rawText.toLowerCase().contains('nữ') || rawText.toLowerCase().contains('nu') || rawText.toLowerCase().contains('sex: female')) {
        _gioitinh = 'Nữ';
      }

      // Ngày sinh: look for dd/MM/yyyy
      RegExp dobRegExp = RegExp(r'\b(\d{2})[-/](\d{2})[-/](\d{4})\b');
      Match? dobMatch = dobRegExp.firstMatch(rawText);
      if (dobMatch != null) {
        try {
          DateTime parsedDate = DateFormat('dd/MM/yyyy').parse('${dobMatch.group(1)}/${dobMatch.group(2)}/${dobMatch.group(3)}');
          if (parsedDate.year <= DateTime.now().year) {
            _ngaysinh = parsedDate;
          }
        } catch (_) {}
      }

      List<String> lines = rawText.split('\n');

      // 1. Tìm Họ và Tên
      int nameLabelIndex = lines.indexWhere((l) => l.toLowerCase().contains('họ và tên') || l.toLowerCase().contains('full name'));
      if (nameLabelIndex != -1 && nameLabelIndex + 1 < lines.length) {
        String nextLine = lines[nameLabelIndex + 1].trim();
        if (nextLine.isNotEmpty && !nextLine.contains(RegExp(r'\d'))) {
          _hotenController.text = nextLine;
        }
      }
      
      // Fallback tìm Họ và tên nếu không thấy nhãn "Full name"
      if (_hotenController.text.isEmpty) {
        for (int i = 0; i < lines.length; i++) {
          String line = lines[i].trim();
          bool isInvalidName = line.contains('CỘNG HÒA') || 
                               line.contains('ĐỘC LẬP') ||
                               line.contains('SOCIALIST') ||
                               line.contains('REPUBLIC') ||
                               line.contains('VIET NAM') ||
                               line.contains('VIỆT') ||
                               line.contains('INDEPENDENCE') ||
                               line.contains('FREEDOM') ||
                               line.contains('HAPPINESS') ||
                               line.contains('CĂN CƯỚC') ||
                               line.contains('IDENTITY') ||
                               line.contains('CITIZEN');
                               
          if (!isInvalidName && line == line.toUpperCase() && !line.contains(RegExp(r'\d')) && line.length > 5) {
             _hotenController.text = line;
             break;
          }
        }
      }

      // 2. Tìm Nơi thường trú
      int addressLabelIndex = lines.indexWhere((l) => l.toLowerCase().contains('thường trú') || l.toLowerCase().contains('residence'));
      int expiryLabelIndex = lines.indexWhere((l) => l.toLowerCase().contains('giá trị đến') || l.toLowerCase().contains('expiry') || l.toLowerCase().contains('date of'));
      
      if (addressLabelIndex != -1) {
         int endIdx = expiryLabelIndex != -1 ? expiryLabelIndex : (addressLabelIndex + 3 < lines.length ? addressLabelIndex + 3 : lines.length);
         List<String> addressParts = [];
         
         // Lấy phần text nằm cùng dòng (nếu có) sau dấu :
         if (lines[addressLabelIndex].contains(':')) {
           String sameLine = lines[addressLabelIndex].split(':').last.trim();
           if (sameLine.isNotEmpty) addressParts.add(sameLine);
         }
         
         for (int i = addressLabelIndex + 1; i < endIdx; i++) {
             String part = lines[i].trim();
             if (part.isNotEmpty) addressParts.add(part);
         }
         _diachiController.text = addressParts.join(', ');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã quét CCCD. Vui lòng kiểm tra lại thông tin!')));
      }
      
      textRecognizer.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi quét: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: const Text('Chụp ảnh CCCD'),
                onTap: () {
                  Navigator.pop(context);
                  _scanCCCD(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _scanCCCD(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _ngaysinh ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _ngaysinh = date);
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ngaysinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày sinh')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final hashedPassword = BCrypt.hashpw(_passwordController.text.trim(), BCrypt.gensalt());
      final username = _usernameController.text.trim();

      // Kiểm tra xem nhân viên đã tồn tại chưa
      final existingNhanVien = await SupabaseService.client.from('nhanvien').select('username').eq('username', username).maybeSingle();
      if (existingNhanVien != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhân viên với mã CCCD này đã tồn tại!')));
          setState(() => _isSaving = false);
        }
        return;
      }

      // Xóa tài khoản bị "treo" (dangling) do các lần thêm lỗi trước đó (nếu có)
      await SupabaseService.client.from('taikhoan').delete().eq('username', username);

      // 1. Lấy mô tả chức vụ từ role đã chọn
      String chucvuText = 'Nhân viên';
      if (_selectedRole != null) {
        final roleObj = _roles.firstWhere((r) => r['marole'] == _selectedRole, orElse: () => {'mota': 'Nhân viên'});
        chucvuText = roleObj['mota'] ?? 'Nhân viên';
        if (chucvuText.length > 10) chucvuText = chucvuText.substring(0, 10);
      }

      double luong = double.tryParse(_luongController.text.trim()) ?? 0;
      if (luong <= 0) {
        if (_selectedRole == 1) luong = 15000000;
        else if (_selectedRole == 2) luong = 7000000;
        else if (_selectedRole == 3) luong = 8000000;
        else if (_selectedRole == 4) luong = 9000000;
        else if (_selectedRole == 5) luong = 12000000;
        else luong = 5000000;
      }

      // 2. Tạo tài khoản trong bảng taikhoan
      await SupabaseService.client.from('taikhoan').insert({
        'username': username,
        'password': hashedPassword,
        'marole': _selectedRole ?? 2,
        'email': _emailController.text.trim(),
      });

      try {
        // 3. Tạo nhân viên trong bảng nhanvien
        await SupabaseService.client.from('nhanvien').insert({
          'username': username,
          'hoten': _hotenController.text.trim(),
          'ngaysinh': DateFormat('yyyy-MM-dd').format(_ngaysinh!),
          'gioitinh': _gioitinh,
          'diachi': _diachiController.text.trim(),
          'sdt': _sdtController.text.trim(),
          'chucvu': chucvuText,
          'luong': luong,
        });

        // 4. Tạo phân công ca làm việc (Nhiều ca)
        if (_selectedShifts.isNotEmpty) {
          final List<Map<String, dynamic>> phancongData = [];
          for (String maca in _selectedShifts) {
            phancongData.add({
              'username': username,
              'maca': maca,
              'ngayphancong': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            });
          }
          await SupabaseService.client.from('phancongca').insert(phancongData);
        }
      } catch (innerError) {
        // ROLLBACK: Nếu tạo nhân viên hoặc phân công ca thất bại, xóa tài khoản vừa tạo để tránh rác dữ liệu
        await SupabaseService.client.from('taikhoan').delete().eq('username', username);
        rethrow; // Ném lỗi ra ngoài để hiển thị SnackBar
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm nhân viên thành công!')));
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
        title: const Text('Thêm Nhân Viên Mới'),
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
                    // Nút quét CCCD
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : () => _showImageSourceActionSheet(context),
                      icon: _isScanning 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(CupertinoIcons.qrcode_viewfinder),
                      label: Text(_isScanning ? 'Đang phân tích OCR...' : 'QUÉT CĂN CƯỚC CÔNG DÂN (OCR)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('THÔNG TIN CÁ NHÂN', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Tên đăng nhập (Mã NV/CCCD) *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hotenController,
                      decoration: const InputDecoration(labelText: 'Họ và tên *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Ngày sinh *', border: OutlineInputBorder()),
                              child: Text(_ngaysinh == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(_ngaysinh!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gioitinh,
                            decoration: const InputDecoration(labelText: 'Giới tính', border: OutlineInputBorder()),
                            items: ['Nam', 'Nữ'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _gioitinh = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sdtController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diachiController,
                      decoration: const InputDecoration(labelText: 'Nơi thường trú', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),
                    const Text('THÔNG TIN CÔNG VIỆC', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
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
                    
                    // Phân công ca (Nhiều ca)
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Phân công ca làm việc (Hôm nay)', border: OutlineInputBorder()),
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
                      decoration: const InputDecoration(labelText: 'Mật khẩu khởi tạo *', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
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
                        child: const Text('LƯU NHÂN VIÊN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
