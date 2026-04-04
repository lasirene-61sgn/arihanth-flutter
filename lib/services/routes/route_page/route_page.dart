import 'package:arianth/screens/admin/ui/add_admin_screen.dart';
import 'package:arianth/screens/admin/ui/admin_details_screen.dart';
import 'package:arianth/screens/admin/ui/admin_view.dart';
import 'package:arianth/screens/buyer/ui/buyer_creation_form/buyer_creation_form.dart';
import 'package:arianth/screens/buyer/ui/buyer_details_screen.dart';
import 'package:arianth/screens/buyer/ui/buyers_screen.dart';
import 'package:arianth/screens/craftsman/ui/craftman_create_form/craftman_create_form.dart';
import 'package:arianth/screens/craftsman/ui/craftman_details_screen.dart';
import 'package:arianth/screens/craftsman/ui/craftsman_screen.dart';
import 'package:arianth/screens/catelogue/ui/catalogue_detail_screen.dart';
import 'package:arianth/screens/designs/ui/design_details_screen.dart';
import 'package:arianth/screens/designs/ui/designs_screen.dart';
import 'package:arianth/screens/key_user/ui/add_keyuser_screen.dart';
import 'package:arianth/screens/key_user/ui/key_users_screen.dart';
import 'package:arianth/screens/kyc_pending/ui/kyc_pending_screen.dart';
import 'package:arianth/screens/finance_dashboard/ui/finance_dashboard_screen.dart';
import 'package:arianth/screens/products/ui/product_details_screen.dart';
import 'package:arianth/screens/products/ui/products_screen.dart';
import 'package:arianth/screens/products/widgets/product_form.dart';
import 'package:arianth/screens/purchase_order/ui/purchase_details_screen.dart';
import 'package:arianth/screens/purchase_order/ui/purchase_order_form.dart';
import 'package:arianth/screens/purchase_order/ui/purchase_order_screen.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/screens/user/ui/user_form_screen.dart';
import 'package:arianth/screens/user/ui/users_screen.dart';
import 'package:arianth/screens/user/ui/widget/user_details_screen.dart';
import 'package:arianth/screens/work_orders/ui/work_order_form.dart';
import 'package:arianth/screens/work_orders/ui/work_orders_screen.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_details_screen.dart';
import 'package:arianth/screens/profile/ui/profile_screen.dart';
import 'package:arianth/screens/common/order_success_screen.dart';
import 'package:get/get.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';

// Import all your screen files here
import 'package:arianth/screens/login/ui/forgot_password_screen.dart';
import 'package:arianth/screens/login/ui/login.dart';
import 'package:arianth/screens/main_screen/main_layout.dart';
import 'package:arianth/screens/dashboard_screen/ui/dashboard_screen.dart';
import 'package:arianth/screens/business_partner_list/ui/business_partner_list.dart';

// Repairs
import 'package:arianth/screens/repairs/ui/repairs_screen.dart';
import 'package:arianth/screens/repairs/ui/repair_details_screen.dart';
import 'package:arianth/screens/repairs/ui/repair_form_screen.dart';
// ... import other screens (Buyers, Products, KYC, etc.)

class AppPages {
  static final routes = [
    // --- Auth & Core ---
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),


    // --- Home / Layout (The shell for Sidebar navigation) ---
    GetPage(
      name: AppRoutes.home,
      page: () => const MainLayout(),
      transition: Transition.cupertino,
    ),

