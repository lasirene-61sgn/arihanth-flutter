import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/dashboard_screen/model/dashboard_model.dart';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/login/riverpod/login_notifier.dart';
import 'package:arianth/screens/main_screen/main_layout.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arianth/services/localization/app_localization.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String currentScreen = 'Dashboard';
  late double h, w;
  String? role;
  String? name;
  bool _isRateExpanded = false;
  final String goldRate = "₹ 7,250 /g";
  final String silverRate = "₹ 92.50 /g";

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    name = SharedPreferencesHelper().getString("name") ?? '';
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).fetchDashBoard();
      ref.read(productListProvider.notifier).fetchBPCodes();
      ref.read(productListProvider.notifier).fetchCraftBPCodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    h = MediaQuery.of(context).size.height;
    w = MediaQuery.of(context).size.width;

    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;
    final dashboardState = ref.watch(dashboardProvider);
    final dashboardData = dashboardState.dashboardData;

    final summaryCards = _getSummaryCards(dashboardData);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white24,
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          ref.watchTr('dashboard'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.profile),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRateCard(),
            const SizedBox(height: 24),

            // Text(
            //   '${loginState.user?.role.substring(0).capitalizeFirst ?? role?.substring(0).capitalizeFirst} ${ref.watchTr('dashboard')}',
            //   style: const TextStyle(
            //     fontSize: 22,
            //     fontWeight: FontWeight.bold,
            //     color: AppColor.textPrimary,
            //   ),
            // ),
            // const SizedBox(height: 4),
            Text(
              '${ref.watchTr('welcome')}, ${loginState.user?.fullName ?? name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
            ),
            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: w < 600 ? 2 : (w < 1024 ? 3 : 4),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: w < 1024 ? 1.4 : 1.6,
              ),
              itemCount: summaryCards.length,
              itemBuilder: (context, index) => _buildSummaryCard(summaryCards[index]),
            ),
            const SizedBox(height: 10),



            SafeArea(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _handleLogout(context),
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: AppColor.textWhite, strokeWidth: 2),
                )
                    : const Icon(Icons.logout, size: 18, color: AppColor.textWhite),
                label: Text(
                  isLoading ? 'Signing out...' : ref.watchTr('logout'),
                  style: const TextStyle(color: AppColor.textWhite, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.textWhite,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildRateCard() {
    final dashboardState = ref.watch(dashboardProvider);
    final brandLogo = dashboardState.dashboardData?.brandLogoUrl;

    // 1. Super Admin View (Single Center Logo)
    if (role == "super_admin") {
      return Center(
        child: Image.asset(
          "assets/image/splash_screen_logo_without_bg.png",
          width: 200,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }

    // 2. Other Users View (Dual Logo in Circles)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left Logo (Local Asset)
          _buildCircularLogo(
            child: Image.asset("assets/image/tara_text_bg.png", fit: BoxFit.cover),
          ),

          // Middle Divider or Spacer (Optional)
          Container(
            height: 40,
            width: 1,
            color: AppColor.divider.withOpacity(0.5),
          ),

          // Right Logo (Network Brand Logo)
          _buildCircularLogo(
            isEmpty: brandLogo == null,
            child: brandLogo != null
                ? Image.network(
              brandLogo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.business, color: AppColor.primary),
            )
                : 
                Text("ADD YOUR LOGO",textAlign: TextAlign.center,style: TextStyle(
                  color: AppColor.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),)
          ),
        ],
      ),
    );
  }

  Widget _buildCircularLogo({required Widget child, bool isEmpty = false}) {
    return Container(
      width: 80,
      height: 80,
      // decoration: const BoxDecoration(
      //   color: Colors.transparent,
      //   shape: BoxShape.circle,
      // ),
      child: Center(child: child),
    );
  }


  Widget _buildSummaryCard(Map<String, dynamic> card) {
    return InkWell(
      onTap: () {
        int? targetIndex;
        final type = card['type'];
        if (type == 'partners') targetIndex = 1;
        else if (type == 'buyers') targetIndex = 2;
        else if (type == 'craftsman') targetIndex = 3;
        else if (type == 'admins') targetIndex = 4;
        else if (type == 'keyusers') targetIndex = 5;
        else if (type == 'users') targetIndex = 6;
        else if (type == 'work_orders') targetIndex = 7;
        else if (type == 'repairs') targetIndex = 15;
        else if (type == 'purchase_orders') targetIndex = 8;
        else if (type == 'products') targetIndex = 9;
        else if (type == 'designs') targetIndex = 10;
        else if (type == 'catalogue') targetIndex = 11;
        else if (type == 'kyc_pending') targetIndex = 12;
        else if (type == 'finance') targetIndex = 13;
        else if (type == 'stock_order') targetIndex = 18;
        else if (type == 'chat') targetIndex = 19;
        else if (type == 'meetings') targetIndex = 20;

        if (targetIndex != null) {
          ref.read(menuIndexProvider.notifier).state = targetIndex;
        } else if (card['route'] != null) {
          Get.toNamed(card['route']);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColor.divider,
                  child: card['icon'] is IconData
                      ? Icon(card['icon'], size: 18, color: AppColor.primary)
                      : Image.asset(card['icon'] as String, width: 18, color: AppColor.primary),
                ),
                Text(
                  card['count'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
              ],
            ),
            Text(
              card['title'],
              style: const TextStyle(fontSize: 12, color: AppColor.black, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.watchTr('confirm_logout')),
        content: Text(ref.watchTr('logout_message')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.watchTr('cancel'))),
          ElevatedButton(
            onPressed: () async{
             await ref.read(loginProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: Text(ref.watchTr('logout'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSummaryCards(DashboardModel? data) {
    final permissions = data?.permissions ?? [];
    final bool isSuperAdmin = role == 'super_admin';
    bool hasPermission(String perm) => isSuperAdmin || permissions.contains(perm);

    String getCount(int? count) => count?.toString() ?? '0';

    return [
      if (hasPermission('business_partner'))
        {'type': 'partners', 'icon': Icons.inventory_2_outlined, 'title': ref.watchTr('partners'), 'count': getCount(data?.businessPartner)},
      if (hasPermission('business_partner'))
        {'type': 'buyers', 'icon': Icons.shopping_cart_outlined, 'title': ref.watchTr('buyers'), 'count': getCount(data?.buyers)},
      if (hasPermission('business_partner'))
        {'type': 'craftsman', 'icon': Icons.build_circle_outlined, 'title': ref.watchTr('craftsman'), 'count': getCount(data?.craftsmans)},
      if (isSuperAdmin)
        {'type': 'admins', 'icon': Icons.admin_panel_settings_outlined, 'title': ref.watchTr('Admins'), 'count': getCount(data?.admin)},
      if (hasPermission('key_user'))
        {'type': 'keyusers', 'icon': Icons.supervisor_account_outlined, 'title': ref.watchTr('Keyusers'), 'count': getCount(data?.keyUser)},
      if (hasPermission('user_management'))
        {'type': 'users', 'icon': Icons.group_add_outlined, 'title': ref.watchTr('Users'), 'count': getCount(data?.user)},

      if (hasPermission('work_order') || hasPermission('workorder'))
        {'type': 'work_orders', 'icon': Icons.work_outline_outlined, 'title': ref.watchTr('work_orders'), 'count': getCount(data?.workOrders)},

      if (isSuperAdmin || role == 'buyer' || role == 'craftsman')
        {'type': 'repairs', 'icon': Icons.handyman_outlined, 'title': ref.watchTr('repairs'), 'count': getCount(data?.repairs)},

      if (hasPermission('purchase_order'))
        {'type': 'purchase_orders', 'icon': Icons.receipt_long_outlined, 'title': ref.watchTr('purchase_orders'), 'count': getCount(data?.purchaseOrder)},

      if (hasPermission('product'))
        {'type': 'products', 'icon': Icons.category_outlined, 'title': ref.watchTr('products'), 'count': getCount(data?.products)},

      if (hasPermission('design'))
        {'type': 'designs', 'icon': Icons.auto_awesome_outlined, 'title': ref.watchTr('designs'), 'count': getCount(data?.designs)},

      if (hasPermission('catalogue'))
        {'type': 'catalogue', 'icon': Icons.menu_book_outlined, 'title': ref.watchTr('catalogue'), 'count': getCount(data?.catalogues)},
      if (hasPermission('finance'))
        {'type': 'finance', 'icon': Icons.analytics_outlined, 'title': 'Finance', 'count': ''},
      if (hasPermission('kyc_pending'))
        {'type': 'kyc_pending', 'icon': Icons.verified_user_outlined, 'title': ref.watchTr('kyc_pending'), 'count': getCount(data?.businessPartnerKyc)},
      if (hasPermission('stock_order'))
        {'type': 'stock_order', 'icon': Icons.list_alt_outlined, 'title': 'Live Stock Order', 'count': ''},
      {'type': 'chat', 'icon': Icons.chat_outlined, 'title': 'Chat', 'count': ''},
      if (hasPermission('meetings'))
        {'type': 'meetings', 'icon': Icons.video_call_outlined, 'title': 'Meetings', 'count': ''},
    ];
  }

  final List<Map<String, String>> jewelryLinks = [
    {"title": "Gold Rate Today", "url": "https://arihanthjewellers.com/"},
    {"title": "Gst Verify", "url": "https://services.gst.gov.in/services/searchtp"},
  ];
}
