import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../models/invoice_model.dart';
import '../models/invoice_detail_model.dart';
import '../utils/pdf_invoice_api.dart';
import 'package:intl/intl.dart';

class InvoiceListView extends StatefulWidget {
  const InvoiceListView({super.key});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InvoiceViewModel>().loadInvoices();
      }
    });
  }

  void _showInvoiceDetails(BuildContext context, InvoiceModel invoice) async {
    final viewModel = context.read<InvoiceViewModel>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final details = await viewModel.getInvoiceDetails(invoice.mahd, invoice.isImport);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      _showInvoiceDetailsDialog(context, invoice, details);
    }
  }

  void _showInvoiceDetailsDialog(BuildContext context, InvoiceModel invoice, List<InvoiceDetailModel> details) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chi tiết hóa đơn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Text('Mã HĐ: ${invoice.mahd}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Ngày lập: ${invoice.ngaylap}'),
              Text('Khách hàng: ${invoice.customerName}'),
              const SizedBox(height: 16),
              const Text('Danh sách sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: details.length,
                  itemBuilder: (context, index) {
                    final item = details[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${item.soluong} x ${currencyFormat.format(item.dongia)}', textAlign: TextAlign.right),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(currencyFormat.format(item.thanhtien), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(currencyFormat.format(invoice.tongtien), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: const Text('Bạn có chắc chắn muốn xóa hóa đơn này không? Kho sẽ được hoàn trả lại số lượng.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ) ?? false;
                        
                        if (confirm && context.mounted) {
                          try {
                            await context.read<InvoiceViewModel>().deleteInvoice(invoice.mahd, invoice.isImport);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa hóa đơn thành công!')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        }
                      },
                      icon: const Icon(CupertinoIcons.trash, color: Colors.red),
                      label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PdfInvoiceApi.generateAndPrint(invoice, details);
                      },
                      icon: const Icon(CupertinoIcons.printer),
                      label: const Text('In hóa đơn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
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
    final invoiceVM = context.watch<InvoiceViewModel>();
    
    // Calculate summary
    double totalRevenue = 0;
    for (var inv in invoiceVM.filteredInvoices) {
      totalRevenue += inv.tongtien;
    }
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý hóa đơn',
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
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<InvoiceViewModel>().loadInvoices();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSegmentedControl<InvoiceViewType>(
                      groupValue: invoiceVM.viewType,
                      selectedColor: AppTheme.primary,
                      borderColor: AppTheme.primary,
                      children: const {
                        InvoiceViewType.sales: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Hóa Đơn Bán', style: TextStyle(fontWeight: FontWeight.bold))),
                        InvoiceViewType.import: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Hóa Đơn Nhập', style: TextStyle(fontWeight: FontWeight.bold))),
                      },
                      onValueChanged: (type) {
                        context.read<InvoiceViewModel>().setViewType(type);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(context, invoiceVM),
                  const SizedBox(height: 16),
                  _buildFilterSection(invoiceVM),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(context, invoiceVM.viewType == InvoiceViewType.sales ? 'TỔNG DOANH THU' : 'TỔNG CHI PHÍ', currencyFormat.format(totalRevenue), null)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(context, 'TỔNG HÓA ĐƠN', '${invoiceVM.filteredInvoices.length}', null)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: invoiceVM.isLoading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == invoiceVM.filteredInvoices.length) {
                          return const SizedBox(height: 32);
                        }
                        final invoice = invoiceVM.filteredInvoices[index];
                        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                        return _buildInvoiceCard(
                          context,
                          invoice,
                          1,
                          true,
                        );
                      },
                      childCount: invoiceVM.filteredInvoices.length + 1,
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, InvoiceViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        onChanged: (value) => vm.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: vm.viewType == InvoiceViewType.sales ? 'Tìm mã HĐ hoặc tên khách...' : 'Tìm mã phiếu hoặc tên NCC...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterSection(InvoiceViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Tất cả', vm.currentFilter == InvoiceFilterType.all, () => vm.setFilterType(InvoiceFilterType.all)),
          const SizedBox(width: 8),
          _buildFilterChip('Hôm nay', vm.currentFilter == InvoiceFilterType.today, () => vm.setFilterType(InvoiceFilterType.today)),
          const SizedBox(width: 8),
          _buildFilterChip('Tuần này', vm.currentFilter == InvoiceFilterType.thisWeek, () => vm.setFilterType(InvoiceFilterType.thisWeek)),
          const SizedBox(width: 8),
          _buildFilterChip('Tháng này', vm.currentFilter == InvoiceFilterType.thisMonth, () => vm.setFilterType(InvoiceFilterType.thisMonth)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryDark : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryDark : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.surface : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, String? change) {
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
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary)),
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Text(change, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold)),
              ]
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice, int status, bool hasAvatar) {
    // status: 1 = Hoàn thành, 2 = Nợ, 3 = Đã hủy
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    if (status == 1) {
      statusColor = AppTheme.success;
      statusBgColor = const Color(0xFFD1FAE5);
      statusText = 'Hoàn thành';
      statusIcon = CupertinoIcons.check_mark_circled;
    } else if (status == 2) {
      statusColor = const Color(0xFFC2410C);
      statusBgColor = const Color(0xFFFFEDD5);
      statusText = 'Nợ';
      statusIcon = CupertinoIcons.exclamationmark_circle;
    } else {
      statusColor = const Color(0xFF9CA3AF);
      statusBgColor = const Color(0xFFF3F4F6);
      statusText = 'Đã hủy';
      statusIcon = CupertinoIcons.xmark_circle;
    }

    return GestureDetector(
      onTap: () => _showInvoiceDetails(context, invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.mahd, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
                    const SizedBox(height: 4),
                    Text(invoice.ngaylap, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(statusText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE2E8F0),
                        radius: 20,
                        child: hasAvatar
                            ? const Icon(CupertinoIcons.person_solid, color: Colors.grey)
                            : const Icon(CupertinoIcons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(invoice.customerName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(CupertinoIcons.money_dollar, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(child: Text('Tiền mặt/Chuyển khoản', style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(invoice.tongtien),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: status == 3 ? AppTheme.textSecondary : AppTheme.textPrimary,
                        decoration: status == 3 ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${invoice.totalItems} mặt hàng', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
