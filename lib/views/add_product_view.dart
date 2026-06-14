import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/log_service.dart';
import '../viewmodels/user_viewmodel.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final TextEditingController _tenspCtrl = TextEditingController();
  final TextEditingController _maspCtrl = TextEditingController();
  final TextEditingController _maloaiCtrl = TextEditingController(text: 'L01');
  final TextEditingController _dvtCtrl = TextEditingController(text: 'Cái');
  final TextEditingController _giabanCtrl = TextEditingController();
  final TextEditingController _gianhapCtrl = TextEditingController();
  
  final TextEditingController _slChungTuCtrl = TextEditingController();
  final TextEditingController _slThucNhapCtrl = TextEditingController();
  final TextEditingController _daThanhToanCtrl = TextEditingController();
  final TextEditingController _nhaCungCapCtrl = TextEditingController(text: 'NCC01');

  double get _giaNhap => double.tryParse(_gianhapCtrl.text) ?? 0;
  int get _slThucNhap => int.tryParse(_slThucNhapCtrl.text) ?? 0;
  double get _daThanhToan => double.tryParse(_daThanhToanCtrl.text) ?? 0;

  double get _tongTienNhap => _giaNhap * _slThucNhap;
  double get _congNo => _tongTienNhap - _daThanhToan;
  String get _trangThaiCongNo => _congNo <= 0 ? 'Đã thanh toán' : 'Cần thanh toán ${NumberFormat('#,###').format(_congNo)} đ';

  bool _isLoading = false;

  void _calculateValues() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _gianhapCtrl.addListener(_calculateValues);
    _slThucNhapCtrl.addListener(_calculateValues);
    _daThanhToanCtrl.addListener(_calculateValues);
  }

  @override
  void dispose() {
    _tenspCtrl.dispose();
    _maspCtrl.dispose();
    _maloaiCtrl.dispose();
    _dvtCtrl.dispose();
    _giabanCtrl.dispose();
    _gianhapCtrl.dispose();
    _slChungTuCtrl.dispose();
    _slThucNhapCtrl.dispose();
    _daThanhToanCtrl.dispose();
    _nhaCungCapCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveImport() async {
    if (_tenspCtrl.text.isEmpty || _maspCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên và mã sản phẩm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<UserViewModel>().currentUser;
      final manv = user?.username ?? 'admin';
      final timestamp = DateTime.now();
      final mahdn = 'HDN${DateFormat('yyMMddHHmmss').format(timestamp)}';

      final giaban = double.tryParse(_giabanCtrl.text) ?? 0;
      final gianhap = double.tryParse(_gianhapCtrl.text) ?? 0;
      final slChungTu = int.tryParse(_slChungTuCtrl.text) ?? 0;
      final slThucNhap = int.tryParse(_slThucNhapCtrl.text) ?? 0;
      final daThanhToan = double.tryParse(_daThanhToanCtrl.text) ?? 0;
      final tongTien = gianhap * slThucNhap;
      final congno = tongTien - daThanhToan;
      final trangthai = congno <= 0 ? 'Đã thanh toán' : 'Cần thanh toán';

      // 1. Create Product (or update if exists - here we assume create)
      await SupabaseService.client.from('sanpham').upsert({
        'masp': _maspCtrl.text,
        'tensp': _tenspCtrl.text,
        'maloai': _maloaiCtrl.text,
        'dvt': _dvtCtrl.text,
        'giaban': giaban,
        'soluong': slThucNhap, // initial stock
        'mancc': _nhaCungCapCtrl.text,
      });

      // 2. Create hoadonnhap
      await SupabaseService.client.from('hoadonnhap').insert({
        'mahdn': mahdn,
        'ngaynhap': timestamp.toIso8601String(),
        'manv': manv,
        'tongtiennhap': tongTien,
        'sotien_dathanhtoan': daThanhToan,
        'congno_nhaphang': congno,
        'trangthai_congno': trangthai,
      });

      // 3. Create chitietnhap
      await SupabaseService.client.from('chitietnhap').insert({
        'mahdn': mahdn,
        'masp': _maspCtrl.text,
        'gianhap': gianhap,
        'sl_chungtu': slChungTu,
        'sl_thucnhap': slThucNhap,
        'thanhtien': tongTien,
      });

      // 4. Log Action
      await LogService.logAction(
        manv, 
        'NHẬP HÀNG MỚI', 
        'Mã hóa đơn: $mahdn - Sản phẩm: ${_tenspCtrl.text} - SL: $slThucNhap - Tổng tiền: ${NumberFormat('#,###').format(tongTien)} đ'
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập hàng thành công!')),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhập hàng mới',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSection(context, [
              Text('Thông tin sản phẩm', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildInputGroup(context, 'Tên sản phẩm', 'Nhập tên sản phẩm...', controller: _tenspCtrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputGroup(context, 'Mã sản phẩm / Barcode', '893...', controller: _maspCtrl, suffixIcon: CupertinoIcons.barcode_viewfinder)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputGroup(context, 'Mã loại', 'L01', controller: _maloaiCtrl)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputGroup(context, 'Đơn vị tính', 'Cái', controller: _dvtCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputGroup(context, 'Giá bán dự kiến', '0', controller: _giabanCtrl)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _buildFormSection(context, [
              Text('Chi tiết nhập hàng', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputGroup(context, 'Giá nhập', '0', controller: _gianhapCtrl, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputGroup(context, 'Mã nhà cung cấp', 'NCC01', controller: _nhaCungCapCtrl)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInputGroup(context, 'SL theo chứng từ', '0', controller: _slChungTuCtrl, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputGroup(context, 'SL thực nhập', '0', controller: _slThucNhapCtrl, isNumber: true)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _buildFormSection(context, [
              Text('Thanh toán & Công nợ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildReadOnlyField(context, 'Tổng tiền nhập', '${NumberFormat('#,###').format(_tongTienNhap)} đ', isBold: true, color: AppTheme.primaryDark),
              const SizedBox(height: 16),
              _buildInputGroup(context, 'Số tiền đã thanh toán', '0', controller: _daThanhToanCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildReadOnlyField(context, 'Trạng thái công nợ', _trangThaiCongNo, 
                color: _congNo <= 0 ? AppTheme.success : AppTheme.warning, 
                isBold: true),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveImport,
                icon: const Icon(CupertinoIcons.floppy_disk),
                label: const Text('Lưu thông tin nhập hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputGroup(BuildContext context, String label, String hint, {IconData? suffixIcon, TextEditingController? controller, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon, color: AppTheme.textSecondary)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value, {Color? color, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color ?? AppTheme.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
