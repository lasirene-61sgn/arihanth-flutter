class AppRoutes {
  // Core / Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String forgotPassword = '/forget-password';
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Home / Layout
  static const String home = '/home';
  static const String mainLayout = '/mainLayout';
  static const String dashboard = '/';

  // Sidebar / Main Modules
  static const String workOrders = '/work-orders';
  static const String workOrdersAdd = '/work-orders/add';
  static const String workOrdersDetails = '/work-orders/details';
  static const String quickOrders = '/quick-orders';
  static const String buyers = '/buyers';
  static const String buyersAdd = '/buyers/Add';
  static const String buyersDetails = '/buyers/Details';
  static const String users = '/users';
  static const String usersAdd = '/users/add';
  static const String settings = '/settings';
  static const String finance = '/finance';

  // Business
  static const String businessPartners = '/business-partners';
  static const String craftsman = '/craftsman';
  static const String craftsmanAdd = '/craftsman/add';
  static const String craftsmanView = '/craftsman/view';
  static const String admin = '/admin';
  static const String addAdmin = '/admin/add';
  static const String adminView = '/admin/view';
  static const String keyUsers = '/key-users';
  static const String keyUsersAdd = '/key-users/add';
  static const String keyUsersKyc = '/keyUsersKyc';

  // Products / Catalogue
  static const String products = '/products';
  static const String productsAdd = '/products/add';
  static const String productsDetails = '/products/details';
  static const String designs = '/designs';
  static const String designsDetails = '/designs/details';
  static const String myCatalogue = '/my-catalogue';
  static const String catalogueDetails = '/my-catalogue/details';


  // Orders
  static const String purchaseOrder = '/purchase-order';
  static const String purchaseOrderAdd = '/purchase-order/add';
  static const String purchaseOrderDetails = '/purchase-order/details';
  static const String repairs = '/repairs';
  static const String repairsAdd = '/repairs/add';
  static const String repairsDetails = '/repairs/details';

  // Users
  static const String usersView = '/users/view';
  static const String keyUsersView = '/key-users/view';

  // KYC
  static const String kyc = '/kyc';
  static const String kycPending = '/kyc-pending';
  static const String favorites = '/favorites';
  static const String orderSuccess = '/order-success';
}
