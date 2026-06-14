import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../viewmodels/pos_viewmodel.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import 'package:intl/intl.dart';

class CheckoutView extends StatefulWidget {
  final PosViewModel posVM;

  const CheckoutView({super.key, required this.posVM});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _paymentMethod = 'cash'; // 'cash' or 'transfer'
  bool _isProcessing = false;

  final TextEditingController _phoneCtrl = TextEditingController();
  CustomerModel? _selectedCustomer;
  bool _isSearchingCustomer = false;

  void _searchCustomer() async {
    if (_phoneCtrl.text.isEmpty) return;
    setState(() => _isSearchingCustomer = true);
    try {
      final customers = await CustomerService().searchCustomers(_phoneCtrl.text);
      setState(() {
        if (customers.isNotEmpty) {
          _selectedCustomer = customers.first;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tìm thấy khách hàng: ${_selectedCustomer!.hoten}'), backgroundColor: AppTheme.success));
        } else {
          _selectedCustomer = null;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy khách hàng!'), backgroundColor: Colors.red));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isSearchingCustomer = false);
    }
  }

  void _confirmCheckout() async {
    setState(() { _isProcessing = true; });
    final mahd = await widget.posVM.checkout(customer: _selectedCustomer);
    if (mounted) {
      setState(() { _isProcessing = false; });
      if (mahd != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thanh toán thành công! Mã HĐ: $mahd'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context); // Go back to POS
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${widget.posVM.errorMessage}'), backgroundColor: Colors.red),
        );
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
          'Thanh Toán',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tổng tiền
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TỔNG CỘNG',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(widget.posVM.total),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text('Khách hàng (Tích điểm)', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Nhập SĐT khách hàng...',
                            prefixIcon: const Icon(CupertinoIcons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _searchCustomer(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearchingCustomer ? null : _searchCustomer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSearchingCustomer
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Kiểm tra', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.person_crop_circle_fill, color: AppTheme.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCustomer!.hoten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Điểm tích lũy: ${_selectedCustomer!.diemtichluy}', style: const TextStyle(color: AppTheme.primaryDark)),
                              ],
                            ),
                          ),
                          Text(
                            '+${widget.posVM.total ~/ 1000} điểm',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  Text('Phương thức thanh toán', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  
                  // Cash Option
                  GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'cash' ? const Color(0xFFE0E7FF) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'cash' ? AppTheme.primary : AppTheme.border,
                          width: _paymentMethod == 'cash' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.money_dollar_circle_fill, size: 32, color: _paymentMethod == 'cash' ? AppTheme.primary : AppTheme.textSecondary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text('Tiền mặt', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (_paymentMethod == 'cash')
                            const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Transfer Option
                  GestureDetector(
                    onTap: () => setState(() => _paymentMethod = 'transfer'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _paymentMethod == 'transfer' ? const Color(0xFFE0E7FF) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == 'transfer' ? AppTheme.primary : AppTheme.border,
                          width: _paymentMethod == 'transfer' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.qrcode_viewfinder, size: 32, color: _paymentMethod == 'transfer' ? AppTheme.primary : AppTheme.textSecondary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text('Chuyển khoản (VietQR)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          if (_paymentMethod == 'transfer')
                            const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // QR Code display if Transfer selected
                  if (_paymentMethod == 'transfer')
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          const Text('Quét mã để thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          // VietQR URL logic: using Vietcombank (vcb) as default
                          // Format: https://img.vietqr.io/image/<BANK_BIN>-<ACCOUNT_NO>-<TEMPLATE>.png?amount=<AMOUNT>&addInfo=<DESCRIPTION>
                          Image.network(
                            'https://img.vietqr.io/image/vcb-1031367128-compact2.png?amount=${widget.posVM.total.toInt()}&addInfo=Thanh toan don hang',
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 250, height: 250,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                width: 250, height: 250,
                                child: Center(child: Text('Không thể tải mã QR', style: TextStyle(color: Colors.red))),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Ngân hàng: Vietcombank', style: TextStyle(color: AppTheme.textSecondary)),
                          const Text('STK: 1031367128', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryDark)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppTheme.border)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirmCheckout,
              icon: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(CupertinoIcons.check_mark_circled_solid),
              label: Text(_isProcessing ? 'Đang xử lý...' : 'Xác nhận Đã Thanh Toán', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
