import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../viewmodels/staff_viewmodel.dart';
import 'staff_add_view.dart';
import 'staff_edit_view.dart';

class StaffManagementView extends StatefulWidget {
  const StaffManagementView({super.key});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffViewModel>().loadStaffs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staffVM = context.watch<StaffViewModel>();

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
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<StaffViewModel>().loadStaffs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Staff Management', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Review shifts, roles, and employee performance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StaffAddView()),
                ).then((value) {
                  if (value == true && context.mounted) {
                    context.read<StaffViewModel>().loadStaffs();
                  }
                });
              },
              icon: const Icon(CupertinoIcons.person_add),
              label: const Text('Thêm nhân viên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchBar(context),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFilterButton(context, CupertinoIcons.person_2, 'Role', () {
                  showModalBottomSheet(
                    context: context,
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(title: const Text('Tất cả chức vụ'), onTap: () { context.read<StaffViewModel>().setFilterRole(null); Navigator.pop(c); }),
                          ...staffVM.availableRoles.map((r) => ListTile(
                            title: Text(r['mota'].toString()),
                            onTap: () {
                              context.read<StaffViewModel>().setFilterRole(r['mota'].toString());
                              Navigator.pop(c);
                            },
                          )),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 12),
                _buildFilterButton(context, CupertinoIcons.time, 'Shift', () {
                  showModalBottomSheet(
                    context: context,
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(title: const Text('Tất cả ca'), onTap: () { context.read<StaffViewModel>().setFilterShift(null); Navigator.pop(c); }),
                          ...staffVM.availableShifts.map((s) => ListTile(
                            title: Text(s['tenca'].toString()),
                            onTap: () {
                              context.read<StaffViewModel>().setFilterShift(s['maca'].toString());
                              Navigator.pop(c);
                            },
                          )),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            _buildShiftCard(context),
            const SizedBox(height: 24),
            Text('Employee Directory', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            if (staffVM.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (staffVM.errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Lỗi tải dữ liệu: ${staffVM.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (staffVM.filteredStaffs.isEmpty)
              const Center(child: Text('Không có nhân viên nào.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staffVM.filteredStaffs.length,
                itemBuilder: (context, index) {
                  final staff = staffVM.filteredStaffs[index];
                  return _buildEmployeeCard(
                    context,
                    staff.hoten,
                    staff.chucvu.toUpperCase(),
                    staff.username,
                    staff.email,
                    staff.sdt,
                    staff.isOnline,
                    staff.isActive ? (staff.isOnline ? 'Online' : 'Offline') : 'Bị Khóa',
                    staff,
                  );
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing ${staffVM.filteredStaffs.length} employees', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
        onChanged: (val) => context.read<StaffViewModel>().setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search by name or ID...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MORNING SHIFT', style: Theme.of(context).textTheme.labelSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF6EE7B7), borderRadius: BorderRadius.circular(12)),
                      child: const Text('CURRENT', style: TextStyle(color: Color(0xFF064E3B), fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text('08:00 AM — 04:00 PM', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildAvatarOverlap(0),
                    _buildAvatarOverlap(1),
                    _buildAvatarOverlap(2),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('+9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.graph_square, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('EFFICIENCY', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('94.2%', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                    Container(height: 4, width: 250, decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(2))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Top Performer: Marcus Chen', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvatarOverlap(int index) {
    return Align(
      widthFactor: 0.7,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.primaries[index % Colors.primaries.length],
          child: const Icon(CupertinoIcons.person, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, String name, String role, String id, String email, String phone, bool isOnline, String statusText, dynamic staff) {
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
          Stack(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(CupertinoIcons.person, color: Colors.grey),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? AppTheme.success : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(role, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              Text(' • ID: $id', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.mail, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(email, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(width: 12),
              const Icon(CupertinoIcons.phone, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(phone, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.pencil, size: 18, color: AppTheme.textSecondary),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StaffEditView(staff: staff))).then((value) {
                    if (value == true && context.mounted) {
                      context.read<StaffViewModel>().loadStaffs();
                    }
                  });
                },
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc chắn muốn xóa nhân viên này? Dữ liệu không thể khôi phục.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirm && context.mounted) {
                    try {
                      await context.read<StaffViewModel>().deleteStaff(id);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa nhân viên')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  staff.isActive ? CupertinoIcons.lock_open : CupertinoIcons.lock,
                  size: 18,
                  color: staff.isActive ? AppTheme.success : AppTheme.warning,
                ),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(staff.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
                      content: Text(staff.isActive 
                          ? 'Nhân viên này sẽ không thể đăng nhập vào hệ thống nữa. Bạn có chắc chắn?' 
                          : 'Cho phép nhân viên này đăng nhập trở lại?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true), 
                          child: Text(staff.isActive ? 'Khóa' : 'Mở khóa', style: TextStyle(color: staff.isActive ? AppTheme.warning : AppTheme.success))
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirm && context.mounted) {
                    try {
                      await context.read<StaffViewModel>().toggleStatus(id, staff.isActive);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(staff.isActive ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isOnline ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          )
        ],
      ),
    );
  }
}
