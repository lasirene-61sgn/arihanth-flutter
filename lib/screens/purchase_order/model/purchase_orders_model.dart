import '../../products/model/products_model.dart';
import '../../designs/model/designs_model.dart';

class PurchaseOrder {
  final int? id;
  final String? purchaseOrderCode;
  final String? dueDate;
  final String? notes;
  final String? status;
  final String? allocatedCraftsmanCode;
  final String? craftsmanStatus;
  final String? createdAt;
  final String? updatedAt;
  final String? totalWeight;
  final String? size;
  final String? colorKey;
  final String? colorHex;
  final List<PurchaseItem>? items;
  final List<dynamic>? rejectedItems;
  final List<SimplePurchaseItem>? itemsWithImageUrls;
  final List<dynamic>? rejectedItemsWithImageUrls;

  // Backward compatibility getters for UI and Notifier
  String? get orderNumber => purchaseOrderCode;
  String? get orderDate => createdAt;
  String? get note => notes;
  String? get bpCode => items != null && items!.isNotEmpty ? items!.first.product?.bpCode : null;

  List<String> get displayImageUrls {
    final Set<String> urls = {};

    // 1. Check items_with_image_urls (full URLs from API)
    if (itemsWithImageUrls != null) {
      for (var item in itemsWithImageUrls!) {
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
          urls.add(item.imageUrl!);
        }
      }
    }

    // 2. Check regular items
    if (items != null) {
      for (var item in items!) {
        final url = item.imageUrl;
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      }
    }

