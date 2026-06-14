import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/log_service.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';

class ProductAddView extends StatefulWidget {
  const ProductAddView({super.key});

  @override
  State<ProductAddView> createState() => _ProductAddViewState();
}

class _ProductAddViewState extends State<ProductAddView> {
  final _formKey = GlobalKey<FormState>();
  
  final _tenspController = TextEditingController();
  final _dvtController = TextEditingController(text: 'Cái');
  final _giabanController = TextEditingController();
  final _maloaiController = TextEditingController(text: 'L01');
  final _manccController = TextEditingController(text: 'NCC01');
  final _ghichuController = TextEditingController();

  final _gianhapController = TextEditingController();
  final _slChungTuController = TextEditingController();
  final _slThucNhapController = TextEditingController();
  final _daThanhToanController = TextEditingController();

  bool _isSaving = false;
  String? _generatedMasp;

  double get _giaNhap => double.tryParse(_gianhapController.text.trim()) ?? 0;
  int get _slThucNhap => int.tryParse(_slThucNhapController.text.trim()) ?? 0;
  double get _daThanhToan => double.tryParse(_daThanhToanController.text.trim()) ?? 0;

  double get _tongTienNhap => _giaNhap * _slThucNhap;
  double get _congNo => _tongTienNhap - _daThanhToan;
  String get _trangThaiCongNo => _congNo <= 0 ? 'Đã thanh toán' : 'Cần thanh toán ${NumberFormat('#,###').format(_congNo)} đ';

  @override
  void initState() {
    super.initState();
    _gianhapController.addListener(_calculateValues);
    _slThucNhapController.addListener(_calculateValues);
    _daThanhToanController.addListener(_calculateValues);
  }

  void _calculateValues() {
    setState(() {});
  }

