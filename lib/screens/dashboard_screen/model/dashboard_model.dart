import 'dart:convert';

class DashboardModel {
  final int businessPartner;
  final int businessPartnerKyc;
  final int buyers;
  final int craftsmans;
  final int admin;
  final int keyUser;
  final int user;
  final int workOrders;
  final int purchaseOrder;
  final int products;
  final int designs;
  final int catalogues;
  final int financeTotal;
  final int repairs;
  final List<String> permissions;
  final String? brandLogoUrl; // ✅ Added

  const DashboardModel({
    required this.businessPartner,
    required this.businessPartnerKyc,
    required this.buyers,
    required this.craftsmans,
    required this.admin,
    required this.keyUser,
    required this.user,
    required this.workOrders,
    required this.purchaseOrder,
    required this.products,
    required this.designs,
    required this.catalogues,
    required this.financeTotal,
    required this.repairs,
    required this.permissions,
    this.brandLogoUrl, // ✅ Added
  });

  DashboardModel copyWith({
    int? businessPartner,
    int? businessPartnerKyc,
    int? buyers,
    int? craftsmans,
    int? admin,
    int? keyUser,
    int? user,
    int? workOrders,
    int? purchaseOrder,
    int? products,
    int? designs,
    int? catalogues,
    int? financeTotal,
    int? repairs,
    List<String>? permissions,
    String? brandLogoUrl, // ✅ Added
  }) {
    return DashboardModel(
      businessPartner: businessPartner ?? this.businessPartner,
      businessPartnerKyc: businessPartnerKyc ?? this.businessPartnerKyc,
      buyers: buyers ?? this.buyers,
      craftsmans: craftsmans ?? this.craftsmans,
      admin: admin ?? this.admin,
      keyUser: keyUser ?? this.keyUser,
      user: user ?? this.user,
      workOrders: workOrders ?? this.workOrders,
      purchaseOrder: purchaseOrder ?? this.purchaseOrder,
      products: products ?? this.products,
      designs: designs ?? this.designs,
      catalogues: catalogues ?? this.catalogues,
      financeTotal: financeTotal ?? this.financeTotal,
      repairs: repairs ?? this.repairs,
      permissions: permissions ?? this.permissions,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl, // ✅ Added
    );
  }

  factory DashboardModel.fromJson(Map<String, dynamic>? json) {
    final innerData = json?['data'] ?? {};

    return DashboardModel(
      businessPartner: toInt(innerData['totalBusinessPartners']),
      businessPartnerKyc: toInt(innerData['pendingKycCount']),
      buyers: toInt(innerData['totalBuyers']),
      craftsmans: toInt(innerData['totalCraftsmen']),
      admin: toInt(innerData['totalAdmins']),
      keyUser: toInt(innerData['totalKeyUsers']),
      user: toInt(innerData['totalUsers']),
      workOrders: toInt(innerData['totalWorkOrders']),
      purchaseOrder: toInt(innerData['totalPurchaseOrders']),
      products: toInt(innerData['totalProducts']),
      designs: toInt(innerData['totalDesigns']),
      catalogues: toInt(innerData['totalCatalogues']),
      repairs: toInt(innerData['totalRepairs']),
      financeTotal: toInt(innerData['financeTotal']),
      brandLogoUrl: innerData['brand_logo_url']?.toString(), // ✅ Added
      permissions: innerData['permissions'] == null
          ? []
          : innerData['permissions'] is String
          ? List<String>.from(jsonDecode(innerData['permissions']))
          : List<String>.from(innerData['permissions']),
    );
  }

  @override
  String toString() {
    return '''
DashboardModel(
  businessPartner: $businessPartner,
  businessPartnerKyc: $businessPartnerKyc,
  buyers: $buyers,
  craftsmans: $craftsmans,
  admin: $admin,
  keyUser: $keyUser,
  user: $user,
  workOrders: $workOrders,
  purchaseOrder: $purchaseOrder,
  products: $products,
  designs: $designs,
  catalogues: $catalogues,
  repairs: $repairs,
  financeTotal: $financeTotal,
  brandLogoUrl: $brandLogoUrl,
  permissions: $permissions
)
''';
  }
}

int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}