import 'package:arianth/screens/admin/ui/admin_view.dart';
import 'package:arianth/screens/business_partner_list/ui/business_partner_list.dart';
import 'package:arianth/screens/buyer/ui/buyers_screen.dart';
import 'package:arianth/screens/catelogue/ui/catelogue_main_screen.dart';
import 'package:arianth/screens/craftsman/ui/craftsman_screen.dart';
import 'package:arianth/screens/dashboard_screen/ui/dashboard_screen.dart';
import 'package:arianth/screens/designs/ui/designs_screen.dart';
import 'package:arianth/screens/designs/ui/designs_screen.dart';
import 'package:arianth/screens/key_user/ui/key_users_screen.dart';
import 'package:arianth/screens/kyc_pending/ui/kyc_pending_screen.dart';
import 'package:arianth/screens/main_screen/menu_notifier.dart';
import 'package:arianth/screens/main_screen/sidebar.dart';
import 'package:arianth/screens/finance_dashboard/ui/finance_dashboard_screen.dart';
import 'package:arianth/screens/products/ui/products_screen.dart';
import 'package:arianth/screens/purchase_order/ui/purchase_order_screen.dart';
import 'package:arianth/screens/user/ui/users_screen.dart';
import 'package:arianth/screens/work_orders/ui/work_orders_screen.dart';
import 'package:arianth/screens/contact_us/ui/contact_us_screen.dart';
import 'package:arianth/screens/repairs/ui/repairs_screen.dart';
import 'package:arianth/screens/my_profile/ui/my_profile_screen.dart';
import 'package:arianth/screens/my_favorites/ui/my_favorites_screen.dart';
import 'package:arianth/screens/live_stock_order/ui/live_stock_order.dart';
import 'package:arianth/screens/chat/ui/chat_list_screen.dart';
import 'package:arianth/screens/meetings/ui/meetings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final menuIndexProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final double mobileBreakpoint = 768;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  final List<Widget> _screens = const [
    DashboardScreen(),
    BusinessPartnersScreen(),
    BuyerScreen(),
    CraftsmanScreen(),
    AdminScreen(),
    KeyUsersScreen(),
    UsersScreen(),
    WorkOrdersScreen(),
    PurchaseOrderScreen(),
    ProductsScreen(),
    DesignsScreen(),
    CatalogueScreen(),
    KycPendingScreen(),
    FinanceDashboardScreen(),
    ContactUsScreen(),
    RepairsScreen(),
    MyProfileScreen(), // Index 16
    MyFavoritesScreen(), // Index 17
    LiveStockOrder(), // Index 18
    ChatListScreen(), // Index 19
    MeetingsScreen(), // Index 20
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < mobileBreakpoint;
    final index = ref.watch(menuIndexProvider);

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If drawer is open, close it
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // Otherwise move to dashboard
        ref.read(menuIndexProvider.notifier).state = 0;
      },
      child: Scaffold(
        key: _scaffoldKey,
      drawer: isMobile ? const Drawer(child: Sidebar()) : null,
      body: Row(
        children: [
          if (!isMobile) const Sidebar(),
          Expanded(child: _screens[index < _screens.length ? index : 0]),
        ],
      ),
    ));
  }
}

