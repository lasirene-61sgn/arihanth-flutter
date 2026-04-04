class Product {
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
  final ProductCategory? category;
  final ProductSubcategory? subcategory;
  final Creator? creator;
  final List<ProductImageData>? images;

  Product({
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
    this.creator,
    this.images,
  });

  Product copyWith({
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
    ProductCategory? category,
    ProductSubcategory? subcategory,
    Creator? creator,
    List<ProductImageData>? images,
  }) {
    return Product(
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
      creator: creator ?? this.creator,
      images: images ?? this.images,
    );
  }

  /// ✅ From JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
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
        designViewUnlockedUntil: json['design_view_unlocked_until']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        category: json['category'] != null ? ProductCategory.fromJson(json['category']) : null,
        subcategory: json['subcategory'] != null ? ProductSubcategory.fromJson(json['subcategory']) : null,
        creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
        images: json['images'] != null
            ? List<ProductImageData>.from(json['images'].map((x) => ProductImageData.fromJson(x)))
            : null,
      );
    } catch (e, s) {
      print("❌ Product.fromJson ERROR: $e");
      print("JSON: $json");
      print("STACK: $s");
      rethrow;
    }
  }

  /// ✅ To JSON
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
      'creator': creator?.toJson(),
      'images': images?.map((x) => x.toJson()).toList(),
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
  final List<String>? permissions;
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
      userCode: json['user_code']?.toString(),
      bpCode: json['bp_code']?.toString(),
      name: json['name']?.toString(),
      fullName: json['full_name']?.toString(),
      emailId: json['email_id']?.toString(),
      mobileNo: json['mobile_no']?.toString(),
      email: json['email']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      permissions: json['permissions'] != null ? List<String>.from(json['permissions']) : null,
      status: json['status']?.toString(),
      dob: json['dob']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      pincode: json['pincode']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      aadharPhoto: json['aadhar_photo']?.toString(),
      aadharNumber: json['aadhar_number']?.toString(),
      createdBy: json['created_by'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      isFrozen: json['is_frozen'],
      profilePictureUrl: json['profile_picture_url']?.toString(),
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


class ProductCategory {
  final int? id;
  final String? name;
  final bool? hasHook;
  final bool? hasEnamel;
  final bool? hasRodium;
  final bool? hasOpenClose;
  final bool? hasStone;
  final String? createdAt;
  final String? updatedAt;

  ProductCategory({
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

  ProductCategory copyWith({
    int? id,
    String? name,
    bool? hasHook,
    bool? hasEnamel,
    bool? hasRodium,
    bool? hasOpenClose,
    bool? hasStone,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      hasHook: hasHook ?? this.hasHook,
      hasEnamel: hasEnamel ?? this.hasEnamel,
      hasRodium: hasRodium ?? this.hasRodium,
      hasOpenClose: hasOpenClose ?? this.hasOpenClose,
      hasStone: hasStone ?? this.hasStone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name']?.toString(),
      hasHook: json['has_hook'],
      hasEnamel: json['has_enamel'],
      hasRodium: json['has_rodium'],
      hasOpenClose: json['has_open_close'],
      hasStone: json['has_stone'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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

class ProductSubcategory {
  final int? id;
  final int? productCategoryId;
  final String? name;
  final String? createdAt;
  final String? updatedAt;

  ProductSubcategory({
    this.id,
    this.productCategoryId,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  ProductSubcategory copyWith({
    int? id,
    int? productCategoryId,
    String? name,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductSubcategory(
      id: id ?? this.id,
      productCategoryId: productCategoryId ?? this.productCategoryId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductSubcategory.fromJson(Map<String, dynamic> json) {
    return ProductSubcategory(
      id: json['id'],
      productCategoryId: json['product_category_id'],
      name: json['name']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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

class ProductImageData {
  final int? id;
  final int? productId;
  final String? path;
  final String? createdAt;
  final String? updatedAt;
  final String? imageUrl;

  ProductImageData({
    this.id,
    this.productId,
    this.path,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  factory ProductImageData.fromJson(Map<String, dynamic> json) {
    return ProductImageData(
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
    };
  }
}

class BPProductModel {
  final bool? success;
  final BPProductData? product;

  BPProductModel({this.success, this.product});

  factory BPProductModel.fromJson(Map<String, dynamic> json) {
    return BPProductModel(
      success: json['success'],
      product: json['product'] != null ? BPProductData.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'product': product?.toJson(),
    };
  }
}

class BPProductData {
  final int? id;
  final String? productName;
  final String? designCode;
  final String? productCode;
  final String? productImageUrl;
  final int? productCategoryId;
  final int? subcategoryId;
  final String? type;
  final String? openClose;
  final String? hallmark;
  final String? rodium;
  final String? hook;
  final String? size;
  final String? stone;
  final String? enamel;
  final String? length;
  final String? weightFrom;
  final String? weightTo;
  final String? relabelCode;
  final List<ProductImageData>? images;

  BPProductData({
    this.id,
    this.productName,
    this.designCode,
    this.productCode,
    this.productImageUrl,
    this.productCategoryId,
    this.subcategoryId,
    this.type,
    this.openClose,
    this.hallmark,
    this.rodium,
    this.hook,
    this.size,
    this.stone,
    this.enamel,
    this.length,
    this.weightFrom,
    this.weightTo,
    this.relabelCode,
    this.images,
  });

  factory BPProductData.fromJson(Map<String, dynamic> json) {
    return BPProductData(
      id: json['id'],
      productName: json['product_name']?.toString(),
      designCode: json['design_code']?.toString(),
      productCode: json['product_code']?.toString(),
      productImageUrl: json['product_image_url']?.toString(),
      productCategoryId: json['product_category_id'],
      subcategoryId: json['subcategory_id'],
      type: json['type']?.toString(),
      openClose: json['open_close']?.toString(),
      hallmark: json['hallmark']?.toString(),
      rodium: json['rodium']?.toString(),
      hook: json['hook']?.toString(),
      size: json['size']?.toString(),
      stone: json['stone']?.toString(),
      enamel: json['enamel']?.toString(),
      length: json['length']?.toString(),
      weightFrom: json['weight_from']?.toString(),
      weightTo: json['weight_to']?.toString(),
      relabelCode: json['relabel_code']?.toString(),
      images: json['images'] != null
          ? List<ProductImageData>.from(
              json['images'].map((x) => ProductImageData.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_name': productName,
      'design_code': designCode,
      'product_code': productCode,
      'product_image_url': productImageUrl,
      'product_category_id': productCategoryId,
      'subcategory_id': subcategoryId,
      'type': type,
      'open_close': openClose,
      'hallmark': hallmark,
      'rodium': rodium,
      'hook': hook,
      'size': size,
      'stone': stone,
      'enamel': enamel,
      'length': length,
      'weight_from': weightFrom,
      'weight_to': weightTo,
      'relabel_code': relabelCode,
      'images': images?.map((x) => x.toJson()).toList(),
    };
  }
}