  @override
  void dispose() {
    _tenspController.dispose();
    _dvtController.dispose();
    _giabanController.dispose();
    _maloaiController.dispose();
    _manccController.dispose();
    _ghichuController.dispose();
    _gianhapController.dispose();
    _slChungTuController.dispose();
    _slThucNhapController.dispose();
    _daThanhToanController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _generatedMasp = null;
    });

    try {
      final user = context.read<UserViewModel>().currentUser;
      final manv = user?.username ?? 'admin';
      final timestamp = DateTime.now();

      // Auto-generate IDs to fit VARCHAR(10) or VARCHAR(20)
      final String autoMasp = 'SP${DateFormat('MMddHHmm').format(timestamp)}'; // 10 chars
      final String mahdn = 'HN${DateFormat('MMddHHmm').format(timestamp)}'; // 10 chars
      final String macn = 'CN${DateFormat('yyMMddHHmmss').format(timestamp)}'; // 14 chars

      double giaban = double.tryParse(_giabanController.text.trim()) ?? 0;
      int slChungTu = int.tryParse(_slChungTuController.text.trim()) ?? 0;

      if (giaban < 0 || _slThucNhap < 0 || _giaNhap < 0 || _daThanhToan < 0 || slChungTu < 0) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Các giá trị số tiền hoặc số lượng không được âm!')),
          );
        }
        return;
      }

      if (slChungTu < _slThucNhap) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Số lượng thực nhập không được lớn hơn số lượng theo chứng từ!')),
          );
        }
        return;
      }

      if (giaban < _giaNhap) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Giá bán không được thấp hơn giá nhập!')),
          );
        }
        return;
      }

      final trangthai = _congNo <= 0 ? 'Đã thanh toán' : 'Chưa thanh toán';

      // 1. Insert sanpham
      await SupabaseService.client.from('sanpham').insert({
        'masp': autoMasp,
        'tensp': _tenspController.text.trim(),
        'dvt': _dvtController.text.trim(),
        'giaban': giaban,
        'soluong': _slThucNhap,
        'maloai': _maloaiController.text.trim(),
        'mancc': _manccController.text.trim(),
        'ghichu': _ghichuController.text.trim(),
      });

      // 2. Insert hdnhap
      await SupabaseService.client.from('hdnhap').insert({
        'mahdnhap': mahdn,
        'ngaylap': timestamp.toIso8601String(),
        'username': manv,
        'mancc': _manccController.text.trim(),
        'ghichu': _ghichuController.text.trim(),
      });

      // 3. Insert chitiethdnhap (without GENERATED column 'thanhtienn')
      await SupabaseService.client.from('chitiethdnhap').insert({
        'mahdnhap': mahdn,
        'masp': autoMasp,
        'soluongtct': slChungTu,
        'soluongtn': _slThucNhap,
        'dongianhap': _giaNhap,
      });

      // 4. Insert congno (without GENERATED column 'conlai')
      await SupabaseService.client.from('congno').insert({
        'macongno': macn,
        'mahd_nhap': mahdn,
        'loaicongno': 'Phải trả',
        'mancc': _manccController.text.trim(),
        'ngayphatsinh': DateFormat('yyyy-MM-dd').format(timestamp),
        'sotienphaitra': _tongTienNhap,
        'dathanhtoan': _daThanhToan,
        'trangthai': trangthai,
      });

      // 5. Record to nhatky_hethong
      await LogService.logAction(
        manv, 
        'NHẬP HÀNG MỚI', 
        'Mã HD: $mahdn - Tên SP: ${_tenspController.text.trim()} - SL: $_slThucNhap - Tổng: ${NumberFormat('#,###').format(_tongTienNhap)} đ'
      );

      // Refresh product list in ProductViewModel if needed
      if (mounted) {
        context.read<ProductViewModel>().loadProducts();
      }

      setState(() {
        _generatedMasp = autoMasp;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhập hàng mới thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _tenspController.clear();
    _giabanController.clear();
    _ghichuController.clear();
    _gianhapController.clear();
    _slChungTuController.clear();
    _slThucNhapController.clear();
    _daThanhToanController.clear();
    setState(() {
      _generatedMasp = null;
    });
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
          'Nhập Hàng Mới',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _generatedMasp == null 
            ? _buildForm() 
            : _buildSuccessResult(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin sản phẩm', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField('Tên sản phẩm', _tenspController, true, TextInputType.text),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Đơn vị tính', _dvtController, true, TextInputType.text)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Mã loại', _maloaiController, true, TextInputType.text)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Mã nhà cung cấp', _manccController, true, TextInputType.text),
                const SizedBox(height: 16),
                _buildTextField('Giá bán dự kiến', _giabanController, true, TextInputType.number),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chi tiết nhập kho', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField('Giá nhập (đ)', _gianhapController, true, TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('SL chứng từ', _slChungTuController, true, TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('SL thực nhập', _slThucNhapController, true, TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thanh toán & Công nợ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildReadOnlyField('Tổng tiền nhập', '${NumberFormat('#,###').format(_tongTienNhap)} đ', isBold: true, color: AppTheme.primaryDark),
                const SizedBox(height: 16),
                _buildTextField('Số tiền đã thanh toán (đ)', _daThanhToanController, true, TextInputType.number),
                const SizedBox(height: 16),
                _buildReadOnlyField('Trạng thái công nợ', _trangThaiCongNo, color: _congNo <= 0 ? AppTheme.success : Colors.red, isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField('Ghi chú thêm', _ghichuController, false, TextInputType.text),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Lưu Phiếu Nhập Hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {Color? color, bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildSuccessResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.check_mark_circled_solid, color: AppTheme.success, size: 80),
        const SizedBox(height: 16),
        Text('Nhập hàng thành công!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text('Mã Sản Phẩm', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text(_generatedMasp!, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              // QR Code representation
              QrImageView(
                data: _generatedMasp!,
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              const Text('Quét mã QR này bằng máy quét ở màn hình POS để thêm vào giỏ hàng.', textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Quay lại danh sách'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _resetForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Nhập lô khác'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool required, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          validator: required ? (value) {
            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $label';
            return null;
          } : null,
          decoration: InputDecoration(
            hintText: 'Nhập $label...',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
      ],
    );
  }
}
