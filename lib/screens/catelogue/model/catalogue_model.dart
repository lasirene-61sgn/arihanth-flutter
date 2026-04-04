class Catalogue {
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
  final String? designViewUnlockedUntil;
  final String? createdAt;
  final String? updatedAt;
  final Category? category;
  final Subcategory? subcategory;
  final List<ProductImage>? images;
  final Creator? creator;

  Catalogue({
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
    this.designViewUnlockedUntil,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.subcategory,
    this.images,
    this.creator,
  });

  Catalogue copyWith({
    int? id,
    int? isLocked,
    String? productCode,
    String? relabelCode,
    String? productName,
    int? productCategoryId,
    int? productSubcategoryId,
    String? type,
    String? orderType,
    String? designStatus,
    String? designCode,
    String? bpCode,
    String? openClose,
    String? size,
    String? length,
    String? weightFrom,
    String? weightTo,
    String? hallmark,
    String? rodium,
    String? hook,
    String? stone,
    String? enamel,
    String? productImage,
    int? createdBy,
    String? designViewUnlockedUntil,
    String? createdAt,
    String? updatedAt,
    Category? category,
    Subcategory? subcategory,
    List<ProductImage>? images,
    Creator? creator,
  }) {
    return Catalogue(
      id: id ?? this.id,
      isLocked: isLocked ?? this.isLocked,
      productCode: productCode ?? this.productCode,
      relabelCode: relabelCode ?? this.relabelCode,
      productName: productName ?? this.productName,
      productCategoryId: productCategoryId ?? this.productCategoryId,
      productSubcategoryId: productSubcategoryId ?? this.productSubcategoryId,
      type: type ?? this.type,
      orderType: orderType ?? this.orderType,
      designStatus: designStatus ?? this.designStatus,
      designCode: designCode ?? this.designCode,
      bpCode: bpCode ?? this.bpCode,
      openClose: openClose ?? this.openClose,
      size: size ?? this.size,
      length: length ?? this.length,
      weightFrom: weightFrom ?? this.weightFrom,
      weightTo: weightTo ?? this.weightTo,
      hallmark: hallmark ?? this.hallmark,
      rodium: rodium ?? this.rodium,
      hook: hook ?? this.hook,
      stone: stone ?? this.stone,
      enamel: enamel ?? this.enamel,
      productImage: productImage ?? this.productImage,
      createdBy: createdBy ?? this.createdBy,
      designViewUnlockedUntil: designViewUnlockedUntil ?? this.designViewUnlockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      images: images ?? this.images,
      creator: creator ?? this.creator,
    );
  }

  // ── Convenience getters ──
  /// Category name string (e.g. "EARRINGS")
  String? get categoryName => category?.name;

  /// Subcategory name string
  String? get subcategoryName => subcategory?.name;

  /// First image URL from images list (full URL)
  String? get imageUrl {
    if (images != null && images!.isNotEmpty) {
      return images!.first.imageUrl;
    }
    return null;
  }

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue(
      id: json['id'],
      isLocked: json['is_locked'],
      productCode: json['product_code'],
      relabelCode: json['relabel_code'],
      productName: json['product_name'],
      productCategoryId: json['product_category_id'],
      productSubcategoryId: json['product_subcategory_id'],
      type: json['type'],
      orderType: json['order_type'],
      designStatus: json['design_status'],
      designCode: json['design_code'],
      bpCode: json['bp_code'],
      openClose: json['open_close'],
      size: json['size']?.toString(), // Safely convert to string if it comes as int
      length: json['length']?.toString(),
      weightFrom: json['weight_from'],
      weightTo: json['weight_to'],
      hallmark: json['hallmark'],
      rodium: json['rodium'],
      hook: json['hook'],
      stone: json['stone'],
      enamel: json['enamel'],
      productImage: json['product_image'],
      createdBy: json['created_by'],
      designViewUnlockedUntil: json['design_view_unlocked_until'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      subcategory: json['subcategory'] != null ? Subcategory.fromJson(json['subcategory']) : null,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => ProductImage.fromJson(i)).toList()
          : null,
      creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
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
      'design_view_unlocked_until': designViewUnlockedUntil,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'category': category?.toJson(),
      'subcategory': subcategory?.toJson(),
      'images': images?.map((i) => i.toJson()).toList(),
      'creator': creator?.toJson(),
    };
  }
}

class Category {
  final int? id;
  final String? name;
  final bool? hasHook;
  final bool? hasEnamel;
  final bool? hasRodium;
  final bool? hasOpenClose;
  final bool? hasStone;
  final String? createdAt;
  final String? updatedAt;

  Category({
    this.id,
    this.name,
    this.hasHook,
    this.hasEnamel,
    this.hasRodium,
    this.hasOpenClose,
    this.hasStone,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      hasHook: json['has_hook'],
      hasEnamel: json['has_enamel'],
      hasRodium: json['has_rodium'],
      hasOpenClose: json['has_open_close'],
      hasStone: json['has_stone'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'has_hook': hasHook,
      'has_enamel': hasEnamel,
      'has_rodium': hasRodium,
      'has_open_close': hasOpenClose,
      'has_stone': hasStone,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Subcategory {
  final int? id;
  final int? productCategoryId;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  Subcategory({
    this.id,
    this.productCategoryId,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      productCategoryId: json['product_category_id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_category_id': productCategoryId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ProductImage {
  final int? id;
  final int? productId;
  final String? path;
  final String? createdAt;
  final String? updatedAt;
  final String? imageUrl;

  ProductImage({
    this.id,
    this.productId,
    this.path,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      productId: json['product_id'],
      path: json['path'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      imageUrl: json['image_url'],
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

class Creator {
  final int? id;
  final String? userCode;
  final String? bpCode;
  final String? name;
  final String? fullName;
  final String? emailId;
  final String? mobileNo;
  final String? email;
  final String? emailVerifiedAt;
  final dynamic permissions;
  final String? status;
  final String? dob;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? profilePicture;
  final String? aadharPhoto;
  final String? aadharNumber;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final int? isFrozen;
  final String? profilePictureUrl;

  Creator({
    this.id,
    this.userCode,
    this.bpCode,
    this.name,
    this.fullName,
    this.emailId,
    this.mobileNo,
    this.email,
    this.emailVerifiedAt,
    this.permissions,
    this.status,
    this.dob,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.profilePicture,
    this.aadharPhoto,
    this.aadharNumber,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isFrozen,
    this.profilePictureUrl,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'],
      userCode: json['user_code'],
      bpCode: json['bp_code'],
      name: json['name'],
      fullName: json['full_name'],
      emailId: json['email_id'],
      mobileNo: json['mobile_no'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      permissions: json['permissions'],
      status: json['status'],
      dob: json['dob'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      profilePicture: json['profile_picture'],
      aadharPhoto: json['aadhar_photo'],
      aadharNumber: json['aadhar_number'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isFrozen: json['is_frozen'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_code': userCode,
      'bp_code': bpCode,
      'name': name,
      'full_name': fullName,
      'email_id': emailId,
      'mobile_no': mobileNo,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'permissions': permissions,
      'status': status,
      'dob': dob,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'profile_picture': profilePicture,
      'aadhar_photo': aadharPhoto,
      'aadhar_number': aadharNumber,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_frozen': isFrozen,
      'profile_picture_url': profilePictureUrl,
    };
  }
}