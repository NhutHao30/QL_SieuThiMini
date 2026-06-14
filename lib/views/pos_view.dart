import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/pos_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'checkout_view.dart';

class PosView extends StatefulWidget {
  const PosView({super.key});

  @override
  State<PosView> createState() => _PosViewState();
}

class _PosViewState extends State<PosView> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PosViewModel>().loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final posVM = context.watch<PosViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(CupertinoIcons.bars, color: AppTheme.primary),
        title: Text(
          'StoreManager',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: const [
          Icon(CupertinoIcons.barcode_viewfinder, color: AppTheme.primary),
          SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await context.read<PosViewModel>().loadProducts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(context, posVM),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill('Tất cả', true),
                      const SizedBox(width: 8),
                      _buildFilterPill('Thực phẩm', false),
                      const SizedBox(width: 8),
                      _buildFilterPill('Nước uống', false),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Horizontal product selector
                if (posVM.isLoading)
                   const Center(child: CircularProgressIndicator())
                else
                   SizedBox(
                     height: 130,
                     child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: posVM.products.length,
                       itemBuilder: (context, index) {
                         final product = posVM.products[index];
                         return GestureDetector(
                           onTap: () async {
                             final error = await posVM.addToCart(product);
                             if (error != null && context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                             }
                           },
                           child: Container(
                             width: 110,
                             margin: const EdgeInsets.only(right: 8),
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: AppTheme.surface,
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(color: AppTheme.border),
                             ),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const Icon(CupertinoIcons.cube_box, color: AppTheme.primary, size: 32),
                                 const SizedBox(height: 8),
                                 Text(
                                   product.tensp,
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                                   textAlign: TextAlign.center,
                                   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   currencyFormat.format(product.giaban),
                                   style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                 )
                               ],
                             ),
                           ),
                         );
                       },
                     ),
                   ),

                const SizedBox(height: 24),
                _buildCartSection(context, posVM),
                const SizedBox(height: 80),
              ],
            ),
          ),
          ),
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _openScanner(context, posVM),
              backgroundColor: AppTheme.primaryDark,
              child: const Icon(CupertinoIcons.barcode_viewfinder, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  void _openScanner(BuildContext context, PosViewModel posVM) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerScreen(posVM: posVM)));
  }

  Widget _buildSearchBar(BuildContext context, PosViewModel posVM) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        onChanged: (val) {
          posVM.searchProducts(val);
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm hoặc quét mã...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.textSecondary),
          suffixIcon: GestureDetector(
            onTap: () => _openScanner(context, posVM),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppTheme.primary, size: 20),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryDark : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? AppTheme.surface : AppTheme.textSecondary,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCartSection(BuildContext context, PosViewModel posVM) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giỏ hàng hiện tại', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
                GestureDetector(
                  onTap: () => posVM.clearCart(),
                  child: Text('Xóa tất cả', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          
          if (posVM.cart.isEmpty)
             const Padding(
               padding: EdgeInsets.all(32),
               child: Center(child: Text("Giỏ hàng trống", style: TextStyle(color: AppTheme.textSecondary))),
             )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posVM.cart.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, index) {
                final item = posVM.cart[index];
                return _buildCartItem(context, posVM, item);
              },
            ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tạm tính', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                    Text(currencyFormat.format(posVM.subtotal), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thuế (8%)', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                    Text(currencyFormat.format(posVM.tax), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng tiền', style: Theme.of(context).textTheme.headlineSmall),
                    Text(currencyFormat.format(posVM.total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: posVM.cart.isEmpty || posVM.isCheckingOut
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutView(posVM: posVM),
                            ),
                          );
                        },
                  icon: posVM.isCheckingOut 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(CupertinoIcons.cart),
                  label: Text(posVM.isCheckingOut ? 'Đang xử lý...' : 'Thanh toán', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, PosViewModel posVM, dynamic item) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.cube_box, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.tensp, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${currencyFormat.format(item.product.giaban)} / ${item.product.dvt}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => posVM.updateQuantity(item.product.masp, item.quantity - 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 16, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Text('${item.quantity}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => posVM.updateQuantity(item.product.masp, item.quantity + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(CupertinoIcons.add, size: 16, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              currencyFormat.format(item.total),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  final PosViewModel posVM;
  const ScannerScreen({super.key, required this.posVM});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã sản phẩm')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (isProcessing) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            setState(() { isProcessing = true; });
            final success = await widget.posVM.addProductByBarcode(code);
            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm sản phẩm mã $code')));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tìm thấy mã $code')));
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() { isProcessing = false; });
                });
              }
            }
          }
        },
      ),
    );
  }
}