    return urls.toList();
  }

  PurchaseOrder({
    this.id,
    this.purchaseOrderCode,
    this.dueDate,
    this.notes,
    this.status,
    this.allocatedCraftsmanCode,
    this.craftsmanStatus,
    this.createdAt,
    this.updatedAt,
    this.totalWeight,
    this.size,
    this.colorKey,
    this.colorHex,
    this.items,
    this.rejectedItems,
    this.itemsWithImageUrls,
    this.rejectedItemsWithImageUrls,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    // Collect items first to use for fallback calculation
    final List<PurchaseItem>? parsedItems = json['items'] != null && json['items'] is List
        ? (json['items'] as List)
        .where((x) => x is Map<String, dynamic>)
        .map((x) => PurchaseItem.fromJson(x as Map<String, dynamic>))
        .toList()
        : null;

    // Try to get total_weight from root, otherwise calculate from items
    String? weightStr = json['total_weight']?.toString();
    if ((weightStr == null || weightStr == "null" || weightStr.isEmpty) && parsedItems != null) {
       double sum = 0;
       for (var item in parsedItems) {
         sum += (item.totalWeight ?? 0).toDouble();
       }
       if (sum > 0) weightStr = sum.toStringAsFixed(2);
    }

    return PurchaseOrder(
      id: json['id'],
      purchaseOrderCode: json['purchase_order_code']?.toString(),
      dueDate: json['due_date']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString(),
      allocatedCraftsmanCode: json['allocated_craftsman_code']?.toString(),
      craftsmanStatus: json['craftsman_status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      totalWeight: weightStr,
      size: json['size']?.toString(),
      colorKey: json['color_key']?.toString(),
      colorHex: json['color_hex']?.toString(),
      items: parsedItems,
      rejectedItems: json['rejected_items'] != null && json['rejected_items'] is List
          ? List<dynamic>.from(json['rejected_items'])
          : null,
      itemsWithImageUrls: json['items_with_image_urls'] != null && json['items_with_image_urls'] is List
          ? (json['items_with_image_urls'] as List)
          .where((x) => x is Map<String, dynamic>)
          .map((x) => SimplePurchaseItem.fromJson(x as Map<String, dynamic>))
          .toList()
          : null,
      rejectedItemsWithImageUrls: json['rejected_items_with_image_urls'] != null && json['rejected_items_with_image_urls'] is List
          ? List<dynamic>.from(json['rejected_items_with_image_urls'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'due_date': dueDate,
      'notes': notes,
      'items': items?.map((x) => x.toJson()).toList(),
    };
  }

  PurchaseOrder copyWith({
    int? id,
    String? purchaseOrderCode,
    String? dueDate,
    String? notes,
    String? status,
    String? allocatedCraftsmanCode,
    String? craftsmanStatus,
    String? createdAt,
    String? updatedAt,
    List<PurchaseItem>? items,
    List<dynamic>? rejectedItems,
    List<SimplePurchaseItem>? itemsWithImageUrls,
    List<dynamic>? rejectedItemsWithImageUrls,
    num? totalWeight,
    String? size,
    String? colorKey,
    String? colorHex,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      purchaseOrderCode: purchaseOrderCode ?? this.purchaseOrderCode,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      allocatedCraftsmanCode: allocatedCraftsmanCode ?? this.allocatedCraftsmanCode,
      craftsmanStatus: craftsmanStatus ?? this.craftsmanStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      rejectedItems: rejectedItems ?? this.rejectedItems,
      itemsWithImageUrls: itemsWithImageUrls ?? this.itemsWithImageUrls,
      rejectedItemsWithImageUrls: rejectedItemsWithImageUrls ?? this.rejectedItemsWithImageUrls,
      totalWeight: totalWeight != null
          ? totalWeight.toString()
          : this.totalWeight,
      size: size ?? this.size,
      colorKey: colorKey ?? this.colorKey,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

class PurchaseItem {
  final String? productId;
  final String? category;
  final String? subcategory;
  final String? itemNotes;
  final List<String>? grams;
  final List<String>? quantity;
  final num? total;
  final String? image;
  final String? status;
  final String? directImageUrl;
  final Product? product;
  final List<num>? individualTotals;
  final Design? designData;
  final String? designString; // Captures 'design' when it's a string
  final String? designCode;   // Captures 'design_code'
  final String? categoryName;
  final String? subcategoryName;
  final String? size;

  // Backward compatibility getters for UI
  int? get sNo => int.tryParse(productId ?? '0');
  String? get productCategory => categoryName ?? category;
  String? get subCategory => subcategoryName ?? subcategory;

  // UI expects List for join, but API wants String
  List<String> get design {
    final List<String> d = [];
    if (designData?.designCode != null && designData!.designCode!.isNotEmpty) d.add(designData!.designCode!);
    if (designString != null && designString!.isNotEmpty) d.add(designString!);
    if (designCode != null && designCode!.isNotEmpty) d.add(designCode!);
    return d.toSet().toList(); // returns unique values
  }
  String get designText => design.join(', ');

  num? get totalWeight => total;
  String? get notes => itemNotes;


  String? get imageUrl {
    if (directImageUrl != null && directImageUrl!.isNotEmpty) return directImageUrl;
    if (designData?.imageUrl != null) return designData!.imageUrl;
    if (product?.images != null && product!.images!.isNotEmpty) {
      return product!.images!.first.imageUrl;
    }

    if (image != null && (image!.startsWith('http') || image!.startsWith('https'))) {
      return image;
    }
    return null;
  }

  PurchaseItem({
    this.productId,
    this.category,
    this.subcategory,
    this.itemNotes,
    this.grams,
    this.quantity,
    this.total,
    this.image,
    this.status,
    this.directImageUrl,
    this.product,
    this.individualTotals,
    this.designData,
    this.designString,
    this.designCode,
    this.categoryName,
    this.subcategoryName,
    this.size,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    // Safely handle "design" field based on API structure changes
    Design? parsedDesign;
    String? parsedDesignString;

    if (json['design'] is Map<String, dynamic>) {
      parsedDesign = Design.fromJson(json['design']);
    } else if (json['design'] is String) {
      parsedDesignString = json['design'];
    }

    return PurchaseItem(
      productId: json['product_id']?.toString(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      itemNotes: json['item_notes']?.toString(), // FIX: 'notes' instead of 'item_notes'
      grams: json['grams'] != null ? List<String>.from(json['grams'].map((x) => x.toString())) : null,
      quantity: json['quantity'] != null ? List<String>.from(json['quantity'].map((x) => x.toString())) : null,
      total: json['total'] is String ? num.tryParse(json['total']) : json['total'],
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      directImageUrl: json['image_url']?.toString(),
      product: (json['product'] != null && json['product'] is Map<String, dynamic>)
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      individualTotals: (json['individual_totals'] != null && json['individual_totals'] is List)
          ? (json['individual_totals'] as List).map((x) => x is String ? (num.tryParse(x) ?? 0) : (x as num? ?? 0)).toList()
          : null,
      designData: parsedDesign,
      designString: parsedDesignString,
      designCode: json['design_code']?.toString(),
      categoryName: json['category_name']?.toString(),
      subcategoryName: json['subcategory_name']?.toString(),
      size: json['item_size']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': (productId == null || productId!.isEmpty) ? null : productId,
      'category': categoryName ?? category,
      'subcategory': subcategoryName ?? subcategory,
      'item_notes': itemNotes,
      'grams': grams,
      'quantity': quantity,
      'total_weight': total,
      'design_code': designText.isNotEmpty ? designText : null,
      'item_size': size,
    };
  }
}

// Added for items_with_image_urls from the JSON
class SimplePurchaseItem {
  final String? productId;
  final String? category;
  final String? subcategory;
  final String? itemNotes;
  final List<String>? grams;
  final List<String>? quantity;
  final String? totalWeight;
  final String? total;
  final String? design;
  final String? image;
  final String? status;
  final String? imageUrl;
  final String? size;

  SimplePurchaseItem({
    this.productId,
    this.category,
    this.subcategory,
    this.itemNotes,
    this.grams,
    this.quantity,
    this.totalWeight,
    this.total,
    this.design,
    this.image,
    this.status,
    this.imageUrl,
    this.size,
  });

  factory SimplePurchaseItem.fromJson(Map<String, dynamic> json) {
    return SimplePurchaseItem(
      productId: json['product_id']?.toString(),
      category: json['category']?.toString(),
      subcategory: json['subcategory']?.toString(),
      itemNotes: json['item_notes']?.toString(), // FIX: 'notes' instead of 'item_notes'
      grams: json['grams'] != null ? List<String>.from(json['grams'].map((x) => x.toString())) : null,
      quantity: json['quantity'] != null ? List<String>.from(json['quantity'].map((x) => x.toString())) : null,
      totalWeight: json['total_weight']?.toString(),
      total: json['total']?.toString(),
      design: json['design']?.toString(), // FIX: Capture string design
      image: json['image']?.toString(),
      status: json['status']?.toString(),
      imageUrl: json['image_url']?.toString(),
      size: json['item_size']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'category': category,
      'subcategory': subcategory,
      'item_notes': itemNotes,
      'grams': grams,
      'quantity': quantity,
      'total_weight': totalWeight,
      'total': total,
      'design': design,
      'image': image,
      'status': status,
      'image_url': imageUrl,
      'item_size': size,
    };
  }
}