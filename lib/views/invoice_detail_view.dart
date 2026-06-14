import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết hóa đơn',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: const [
          Icon(CupertinoIcons.printer, color: AppTheme.primary),
          SizedBox(width: 16),
          Icon(CupertinoIcons.share, color: AppTheme.primary),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildCustomerCard(context),
            const SizedBox(height: 16),
            _buildProductsCard(context),
            const SizedBox(height: 16),
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.arrow_uturn_left, size: 18),
                    label: const Text('Hoàn trả'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.printer, size: 18),
                    label: const Text('In hóa đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box), label: 'Tồn kho'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar_alt_fill), label: 'Bán hàng'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), label: 'Hóa đơn'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_3), label: 'Nhân viên'),
        ],
        selectedItemColor: AppTheme.success,
        unselectedItemColor: AppTheme.textSecondary,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MÃ HÓA ĐƠN', style: Theme.of(context).textTheme.labelSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FFBBE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Hoàn thành', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF00714D))),
              )
            ],
          ),
          Text('#8842', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text('14:30, 25/10/2023', style: Theme.of(context).textTheme.bodyMedium),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryDark,
            radius: 24,
            child: Icon(CupertinoIcons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nguyễn Văn An', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('090 123 4567', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Điểm tích lũy', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text('+125 pts', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            width: double.infinity,
            child: Text('DANH SÁCH SẢN PHẨM (3)', style: Theme.of(context).textTheme.labelSmall),
          ),
          _buildProductItem(context, 'Sữa tươi TH True Milk 1L', 'SKU: TH-001', 'x2', '70.000đ', Colors.red.shade100),
          const Divider(height: 1, color: AppTheme.border),
          _buildProductItem(context, 'Gạo ST25 Túi 5kg', 'SKU: G-ST25', 'x1', '195.000đ', Colors.brown.shade100),
          const Divider(height: 1, color: AppTheme.border),
          _buildProductItem(context, 'Dầu ăn Simply 2L', 'SKU: S-OIL-2', 'x2', '185.000đ', Colors.yellow.shade100),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, String name, String sku, String qty, String price, Color imgColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: imgColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(sku, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(qty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(price, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow(context, 'Tạm tính', '450.000đ'),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Giảm giá (Voucher)', '-20.000đ', isDiscount: true),
          const SizedBox(height: 12),
          _buildSummaryRow(context, 'Thuế (VAT 8%)', '20.000đ'),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng', style: Theme.of(context).textTheme.headlineMedium),
              Text('450.000đ', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.primary)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDiscount ? Colors.red : AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.creditcard, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text('Thẻ tín dụng (Visa)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          Text('**** 8890', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
