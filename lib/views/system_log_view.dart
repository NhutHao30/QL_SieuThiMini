import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../viewmodels/log_viewmodel.dart';
import '../models/log_model.dart';

class SystemLogView extends StatefulWidget {
  const SystemLogView({super.key});

  @override
  State<SystemLogView> createState() => _SystemLogViewState();
}

class _SystemLogViewState extends State<SystemLogView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogViewModel>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final logVM = context.watch<LogViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhật ký hệ thống',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: AppTheme.primary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: AppTheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchBar(context, logVM),
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'DÒNG THỜI GIAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: logVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await context.read<LogViewModel>().loadLogs();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logVM.logs.length,
                      itemBuilder: (context, index) {
                        return _buildLogCard(context, logVM.logs[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LogViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        onChanged: (val) => vm.filterLogs(val),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm nhật ký...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildChip('Hôm nay', isSelected: true),
        const SizedBox(width: 8),
        _buildChip('Tuần này'),
        const SizedBox(width: 8),
        _buildChip('Tháng này'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: const [
              Icon(CupertinoIcons.line_horizontal_3_decrease, size: 14, color: AppTheme.primary),
              SizedBox(width: 4),
              Text('Loại', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryDark : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogModel log) {
    IconData actionIcon;
    Color iconColor;
    
    String actionName = log.hanhdong.toUpperCase();
    if (actionName.contains('HÓA ĐƠN')) {
      actionIcon = CupertinoIcons.money_dollar_circle_fill;
      iconColor = AppTheme.success;
    } else if (actionName.contains('KHO') || actionName.contains('SẢN PHẨM')) {
      actionIcon = actionName.contains('THÊM') ? CupertinoIcons.add_circled_solid : CupertinoIcons.cube_box_fill;
      iconColor = AppTheme.warning;
    } else if (actionName.contains('KHÁCH HÀNG')) {
      actionIcon = CupertinoIcons.person_solid;
      iconColor = const Color(0xFF3B82F6);
    } else {
      actionIcon = CupertinoIcons.info_circle_fill;
      iconColor = AppTheme.primary;
    }

    String formattedDate = DateFormat('HH:mm - dd/MM/yyyy').format(log.thoigian);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: const Icon(CupertinoIcons.person_fill, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.hoten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(log.chucvu.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.only(right: 12),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(actionIcon, size: 16, color: iconColor),
                                const SizedBox(width: 6),
                                Text(
                                  log.hanhdong,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              log.chitiet,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
