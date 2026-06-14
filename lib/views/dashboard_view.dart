import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import 'chat_view.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardViewModel>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<DashboardViewModel>();
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
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ca đang làm',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Consumer<ChatViewModel>(
            builder: (context, chatVM, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.chat_bubble_2, color: AppTheme.primary),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatView()));
                    },
                  ),
                  if (chatVM.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chatVM.unreadCount > 9 ? '9+' : '${chatVM.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.bell, color: AppTheme.primary),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardViewModel>().loadDashboardStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailyRevenueCard(context, dashboardVM),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Hóa đơn hôm nay',
                    '${dashboardVM.todayOrders}',
                    CupertinoIcons.shopping_cart,
                    false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Cảnh báo tồn kho',
                    '${dashboardVM.lowStockItems} mặt hàng',
                    CupertinoIcons.exclamationmark_triangle,
                    dashboardVM.lowStockItems > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Quét mã',
                    CupertinoIcons.barcode,
                    true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Thêm mới',
                    CupertinoIcons.add,
                    false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Xuất báo cáo',
                    CupertinoIcons.doc_on_clipboard,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'CẢNH BÁO THÔNG MINH',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildAlertCard(context),
            const SizedBox(height: 24),
            Text(
              'HIỆU SUẤT TRONG NGÀY',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            _buildHourlyPerformanceCard(context),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao dịch gần đây',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Xem tất cả',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dashboardVM.recentSales.isEmpty)
              const Center(child: Text('Chưa có giao dịch nào'))
            else
              ...dashboardVM.recentSales.map((sale) {
                final cthd = sale['chitiethdban'] as List<dynamic>?;
                int totalItems = 0;
                if (cthd != null) {
                  for (var item in cthd) {
                    totalItems += int.tryParse(item['soluong'].toString()) ?? 0;
                  }
                }
                
                DateTime? date;
                if (sale['ngaylap'] != null) {
                  date = DateTime.tryParse(sale['ngaylap'].toString());
                }
                final timeAgo = date != null ? DateFormat('dd/MM HH:mm').format(date.toLocal()) : '';
                
                return _buildRecentSaleItem(
                  context,
                  'Mã HĐ: ${sale['mahd']}',
                  '$totalItems sản phẩm • $timeAgo',
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(double.tryParse(sale['tongtien'].toString()) ?? 0.0),
                );
              }),
            const SizedBox(height: 24),
            _buildBanner(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDailyRevenueCard(BuildContext context, DashboardViewModel dashboardVM) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DOANH THU HÔM NAY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_up_right,
                      color: AppTheme.success,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trực tiếp',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(dashboardVM.todayRevenue),
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: AppTheme.primary, fontSize: 28),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(2, 3),
                      FlSpot(4, 5),
                      FlSpot(6, 4),
                      FlSpot(8, 7),
                      FlSpot(10, 4),
                      FlSpot(12, 7),
                    ],
                    isCurved: true,
                    color: AppTheme.success,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.success.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'so với hôm qua',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    bool isAlert,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFEF2F2) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAlert ? const Color(0xFFFECACA) : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAlert
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isAlert ? Colors.red : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isAlert ? Colors.red.shade900 : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isAlert ? Colors.red.shade700 : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.primaryDark : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppTheme.primary,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isPrimary ? AppTheme.surface : AppTheme.primary,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPrimary ? AppTheme.surface : AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              color: AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sắp hết hạn',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12 sản phẩm sẽ hết hạn trong vòng 7 ngày',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF451A03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyPerformanceCard(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 20,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  );
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = '08:00';
                      break;
                    case 3:
                      text = '12:00';
                      break;
                    case 6:
                      text = '16:00';
                      break;
                    case 9:
                      text = '20:00';
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return SideTitleWidget(
                    space: 8,
                    meta: meta,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _buildBarGroup(0, 5, isPrimary: false),
            _buildBarGroup(1, 8, isPrimary: false),
            _buildBarGroup(2, 12, isPrimary: true),
            _buildBarGroup(3, 6, isPrimary: false),
            _buildBarGroup(4, 4, isPrimary: false),
            _buildBarGroup(5, 10, isPrimary: true),
            _buildBarGroup(6, 5, isPrimary: false),
            _buildBarGroup(7, 9, isPrimary: false),
            _buildBarGroup(8, 14, isPrimary: true),
            _buildBarGroup(9, 6, isPrimary: false),
            _buildBarGroup(10, 5, isPrimary: false),
            _buildBarGroup(11, 15, isPrimary: true),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, {bool isPrimary = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isPrimary ? AppTheme.primaryDark : const Color(0xFFE0E7FF),
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRecentSaleItem(
    BuildContext context,
    String title,
    String subtitle,
    String price,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.doc_text,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text(
            price,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
          ),
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
            'Kiểm kê kho',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Lịch kiểm kê kho số 4 sẽ bắt đầu trong 2 giờ tới.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
