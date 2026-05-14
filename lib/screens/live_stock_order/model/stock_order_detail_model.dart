import 'package:flutter/foundation.dart';

class StockOrderDetailBuyer {
  final int? id;
  final String? bpCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? email;
  final String? gstNo;
  final String? city;
  final String? state;

  StockOrderDetailBuyer({
    this.id,
    this.bpCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
    this.gstNo,
    this.city,
    this.state,
  });

  factory StockOrderDetailBuyer.fromJson(Map<String, dynamic> json) {
    try {
      return StockOrderDetailBuyer(
        id: json['id'] as int?,
        bpCode: json['bp_code']?.toString(),
        businessName: json['business_name']?.toString(),
        name: json['name']?.toString(),
        mobile: json['mobile']?.toString(),
        email: json['email']?.toString(),
        gstNo: json['gst_no']?.toString(),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing StockOrderDetailBuyer: $e');
      return StockOrderDetailBuyer();
    }
  }

  StockOrderDetailBuyer copyWith({
    int? id,
    String? bpCode,
    String? businessName,
    String? name,
    String? mobile,
    String? email,
    String? gstNo,
    String? city,
    String? state,
  }) {
    return StockOrderDetailBuyer(
      id: id ?? this.id,
      bpCode: bpCode ?? this.bpCode,
      businessName: businessName ?? this.businessName,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      gstNo: gstNo ?? this.gstNo,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    if (name != null && name!.isNotEmpty) return name!;
    return '';
  }
}

class StockOrderDetailCraftsman {
  final int? id;
  final String? craftmanCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? email;

  StockOrderDetailCraftsman({
    this.id,
    this.craftmanCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
  });

  factory StockOrderDetailCraftsman.fromJson(Map<String, dynamic> json) {
    try {
      return StockOrderDetailCraftsman(
        id: json['id'] as int?,
        craftmanCode: json['craftman_code']?.toString(),
        businessName: json['business_name']?.toString(),
        name: json['name']?.toString(),
        mobile: json['mobile']?.toString(),
        email: json['email']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing StockOrderDetailCraftsman: $e');
      return StockOrderDetailCraftsman();
    }
  }

  StockOrderDetailCraftsman copyWith({
    int? id,
    String? craftmanCode,
    String? businessName,
    String? name,
    String? mobile,
    String? email,
  }) {
    return StockOrderDetailCraftsman(
      id: id ?? this.id,
      craftmanCode: craftmanCode ?? this.craftmanCode,
      businessName: businessName ?? this.businessName,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
    );
  }

  String get displayName {
    if (businessName != null && businessName!.isNotEmpty) return businessName!;
    if (name != null && name!.isNotEmpty) return name!;
    return '';
  }
}

class StockOrderDetailModel {
  final int? id;
  final int? buyerId;
  final int? craftsmanId;
  final int? itemId;
  final int? productId;
  final String? orderNumber;
  final String? status;
  final int? totalItems;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String? designCode;
  final String? weightFrom;
  final String? weightTo;
  final String? size;
  final String? grams;
  final int? quantity;
  final String? itemStatus;
  final String? imageUrl;
  final StockOrderDetailBuyer? buyer;
  final StockOrderDetailCraftsman? craftsman;

  StockOrderDetailModel({
    this.id,
    this.buyerId,
    this.craftsmanId,
    this.itemId,
    this.productId,
    this.orderNumber,
    this.status,
    this.totalItems,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.designCode,
    this.weightFrom,
    this.weightTo,
    this.size,
    this.grams,
    this.quantity,
    this.itemStatus,
    this.imageUrl,
    this.buyer,
    this.craftsman,
  });

  factory StockOrderDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return StockOrderDetailModel(
        id: json['id'] as int?,
        buyerId: json['buyer_id'] as int?,
        craftsmanId: json['craftsman_id'] as int?,
        itemId: json['item_id'] as int?,
        productId: json['product_id'] as int?,
        orderNumber: json['order_number']?.toString(),
        status: json['status']?.toString(),
        totalItems: json['total_items'] is int
            ? json['total_items'] as int
            : int.tryParse(json['total_items']?.toString() ?? ''),
        notes: json['notes']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        designCode: json['design_code']?.toString(),
        weightFrom: json['weight_from']?.toString(),
        weightTo: json['weight_to']?.toString(),
        size: json['size']?.toString(),
        grams: json['grams']?.toString(),
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? ''),
        itemStatus: json['item_status']?.toString(),
        imageUrl: json['image_url']?.toString(),
        buyer: json['buyer'] is Map<String, dynamic>
            ? StockOrderDetailBuyer.fromJson(json['buyer'] as Map<String, dynamic>)
            : null,
        craftsman: json['craftsman'] is Map<String, dynamic>
            ? StockOrderDetailCraftsman.fromJson(json['craftsman'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing StockOrderDetailModel: $e');
      return StockOrderDetailModel();
    }
  }

  StockOrderDetailModel copyWith({
    int? id,
    int? buyerId,
    int? craftsmanId,
    int? itemId,
    int? productId,
    String? orderNumber,
    String? status,
    int? totalItems,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? designCode,
    String? weightFrom,
    String? weightTo,
    String? size,
    String? grams,
    int? quantity,
    String? itemStatus,
    String? imageUrl,
    StockOrderDetailBuyer? buyer,
    StockOrderDetailCraftsman? craftsman,
  }) {
    return StockOrderDetailModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      craftsmanId: craftsmanId ?? this.craftsmanId,
      itemId: itemId ?? this.itemId,
      productId: productId ?? this.productId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      designCode: designCode ?? this.designCode,
      weightFrom: weightFrom ?? this.weightFrom,
      weightTo: weightTo ?? this.weightTo,
      size: size ?? this.size,
      grams: grams ?? this.grams,
      quantity: quantity ?? this.quantity,
      itemStatus: itemStatus ?? this.itemStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      buyer: buyer ?? this.buyer,
      craftsman: craftsman ?? this.craftsman,
    );
  }

  /// Computed total weight: grams × quantity
  String get totalWeightDisplay {
    final g = double.tryParse(grams ?? '') ?? 0;
    final q = quantity ?? 1;
    final total = g * q;
    if (total == total.truncateToDouble()) return '${total.toInt()} gm';
    return '${total.toStringAsFixed(3)} gm';
  }

  bool get hasSize =>
      size != null && size!.isNotEmpty && size != 'N/A' && size != 'null';
}
