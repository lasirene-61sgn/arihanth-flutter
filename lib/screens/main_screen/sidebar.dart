import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/login/riverpod/login_notifier.dart';
import 'package:arianth/screens/main_screen/main_layout.dart';
import 'package:arianth/screens/main_screen/menu_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';

import '../dashboard_screen/riverpod/dashboard_notifier.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  String? name, email;

  @override
  void initState() {
    super.initState();
    final prefs = SharedPreferencesHelper();
    name = prefs.getString("name") ?? '';
    email = prefs.getString("email") ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(menuIndexProvider);
    final loginState = ref.watch(loginProvider);
    final String displayName = (name != null && name!.isNotEmpty) ? name! : "User";

    return Drawer(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.sidebarColor, // 👈 Deep brand maroon
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: Column(
          children: [
            SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () {
                    Get.back(); // close drawer
                    Get.toNamed(AppRoutes.profile);
                  },
                  child: _buildProfileHeader(displayName, email),
                )),

            const Divider(indent: 20, endIndent: 20, height: 1),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: AppColor.primary),
                  textTheme: Theme.of(context).textTheme.apply(bodyColor: AppColor.primary),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  children: _buildMenuItems(context, selectedIndex),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                top: false,
                child: CustomButton(
                  text: ref.watchTr('logout'),
                  isLoading: loginState.isLoading,
                  onPressed: () => ref.read(loginProvider.notifier).logout(),
                  backgroundColor: AppColor.primary,
                  textColor: AppColor.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? email) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      margin: const EdgeInsets.symmetric(horizontal: 10,vertical: 0),
      decoration: BoxDecoration(
        color: AppColor.primary
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColor.white,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",
              style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                if (email != null)
                  Text(email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, int selectedIndex) {
    final loginState = ref.watch(loginProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final role = loginState.user?.role ?? SharedPreferencesHelper().getString("role") ?? '';
    final permissions = dashboardState.dashboardData?.permissions ?? [];
    final bool isSuperAdmin = role == 'super_admin';

    bool hasPermission(String perm) => isSuperAdmin || permissions.contains(perm);

    List<Widget> menu = [];

    // --- SECTION: GENERAL ---
    menu.add(_sectionTitle("GENERAL"));
    menu.add(_navItem(Icons.grid_view, ref.watchTr('dashboard'), 0, selectedIndex));
    if (role == 'buyer' || role == 'craftsman') {
      menu.add(_navItem(Icons.person_outline, ref.watchTr('my_profile'), 16, selectedIndex));
      if (permissions.contains('favorites')) {
        menu.add(_navItem(Icons.favorite_outline, ref.watchTr('my_favorites'), 17, selectedIndex));
      }
    }
    menu.add(const SizedBox(height: 15));

    // --- SECTION: BUSINESS ---
    bool hasBusinessPartner = hasPermission('business_partner');
    bool hasWorkOrder = hasPermission('work_order') || hasPermission('workorder');
    bool hasPurchaseOrder = hasPermission('purchase_order');
    bool hasProduct = hasPermission('product');
    bool hasDesign = hasPermission('design');
    bool hasCatalogue = hasPermission('catalogue');

    if (hasBusinessPartner || hasWorkOrder || hasPurchaseOrder || hasProduct || hasDesign || hasCatalogue) {
      menu.add(_sectionTitle("BUSINESS OPERATIONS"));

      if (hasBusinessPartner) {
        bool isBusinessActive = selectedIndex >= 1 && selectedIndex <= 3;
        menu.add(
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: AppColor.textSecondary,
            ),
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              initiallyExpanded: isBusinessActive,
              iconColor: AppColor.primary,
              collapsedIconColor: AppColor.textSecondary,
              leading: Icon(
                Icons.business_center_outlined,
                color: isBusinessActive ? AppColor.primary : AppColor.textSecondary,
              ),
              title: Text(
                ref.watchTr('business_partners'),
                style: TextStyle(
                  fontSize: 14,
                  color: isBusinessActive ? AppColor.primary : AppColor.textSecondary,
                  fontWeight: isBusinessActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 10),
              children: [
                _navItem(Icons.inventory_2_outlined, ref.watchTr('partners'), 1, selectedIndex),
                _navItem(Icons.shopping_cart_outlined, ref.watchTr('buyers'), 2, selectedIndex),
                _navItem(Icons.build_circle_outlined, ref.watchTr('craftsman'), 3, selectedIndex),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }

      if (hasWorkOrder) {
        menu.add(_navItem(Icons.work_outline_outlined, ref.watchTr('work_orders'), 7, selectedIndex));
      }
      // Add Repairs (default visible for all orders roles)
      if (isSuperAdmin || role == 'buyer' || role == 'craftsman') {
        menu.add(_navItem(Icons.handyman_outlined, ref.watchTr('repairs'), 15, selectedIndex));
      }
      if (hasPurchaseOrder) {
        menu.add(_navItem(Icons.receipt_long_outlined, ref.watchTr('purchase_orders'), 8, selectedIndex));
      }
      if (isSuperAdmin) {
        // Super Admin: Show Designs, Hide Products & Catalogue
        menu.add(_navItem(Icons.auto_awesome_outlined, ref.watchTr('designs'), 10, selectedIndex));
      } else {
        // Others: Show Catalogue, Hide Products & Designs
        if (hasCatalogue) {
          menu.add(_navItem(Icons.menu_book_outlined, ref.watchTr('catalogue'), 11, selectedIndex));
        }
      }

      menu.add(const SizedBox(height: 20));
    }

    // --- SECTION: ADMINISTRATION ---
    bool hasAdmin = isSuperAdmin;
    bool hasKeyUser = hasPermission('key_user');
    bool hasUser = hasPermission('user_management');

    if (hasAdmin || hasKeyUser || hasUser) {
      menu.add(_sectionTitle("ADMINISTRATION"));
      if (hasAdmin) {
        menu.add(_navItem(Icons.admin_panel_settings_outlined, ref.watchTr('Admins'), 4, selectedIndex));
      }
      if (hasKeyUser) {
        menu.add(_navItem(Icons.supervisor_account_outlined, ref.watchTr('Keyusers'), 5, selectedIndex));
      }
      if (hasUser) {
        menu.add(_navItem(Icons.group_add_outlined, ref.watchTr('Users'), 6, selectedIndex));
      }

      menu.add(const SizedBox(height: 20));
    }

    // --- SECTION: ACCOUNT CONTROL ---
    bool hasKYC = hasPermission('kyc_pending');

    if (hasKYC) {
      menu.add(_sectionTitle("ACCOUNT CONTROL"));
      if (hasKYC) {
        menu.add(_navItem(Icons.verified_user_outlined, ref.watchTr('kyc_pending'), 12, selectedIndex));
      }
      menu.add(const SizedBox(height: 20));
    }
    bool hasFinance = hasPermission('finance');
    if (hasFinance) {
      menu.add(_sectionTitle("FINANCE"));
      menu.add(_navItem(Icons.analytics_outlined, "Finance", 13, selectedIndex));
      menu.add(const SizedBox(height: 15));
    }

    // --- SECTION: SUPPORT ---
    menu.add(_sectionTitle("SUPPORT"));
    menu.add(_navItem(Icons.contact_support_outlined, "Contact Us", 14, selectedIndex));
    menu.add(const SizedBox(height: 20));

    return menu;
  }

  // Helper widget for the Titles
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10, top: 5),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColor.primary, // 👈 Muted white for section headers
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String title, int index, int selectedIndex) {
    final bool isActive = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          ref.read(menuIndexProvider.notifier).state = index;
          Get.back();
        },
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : AppColor.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColor.primary,
          ),
        ),
        trailing: isActive
            ? Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        )
            : null,
      ),
    );
  }
}