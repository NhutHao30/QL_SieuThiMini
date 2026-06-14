import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/pos_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'dashboard_view.dart';
import 'more_menu_view.dart';
import 'staff_management_view.dart';
import 'product_management_view.dart';
import 'pos_view.dart';
import 'chat_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  Map<String, dynamic>? _lastNotifiedMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatVM = context.read<ChatViewModel>();
      chatVM.addListener(() {
        if (!mounted) return;
        final newMsg = chatVM.latestMessage;
        if (newMsg != null && newMsg != _lastNotifiedMessage && !chatVM.isChatOpen) {
          _lastNotifiedMessage = newMsg;
          _showFloatingNotification(newMsg);
        }
      });
    });
  }

  void _showFloatingNotification(Map<String, dynamic> msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg['sender_name'] ?? 'Nhân viên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(msg['message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(top: kToolbarHeight, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.yellowAccent,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatView()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    
    // Always show Dashboard
    List<Widget> pages = [const DashboardView()];
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2), label: 'Trang chủ'),
    ];

    if (userVM.canSell) {
      pages.add(const PosView());
      items.add(const BottomNavigationBarItem(icon: Icon(CupertinoIcons.barcode_viewfinder), label: 'Bán hàng'));
    }

    // Role 2 can view products (just no edit/add buttons inside)
    pages.add(const ProductManagementView());
    items.add(const BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box), label: 'Sản phẩm'));

    if (userVM.canManageStaff) {
      pages.add(const StaffManagementView());
      items.add(const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_3), label: 'Nhân viên'));
    }

    pages.add(const MoreMenuView());
    items.add(const BottomNavigationBarItem(icon: Icon(CupertinoIcons.ellipsis), label: 'Mở rộng'));

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00288E), // AppTheme.primary
        unselectedItemColor: const Color(0xFF757684), // AppTheme.textSecondary
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (pages[index] is PosView) {
            context.read<PosViewModel>().loadProducts();
          }
        },
        items: items,
      ),
    );
  }
}
