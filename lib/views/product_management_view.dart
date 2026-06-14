import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import '../viewmodels/product_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import '../models/product_model.dart';
import 'product_add_view.dart';
import 'product_edit_view.dart';

class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() =>
      _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductViewModel>().loadProducts();
      }
    });
  }

  Widget _buildChip(String label, {required bool isSelected, bool isStatus = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isStatus ? Colors.blue[100] : AppTheme.primaryDark) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (isStatus ? Colors.blue : AppTheme.primaryDark) 
                : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (isStatus ? Colors.blue[800] : Colors.white) 
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator(int stock) {
    if (stock == 0) {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
          const SizedBox(width: 4),
          const Text('OUT OF STOCK', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      );
    } else if (stock < 10) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
          const SizedBox(width: 4),
          Text('Low Stock: $stock units', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: stock,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10 - stock,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text('Stock: $stock units', style: const TextStyle(color: Colors.black87, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: stock > 50 ? 50 : stock,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  flex: stock > 50 ? 0 : 50 - stock,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _showProductDetails(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chi tiết sản phẩm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              // QR Code
              Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: QrImageView(
                  data: product.masp,
                  version: QrVersions.auto,
                  size: 130,
                ),
              ),
              const SizedBox(height: 24),
              // Product Info
              Text(product.tensp, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Mã SP (SKU): ${product.masp}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giá bán:', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  Text('${product.giaban.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tồn kho:', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  Text('${product.soluong} ${product.dvt}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loại SP:', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  Text(product.maloai, style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(product.trangthai ? 'Xác nhận vô hiệu hóa' : 'Xác nhận kích hoạt'),
                            content: Text(product.trangthai 
                                ? 'Bạn có chắc chắn muốn vô hiệu hóa sản phẩm này? Nó sẽ không thể thêm vào giỏ hàng được nữa.'
                                : 'Bạn muốn kích hoạt lại sản phẩm này?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true), 
                                child: Text(product.trangthai ? 'Vô hiệu hóa' : 'Kích hoạt', style: TextStyle(color: product.trangthai ? Colors.red : AppTheme.success)),
                              ),
                            ],
                          ),
                        ) ?? false;

                        if (confirm && context.mounted) {
                          try {
                            await context.read<ProductViewModel>().toggleProductStatus(product.masp, product.trangthai);
                            if (context.mounted) {
                              Navigator.pop(context); // Close details dialog
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product.trangthai ? 'Đã vô hiệu hóa sản phẩm!' : 'Đã kích hoạt sản phẩm!')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        }
                      },
                      icon: Icon(product.trangthai ? CupertinoIcons.nosign : CupertinoIcons.check_mark_circled, color: product.trangthai ? Colors.red : AppTheme.success),
                      label: Text(product.trangthai ? 'Vô hiệu hóa' : 'Kích hoạt', style: TextStyle(color: product.trangthai ? Colors.red : AppTheme.success)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: product.trangthai ? Colors.red : AppTheme.success),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog first
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductEditView(product: product),
                          ),
                        ).then((result) {
                          if (result == true) {
                            // If edit successful, refresh is already done in ProductEditView
                            // but we can refresh again just to be safe
                            context.read<ProductViewModel>().refreshProducts();
                          }
                        });
                      },
                      icon: const Icon(CupertinoIcons.pencil),
                      label: const Text('Sửa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productVM = context.watch<ProductViewModel>();
    final userVM = context.watch<UserViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: userVM.canManageInventory ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductAddView()),
          );
        },
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: const Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: AppTheme.primaryDark, size: 28),
                  const SizedBox(width: 16),
                  const Text(
                    'StoreManager',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE SALES',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(CupertinoIcons.barcode_viewfinder, color: AppTheme.primaryDark, size: 26),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => productVM.refreshProducts(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inventory & Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TỒN KHO',
                              style: TextStyle(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Product Catalog',
                              style: TextStyle(
                                color: Color(0xFF0B1437),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search SKU or name...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(CupertinoIcons.search, color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primary),
                            ),
                          ),
                          onChanged: (value) {
                            productVM.searchProducts(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Categories Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.filter_list, color: AppTheme.textPrimary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Categories',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildChip('Tất cả', isSelected: productVM.currentCategory == 'Tất cả', onTap: () => productVM.setCategoryFilter('Tất cả')),
                            const SizedBox(width: 8),
                            _buildChip('L01 (Đồ ăn)', isSelected: productVM.currentCategory == 'L01', onTap: () => productVM.setCategoryFilter('L01')),
                            const SizedBox(width: 8),
                            _buildChip('L02 (Nước)', isSelected: productVM.currentCategory == 'L02', onTap: () => productVM.setCategoryFilter('L02')),
                            const SizedBox(width: 8),
                            _buildChip('Hoạt động', isSelected: productVM.filterStatus == true, isStatus: true, onTap: () => productVM.setStatusFilter(productVM.filterStatus == true ? null : true)),
                            const SizedBox(width: 8),
                            _buildChip('Vô hiệu hóa', isSelected: productVM.filterStatus == false, isStatus: true, onTap: () => productVM.setStatusFilter(productVM.filterStatus == false ? null : false)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product List
                      if (productVM.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (productVM.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              productVM.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: productVM.filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = productVM.filteredProducts[index];
                            return GestureDetector(
                              onTap: () => _showProductDetails(context, product),
                              child: Card(
                                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppTheme.border),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    // QR Code Image
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: QrImageView(
                                          data: product.masp,
                                          version: QrVersions.auto,
                                          size: 80,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.tensp,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: product.trangthai ? AppTheme.textPrimary : Colors.grey,
                                                    decoration: product.trangthai ? null : TextDecoration.lineThrough,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${product.giaban.toStringAsFixed(0)} đ',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'SKU: ${product.masp}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              const Text(
                                                'Unit Price',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _buildStockIndicator(product.soluong),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            );
                          },
                        ),
                        
                      // Pagination
                      if (!productVM.isLoading && productVM.errorMessage == null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: productVM.currentPage > 1
                                    ? productVM.previousPage
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Trước'),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                'Trang ${productVM.currentPage}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: productVM.hasMore
                                    ? productVM.nextPage
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Sau'),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}