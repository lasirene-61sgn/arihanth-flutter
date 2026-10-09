class ReportModel {
  final List<TopPicksCraftsman> topPicksCraftsman;
  final List<TopPicksClient> topPicksClient;
  final List<OverallDesigns> overallDesigns;
  final List<Favorite> craftsmanFavorites;
  final List<Favorite> buyerFavorites;

  ReportModel({
    this.topPicksCraftsman = const [],
    this.topPicksClient = const [],
    this.overallDesigns = const [],
    this.craftsmanFavorites = const [],
    this.buyerFavorites = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      topPicksCraftsman: (json['top_picks_craftsman'] as List<dynamic>?)
              ?.map((e) => TopPicksCraftsman.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topPicksClient: (json['top_picks_client'] as List<dynamic>?)
              ?.map((e) => TopPicksClient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallDesigns: (json['overall_designs'] as List<dynamic>?)
              ?.map((e) => OverallDesigns.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      craftsmanFavorites: (json['craftsman_favorites'] as List<dynamic>?)
              ?.map((e) => Favorite.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      buyerFavorites: (json['buyer_favorites'] as List<dynamic>?)
              ?.map((e) => Favorite.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TopPicksCraftsman {
  final String code;
  final String name;
  final int allocated;
  final int completed;
  final int inProcess;
  final int forApproval;
  final num totalWeight;
  final num waTotalWeight;
  final num poTotalWeight;
  final num totalAmount;
  final int overdue;
  final WoDetails? wo;
  final WoDetails? po;

  TopPicksCraftsman({
    this.code = '',
    this.name = '',
    this.allocated = 0,
    this.completed = 0,
    this.inProcess = 0,
    this.forApproval = 0,
    this.totalWeight = 0,
    this.waTotalWeight = 0,
    this.poTotalWeight = 0,
    this.totalAmount = 0,
    this.overdue = 0,
    this.wo,
    this.po,
  });

  factory TopPicksCraftsman.fromJson(Map<String, dynamic> json) {
    return TopPicksCraftsman(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      allocated: json['allocated'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      inProcess: json['in_process'] as int? ?? 0,
      forApproval: json['for_approval'] as int? ?? 0,
      totalWeight: json['total_weight'] as num? ?? 0,
      waTotalWeight: json['wa_total_weight'] as num? ?? 0,
      poTotalWeight: json['po_total_weight'] as num? ?? 0,
      totalAmount: json['total_amount'] as num? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      wo: json['wo'] != null ? WoDetails.fromJson(json['wo']) : null,
      po: json['po'] != null ? WoDetails.fromJson(json['po']) : null,
    );
  }
}

class TopPicksClient {
  final String name;
  final int orders;
  final OrderGroup? newOrders;
  final OrderGroup? inProcess;
  final OrderGroup? forApproval;
  final OrderGroup? overdue;
  final OrderGroup? completed;
  final OrderGroup? rejected;

  TopPicksClient({
    this.name = '',
    this.orders = 0,
    this.newOrders,
    this.inProcess,
    this.forApproval,
    this.overdue,
    this.completed,
    this.rejected,
  });

  factory TopPicksClient.fromJson(Map<String, dynamic> json) {
    return TopPicksClient(
      name: json['name']?.toString() ?? '',
      orders: json['orders'] as int? ?? 0,
      newOrders: json['new'] != null ? OrderGroup.fromJson(json['new']) : null,
      inProcess: json['in_process'] != null ? OrderGroup.fromJson(json['in_process']) : null,
      forApproval: json['for_approval'] != null ? OrderGroup.fromJson(json['for_approval']) : null,
      overdue: json['overdue'] != null ? OrderGroup.fromJson(json['overdue']) : null,
      completed: json['completed'] != null ? OrderGroup.fromJson(json['completed']) : null,
      rejected: json['rejected'] != null ? OrderGroup.fromJson(json['rejected']) : null,
    );
  }
}

class WoDetails {
  final OrderGroup? newOrders;
  final OrderGroup? allocated;
  final OrderGroup? inProcess;
  final OrderGroup? completed;
  final OrderGroup? overdue;
  final OrderGroup? forApproval;

  WoDetails({
    this.newOrders,
    this.allocated,
    this.inProcess,
    this.completed,
    this.overdue,
    this.forApproval,
  });

  factory WoDetails.fromJson(Map<String, dynamic> json) {
    return WoDetails(
      newOrders: json['new'] != null ? OrderGroup.fromJson(json['new']) : null,
      allocated: json['allocated'] != null ? OrderGroup.fromJson(json['allocated']) : null,
      inProcess: json['in_process'] != null ? OrderGroup.fromJson(json['in_process']) : null,
      completed: json['completed'] != null ? OrderGroup.fromJson(json['completed']) : null,
      overdue: json['overdue'] != null ? OrderGroup.fromJson(json['overdue']) : null,
      forApproval: json['for_approval'] != null ? OrderGroup.fromJson(json['for_approval']) : null,
    );
  }
}

class OrderGroup {
  final int count;
  final num weight;
  final List<Order> orders;

  OrderGroup({
    this.count = 0,
    this.weight = 0,
    this.orders = const [],
  });

  factory OrderGroup.fromJson(Map<String, dynamic> json) {
    return OrderGroup(
      count: json['count'] as int? ?? 0,
      weight: json['weight'] as num? ?? 0,
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Order {
  final String number;
  final String qty;
  final num weight;
  final String bpCode;
  final String businessName;
  final String craftsmanCode;
  final String craftsmanName;
  final String dueDate;
  final int overdueDays;

  Order({
    this.number = '',
    this.qty = '',
    this.weight = 0,
    this.bpCode = '',
    this.businessName = '',
    this.craftsmanCode = '',
    this.craftsmanName = '',
    this.dueDate = '',
    this.overdueDays = 0,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      number: json['number']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      weight: json['weight'] as num? ?? 0,
      bpCode: json['bp_code']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      craftsmanCode: json['craftsman_code']?.toString() ?? '',
      craftsmanName: json['craftsman_name']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      overdueDays: json['overdue_days'] as int? ?? 0,
    );
  }
}

class OverallDesigns {
  final String category;
  final int count;
  final List<Product> products;

  OverallDesigns({
    this.category = '',
    this.count = 0,
    this.products = const [],
  });

  factory OverallDesigns.fromJson(Map<String, dynamic> json) {
    return OverallDesigns(
      category: json['category']?.toString() ?? '',
      count: json['count'] as int? ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Favorite {
  final String name;
  final String code;
  final int userId;
  final Map<String, FavoriteCategory> categories;

  Favorite({
    this.name = '',
    this.code = '',
    this.userId = 0,
    this.categories = const {},
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    final Map<String, FavoriteCategory> parsedCategories = {};
    if (json['categories'] is Map<String, dynamic>) {
      (json['categories'] as Map<String, dynamic>).forEach((key, value) {
        parsedCategories[key] = FavoriteCategory.fromJson(value as Map<String, dynamic>);
      });
    }

    return Favorite(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      userId: json['user_id'] as int? ?? 0,
      categories: parsedCategories,
    );
  }
}

class FavoriteCategory {
  final int count;
  final List<Product> products;

  FavoriteCategory({
    this.count = 0,
    this.products = const [],
  });

  factory FavoriteCategory.fromJson(Map<String, dynamic> json) {
    return FavoriteCategory(
      count: json['count'] as int? ?? 0,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Product {
  final String designCode;
  final String name;
  final num weightFrom;
  final num weightTo;
  final String? imageUrl;

  Product({
    this.designCode = '',
    this.name = '',
    this.weightFrom = 0,
    this.weightTo = 0,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      designCode: json['design_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      weightFrom: json['weight_from'] as num? ?? 0,
      weightTo: json['weight_to'] as num? ?? 0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}
