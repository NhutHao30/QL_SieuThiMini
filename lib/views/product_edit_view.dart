import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../viewmodels/product_viewmodel.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/log_service.dart';
import '../viewmodels/user_viewmodel.dart';

class ProductEditView extends StatefulWidget {
  final ProductModel product;

  const ProductEditView({super.key, required this.product});

  @override
  State<ProductEditView> createState() => _ProductEditViewState();
}

class _ProductEditViewState extends State<ProductEditView> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _tenspController;
  late TextEditingController _dvtController;
  late TextEditingController _giabanController;
  late TextEditingController _maloaiController;
  late TextEditingController _manccController;
  late TextEditingController _ghichuController;
  late TextEditingController _soluongController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tenspController = TextEditingController(text: widget.product.tensp);
    _dvtController = TextEditingController(text: widget.product.dvt);
    _giabanController = TextEditingController(text: widget.product.giaban.toStringAsFixed(0));
    _maloaiController = TextEditingController(text: widget.product.maloai);
    _manccController = TextEditingController(text: widget.product.mancc);
    _ghichuController = TextEditingController(text: widget.product.ghichu ?? '');
    _soluongController = TextEditingController(text: widget.product.soluong.toString());
  }

  @override
  void dispose() {
    _tenspController.dispose();
    _dvtController.dispose();
    _giabanController.dispose();
    _maloaiController.dispose();
    _manccController.dispose();
    _ghichuController.dispose();
    _soluongController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      double giaban = double.tryParse(_giabanController.text.trim()) ?? 0;
      int soluong = int.tryParse(_soluongController.text.trim()) ?? 0;

      if (giaban < 0 || soluong < 0) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: Giá bán và số lượng không được âm!')),
          );
        }
        return;
      }

      await SupabaseService.client.from('sanpham').update({
        'tensp': _tenspController.text.trim(),
        'dvt': _dvtController.text.trim(),
        'giaban': giaban,
        'soluong': soluong,
        'maloai': _maloaiController.text.trim(),
        'mancc': _manccController.text.trim(),
        'ghichu': _ghichuController.text.trim(),
      }).eq('masp', widget.product.masp);

      // Ghi log
      if (mounted) {
        final user = context.read<UserViewModel>().currentUser;
        if (user != null) {
          await LogService.logAction(user.username, 'Sửa sản phẩm', 'Đã sửa thông tin sản phẩm mã ${widget.product.masp}');
        }
        
        await context.read<ProductViewModel>().refreshProducts();
        if (mounted) {
          Navigator.pop(context, true); // Pop the edit screen
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật sản phẩm thành công!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Sản Phẩm'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Thông tin cơ bản'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: widget.product.masp,
                            decoration: const InputDecoration(
                              labelText: 'Mã Sản Phẩm (Không thể sửa)',
                              border: OutlineInputBorder(),
                              fillColor: Color(0xFFF3F4F6),
                              filled: true,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tenspController,
                            decoration: const InputDecoration(labelText: 'Tên Sản Phẩm *', border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên SP' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _maloaiController,
                                  decoration: const InputDecoration(labelText: 'Mã Loại *', border: OutlineInputBorder()),
                                  validator: (v) => v!.isEmpty ? 'Nhập mã loại' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _manccController,
                                  decoration: const InputDecoration(labelText: 'Mã NCC *', border: OutlineInputBorder()),
                                  validator: (v) => v!.isEmpty ? 'Nhập mã NCC' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dvtController,
                                  decoration: const InputDecoration(labelText: 'Đơn vị tính', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _soluongController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Tồn kho', border: OutlineInputBorder()),
                                  validator: (v) => v!.isEmpty ? 'Nhập tồn kho' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _giabanController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Giá Bán *', border: OutlineInputBorder(), suffixText: 'đ'),
                            validator: (v) => v!.isEmpty ? 'Vui lòng nhập giá bán' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ghichuController,
                            decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('LƯU THAY ĐỔI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }
}
