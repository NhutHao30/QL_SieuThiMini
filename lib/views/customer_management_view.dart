import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/customer_model.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../services/invoice_service.dart';
import '../models/invoice_model.dart';
import '../models/invoice_detail_model.dart';
import '../utils/pdf_invoice_api.dart';
import 'package:intl/intl.dart';

class CustomerManagementView extends StatefulWidget {
  const CustomerManagementView({super.key});

  @override
  State<CustomerManagementView> createState() => _CustomerManagementViewState();
}

class _CustomerManagementViewState extends State<CustomerManagementView> {
  String _selectedTierFilter = 'All';
  String _selectedTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerViewModel>().loadCustomers();
      }
    });
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String gender = 'Nam';
    String customerType = 'Le'; // 'Le' or 'DaiLy'
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm khách hàng mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      items: ['Nam', 'Nữ'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: const InputDecoration(labelText: 'Giới tính'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: customerType,
                      items: ['Le', 'DaiLy'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => customerType = v!),
                      decoration: const InputDecoration(labelText: 'Loại khách'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                
                final newCustomer = CustomerModel(
                  makh: 'KH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  hoten: nameCtrl.text,
                  sdt: phoneCtrl.text,
                  gioitinh: gender,
                  diachi: 'Chưa cập nhật',
                  ngaysinh: '2000-01-01',
                  loaikh: customerType,
                  diemtichluy: 0,
                );
                
                try {
                  await context.read<CustomerViewModel>().addCustomer(newCustomer);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(CustomerModel customer) {
    final nameCtrl = TextEditingController(text: customer.hoten);
    final phoneCtrl = TextEditingController(text: customer.sdt);
    String gender = customer.gioitinh;
    String customerType = customer.loaikh;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sửa khách hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      items: ['Nam', 'Nữ'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => gender = v!),
                      decoration: const InputDecoration(labelText: 'Giới tính'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: customerType,
                      items: ['Le', 'DaiLy'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => customerType = v!),
                      decoration: const InputDecoration(labelText: 'Loại khách'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                
                final updatedCustomer = CustomerModel(
                  makh: customer.makh,
                  hoten: nameCtrl.text,
                  sdt: phoneCtrl.text,
                  gioitinh: gender,
                  diachi: customer.diachi,
                  ngaysinh: customer.ngaysinh,
                  loaikh: customerType,
                  diemtichluy: customer.diemtichluy,
                );
                
                try {
                  await context.read<CustomerViewModel>().updateCustomer(updatedCustomer);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khách hàng "${customer.hoten}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await context.read<CustomerViewModel>().deleteCustomer(customer);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  String errorMsg = e.toString().replaceAll('Exception: Exception: ', '').replaceAll('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin chi tiết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã KH: ${customer.makh}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Họ tên: ${customer.hoten}'),
            const SizedBox(height: 4),
            Text('Số điện thoại: ${customer.sdt}'),
            const SizedBox(height: 4),
            Text('Giới tính: ${customer.gioitinh}'),
            const SizedBox(height: 4),
            Text('Địa chỉ: ${customer.diachi}'),
            const SizedBox(height: 4),
            Text('Ngày sinh: ${customer.ngaysinh}'),
            const SizedBox(height: 4),
            Text('Loại khách: ${customer.loaikh == 'Le' ? 'Khách lẻ' : 'Đại lý'}'),
            const SizedBox(height: 4),
            Text('Điểm tích lũy: ${customer.diemtichluy}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  void _showCustomerHistory(BuildContext context, CustomerModel customer) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final invoices = await InvoiceService().getInvoices();
      final customerInvoices = invoices.where((i) => i.makh == customer.makh).toList();
      
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) {
          final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
          return AlertDialog(
            title: Text('Lịch sử mua hàng: ${customer.hoten}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            content: SizedBox(
              width: double.maxFinite,
              child: customerInvoices.isEmpty
                  ? const Text('Khách hàng chưa có giao dịch nào.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: customerInvoices.length,
                      itemBuilder: (context, index) {
                        final inv = customerInvoices[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(CupertinoIcons.doc_text, color: AppTheme.primary),
                          title: Text(inv.mahd, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(inv.ngaylap),
                          trailing: Text(
                            currencyFormat.format(inv.tongtien),
                            style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pop(context); // close history dialog
                            _showInvoiceDetails(context, inv);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              )
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showInvoiceDetails(BuildContext context, InvoiceModel invoice) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final details = await InvoiceService().getInvoiceDetails(invoice.mahd);
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showInvoiceDetailsDialog(context, invoice, details);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      PdfInvoiceApi.generateAndPrint(invoice, details);
                    },
                    icon: const Icon(CupertinoIcons.printer),
                    label: const Text('In hóa đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
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
    final customerVM = context.watch<CustomerViewModel>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<CustomerViewModel>().loadCustomers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Customer Database', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Manage relationships, loyalty rewards, and purchase histories.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(CupertinoIcons.person_add),
              label: const Text('THÊM KHÁCH HÀNG MỚI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricCard(context, 'ACTIVE MEMBERS', '1,284', null)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(context, 'POINTS ISSUED', '42.5K', AppTheme.success)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard(context, 'TOP TIER (GOLD)', '15%', null)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard(context, 'AVG SPEND', '\$342', null)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSearchBar(context)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTierFilter,
                      icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTierFilter = newValue!;
                        });
                      },
                      items: <String>['All', 'SILVER', 'GOLD', 'PLATINUM']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'All' ? 'Tier' : value, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTypeFilter,
                      icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTypeFilter = newValue!;
                        });
                      },
                      items: <String>['All', 'Le', 'DaiLy']
                          .map<DropdownMenuItem<String>>((String value) {
                        String display = value;
                        if (value == 'All') display = 'Loại';
                        if (value == 'Le') display = 'Khách Lẻ';
                        if (value == 'DaiLy') display = 'Đại Lý';
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(display, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customerVM.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Builder(
                builder: (context) {
                  List<CustomerModel> filteredList = customerVM.customers.where((c) {
                    // Filter Type
                    if (_selectedTypeFilter != 'All' && c.loaikh != _selectedTypeFilter) return false;
                    
                    // Filter Tier
                    String tier = 'SILVER';
                    if (c.diemtichluy > 1000) tier = 'GOLD';
                    if (c.diemtichluy > 5000) tier = 'PLATINUM';
                    if (_selectedTierFilter != 'All' && tier != _selectedTierFilter) return false;

                    return true;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Không tìm thấy khách hàng nào')),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final customer = filteredList[index];
                  // Assign color and tier based on points
                  Color avatarColor = const Color(0xFFE2E8F0);
                  String tier = 'SILVER';
                  Color tierBg = const Color(0xFFE2E8F0);
                  Color tierText = const Color(0xFF334155);

                  if (customer.diemtichluy > 1000) {
                    avatarColor = const Color(0xFFA5B4FC);
                    tier = 'GOLD';
                    tierBg = const Color(0xFF6EE7B7);
                    tierText = const Color(0xFF065F46);
                  }
                  if (customer.diemtichluy > 5000) {
                    avatarColor = const Color(0xFFFDE68A);
                    tier = 'PLATINUM';
                    tierBg = const Color(0xFF78350F);
                    tierText = Colors.white;
                  }

                  String init = '';
                  if (customer.hoten.isNotEmpty) {
                    List<String> names = customer.hoten.split(' ');
                    if (names.length > 1) {
                      init = names.first[0].toUpperCase() + names.last[0].toUpperCase();
                    } else {
                      init = names.first[0].toUpperCase();
                    }
                  }

                  return _buildCustomerCard(
                    context,
                    init,
                    avatarColor,
                    customer.hoten,
                    customer.sdt,
                    customer.diemtichluy.toString(),
                    tier,
                    tierBg,
                    tierText,
                    '\$---', // spend is not available in model
                    customer,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          _buildBanner(context),
          const SizedBox(height: 32),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, Color? valueColor) {
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
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: valueColor ?? AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, phone...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          context.read<CustomerViewModel>().searchCustomers(value);
        },
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, String init, Color avatarColor, String name, String phone, String points, String tier, Color tierBg, Color tierText, String spend, CustomerModel customer) {
    return Container(
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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: avatarColor,
                    radius: 20,
                    child: Text(init, style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.phone, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(phone, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      )
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                onSelected: (value) {
                  if (value == 'view') {
                    _showCustomerDetails(customer);
                  } else if (value == 'edit') {
                    _showEditCustomerDialog(customer);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(customer);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                  const PopupMenuItem(value: 'edit', child: Text('Sửa khách hàng')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa khách hàng', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(points, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Tier', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tier, style: TextStyle(color: tierText, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Spend', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(spend, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomerHistory(context, customer),
              icon: const Icon(CupertinoIcons.time),
              label: const Text('XEM LỊCH SỬ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryDark,
                side: const BorderSide(color: AppTheme.primaryDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grow Your\nCommunity',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Launch a 2x points\ncampaign to boost\nengagement.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SETUP NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