    // --- Sidebar / Main Modules ---
    // Note: These usually render inside MainLayout, but defined here for direct navigation
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: AppRoutes.workOrders, page: () => const WorkOrdersScreen()),
    GetPage(name: AppRoutes.workOrdersAdd, page: () => WorkOrderForm(id: Get.arguments as String?,)),
    GetPage(name: AppRoutes.workOrdersDetails, page: () => WorkOrderDetailsScreen(workOrderId: Get.arguments as String?)),
    GetPage(name: AppRoutes.buyers, page: () => const BuyerScreen()), // Replace with BuyersScreen()
    GetPage(name: AppRoutes.buyersAdd, page: () => const BPCreationForm()), // Replace with BuyersScreen()
    GetPage(name: AppRoutes.buyersDetails, page: () => const BuyerDetailScreen()), // Replace with BuyersScreen()
    GetPage(name: AppRoutes.finance, page: () => const FinanceDashboardScreen()),

    // --- Business ---
    GetPage(name: AppRoutes.businessPartners, page: () => const BusinessPartnersScreen()),
    GetPage(name: AppRoutes.craftsman, page: () => const CraftsmanScreen()),
    GetPage(name: AppRoutes.craftsmanAdd, page: () => const CraftManCreationForm()),
    GetPage(name: AppRoutes.craftsmanView, page: () => const CraftsmanDetailScreen()),
    GetPage(name: AppRoutes.admin, page: () => const AdminScreen()),
    GetPage(name: AppRoutes.addAdmin, page: () => const AddAdminScreen()),
    GetPage(name: AppRoutes.adminView, page: () => AdminDetailsScreen(adminId: Get.arguments as String?)),
    GetPage(name: AppRoutes.keyUsers, page: () => const KeyUsersScreen()),
    GetPage(name: AppRoutes.keyUsersAdd, page: () {
      final args = Get.arguments as Map<String, dynamic>?;
      return KeyUserFormScreen(id: args?['id']);
    }
  ),
    GetPage(name: AppRoutes.keyUsersView, page: () => const UserDetailsViewScreen(screenName: "Key Users")),
    GetPage(name: AppRoutes.users, page: () => const UsersScreen()),
    GetPage(name: AppRoutes.usersAdd, page: () => const UserFormScreen()),
    GetPage(name: AppRoutes.usersView, page: () => const UserDetailsViewScreen(screenName: "Users")),

    // --- Products / Catalogue ---
    GetPage(name: AppRoutes.products, page: () => const ProductsScreen()),
    // Inside your route setup (e.g., GetMaterialApp or route list)
    GetPage(
      name: AppRoutes.productsAdd,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;

        return CreateProductForm(
          productId: args?['id'],
          type: args?['type'],
          onClose: () => Get.back(),
          onCreate: () {
            Get.back();
          },
        );
      },
    ),
    GetPage(name: AppRoutes.productsDetails, page: () => ProductDetailsViewScreen(productId: Get.arguments as String)),
    GetPage(name: AppRoutes.designs, page: () => const DesignsScreen()),
    GetPage(
      name: AppRoutes.designsDetails,
      page: () {
        final selectedId = Get.arguments as String?;
        return DesignDetailsScreen(designId: selectedId);
      },
    ),
    GetPage(name: AppRoutes.catalogueDetails, page: () {
        final selectedId = Get.arguments as String?;
        return CatalogueDetailScreen(catalogueId: selectedId);
      },
    ),

    // --- Orders ---
    GetPage(name: AppRoutes.purchaseOrder, page: () => const PurchaseOrderScreen()),
    GetPage(name: AppRoutes.purchaseOrderAdd, page: () => PurchaseOrderForm(purchaseId: Get.arguments as String?)),
    GetPage(name: AppRoutes.purchaseOrderDetails, page: () => PurchaseOrderDetailScreen(purchaseId: Get.arguments as String? ?? "")),

    // --- Repairs ---
    GetPage(name: AppRoutes.repairs, page: () => const RepairsScreen()),
    GetPage(
      name: AppRoutes.repairsAdd, 
      page: () => RepairFormScreen(repairId: Get.arguments?.toString()),
    ),
    GetPage(name: AppRoutes.repairsDetails, page: () => RepairDetailsScreen(repairId: Get.arguments as String)),

    // --- KYC ---
    // GetPage(name: AppRoutes.kyc, page: () => const KycScreen()),
    GetPage(name: AppRoutes.kycPending, page: () => const KycPendingScreen()),
    GetPage(
      name: AppRoutes.orderSuccess,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return OrderSuccessScreen(
          orderNo: args['orderNo'] ?? '',
          orderType: args['orderType'] ?? '',
          onBack: args['onBack'] ?? () => Get.back(),
        );
      },
      transition: Transition.cupertino,
    ),
  ];
}