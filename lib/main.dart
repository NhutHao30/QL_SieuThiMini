import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'views/main_layout.dart';
import 'views/login_view.dart';

import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/staff_viewmodel.dart';
import 'viewmodels/customer_viewmodel.dart';
import 'viewmodels/invoice_viewmodel.dart';
import 'viewmodels/pos_viewmodel.dart';
import 'viewmodels/log_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bdzvjxsymdwvxkrdnopj.supabase.co',
    anonKey: 'sb_publishable_9OHzKxRCgOLTHMDS5hD59w_GfvOhN1t',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => StaffViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvoiceViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => PosViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => LogViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(),
        ),
        ChangeNotifierProxyProvider<UserViewModel, ChatViewModel>(
          create: (context) => ChatViewModel(),
          update: (context, userVM, chatVM) {
            final vm = chatVM ?? ChatViewModel();
            vm.updateUser(userVM);
            return vm;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QL Siêu Thị Mini',
        theme: AppTheme.lightTheme,
        home: const LoginView(),
      ),
    );
  }
}