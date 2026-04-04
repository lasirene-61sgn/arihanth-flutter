// ─────────────────────────────────────────────────
//  designs_model.dart  — matches actual API response
// ─────────────────────────────────────────────────

class DesignCategory {
  final int? id;
  final String? name;

  DesignCategory({this.id, this.name});

  factory DesignCategory.fromJson(Map<String, dynamic> json) {
    return DesignCategory(
      id: json['id'],
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class DesignSubcategory {
  final int? id;
  final int? productCategoryId;
  final String? name;

  DesignSubcategory({this.id, this.productCategoryId, this.name});

  factory DesignSubcategory.fromJson(Map<String, dynamic> json) {
    return DesignSubcategory(
      id: json['id'],
      productCategoryId: json['product_category_id'],
      name: json['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_category_id': productCategoryId,
        'name': name,
      };
}

class DesignImage {
  final int? id;
  final int? productId;
  final String? path;
  final String? createdAt;
  final String? updatedAt;
  final String? imageUrl;

  DesignImage({
    this.id,
    this.productId,
    this.path,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  factory DesignImage.fromJson(Map<String, dynamic> json) {
    return DesignImage(
      id: json['id'],
      productId: json['product_id'],
      path: json['path']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'path': path,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image_url': imageUrl,
    };
  }
}

class Design {
  final int? id;
  final int? isLocked;
  final String? productCode;
  final String? relabelCode;
  final String? productName;
  final int? productCategoryId;
  final int? productSubcategoryId;
  final String? type;
  final String? orderType;
  final String? designStatus;
  final String? designCode;
  final String? bpCode;
  final String? openClose;
  final String? size;
  final String? length;
  final String? weightFrom;
  final String? weightTo;
  final String? hallmark;
  final String? rodium;
  final String? hook;
  final String? stone;
  final String? enamel;
  final String? productImage;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  // Nested objects
  final DesignCategory? categoryObj;
  final DesignSubcategory? subcategoryObj;
  final List<DesignImage>? images;

  Design({
    this.id,
    this.isLocked,
    this.productCode,
    this.relabelCode,
    this.productName,
    this.productCategoryId,
    this.productSubcategoryId,
    this.type,
    this.orderType,
    this.designStatus,
    this.designCode,
    this.bpCode,
    this.openClose,
    this.size,
    this.length,
    this.weightFrom,
    this.weightTo,
    this.hallmark,
    this.rodium,
    this.hook,
    this.stone,
    this.enamel,
    this.productImage,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.categoryObj,
    this.subcategoryObj,
    this.images,
  });

  // ── Convenience getters (backward-compatible with screen code) ──

  /// Category name string (e.g. "EARRINGS")
  String? get category => categoryObj?.name;

  /// Subcategory name string (e.g. "JHUMKA")
  String? get subCategory => subcategoryObj?.name;

  /// Product name used as the design display name
  String? get designName => productName;

  /// First image URL from images list (full URL)
  String? get imageUrl {
    if (images != null && images!.isNotEmpty) {
      return images!.first.imageUrl;
    }
    return null;
  }

  factory Design.fromJson(Map<String, dynamic> json) {
    return Design(
      id: json['id'],
      isLocked: json['is_locked'],
      productCode: json['product_code']?.toString(),
      relabelCode: json['relabel_code']?.toString(),
      productName: json['product_name']?.toString(),
      productCategoryId: json['product_category_id'],
      productSubcategoryId: json['product_subcategory_id'],
      type: json['type']?.toString(),
      orderType: json['order_type']?.toString(),
      designStatus: json['design_status']?.toString(),
      designCode: json['design_code']?.toString(),
      bpCode: json['bp_code']?.toString(),
      openClose: json['open_close']?.toString(),
      size: json['size']?.toString(),
      length: json['length']?.toString(),
      weightFrom: json['weight_from']?.toString(),
      weightTo: json['weight_to']?.toString(),
      hallmark: json['hallmark']?.toString(),
      rodium: json['rodium']?.toString(),
      hook: json['hook']?.toString(),
      stone: json['stone']?.toString(),
      enamel: json['enamel']?.toString(),
      productImage: json['product_image']?.toString(),
      createdBy: json['created_by'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      categoryObj: json['category'] is Map<String, dynamic>
          ? DesignCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      subcategoryObj: json['subcategory'] is Map<String, dynamic>
          ? DesignSubcategory.fromJson(json['subcategory'] as Map<String, dynamic>)
          : null,
      images: json['images'] is List
          ? (json['images'] as List)
              .map((i) => DesignImage.fromJson(i as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_locked': isLocked,
      'product_code': productCode,
      'relabel_code': relabelCode,
      'product_name': productName,
      'product_category_id': productCategoryId,
      'product_subcategory_id': productSubcategoryId,
      'type': type,
      'order_type': orderType,
      'design_status': designStatus,
      'design_code': designCode,
      'bp_code': bpCode,
      'open_close': openClose,
      'size': size,
      'length': length,
      'weight_from': weightFrom,
      'weight_to': weightTo,
      'hallmark': hallmark,
      'rodium': rodium,
      'hook': hook,
      'stone': stone,
      'enamel': enamel,
      'product_image': productImage,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'category': categoryObj?.toJson(),
      'subcategory': subcategoryObj?.toJson(),
      'images': images?.map((i) => i.toJson()).toList(),
    };
  }
}