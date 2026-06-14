import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/user_viewmodel.dart';
import 'customer_management_view.dart';
import 'invoice_list_view.dart';
import 'login_view.dart';
import 'system_log_view.dart';

class MoreMenuView extends StatelessWidget {
  const MoreMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Mở rộng',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (context.watch<UserViewModel>().isManager) ...[
            _buildMenuCard(
              context,
              icon: CupertinoIcons.person_2,
              title: 'Quản lý khách hàng',
              subtitle: 'Thêm mới, tích điểm và hạng thành viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerManagementView()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: CupertinoIcons.doc_text,
            title: 'Quản lý hóa đơn',
            subtitle: 'Xem lịch sử giao dịch và in hóa đơn',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceListView()),
              );
            },
          ),
          if (context.watch<UserViewModel>().isAdmin) ...[
            const SizedBox(height: 12),
            _buildMenuCard(
              context,
              icon: CupertinoIcons.time,
              title: 'Nhật ký hệ thống',
              subtitle: 'Theo dõi lịch sử hoạt động của nhân viên',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SystemLogView()),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: CupertinoIcons.settings,
            title: 'Cài đặt hệ thống',
            subtitle: 'Cấu hình ứng dụng và phân quyền',
            onTap: () {
              // Placeholder cho Cài đặt sau này
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await context.read<UserViewModel>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(CupertinoIcons.square_arrow_right),
            label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
