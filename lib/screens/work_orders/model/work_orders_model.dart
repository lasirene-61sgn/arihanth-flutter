import 'package:arianth/screens/products/model/category_model.dart';

class WorkOrder {
  final int? id;
  final int? createdBy;
  final String? creatorType;
  final String? creatorUserCode;
  final String? workOrderNumber;
  final String? productImage;
  final String? bpCode;
  final String? customerName;
  final String? referenceNo;
  final String? dueDate;
  final int? productCategoryId;
  final String? subcategory;
  final int? subcategoryId;
  final String? quantity;
  final String? type;
  final String? orderType;
  final String? weightFrom;
  final String? weightTo;
  final String? narrationCraftsman;
  final String? narrationAdmin;
  final String? openClose;
  final String? hallmark;
  final String? rodium;
  final String? hook;
  final String? size;
  final String? stone;
  final String? enamel;
  final String? screwName;
  final String? length;
  final String? productCode;
  final String? designCode;
  final String? productName;
  final String? craftsmanDueDate;
  final String? allocatedCraftsmanBpCode;
  final String? status;
  final int? approvedBy;
  final String? craftsmanStatus;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;
  final String? productImageUrl;
  final String? fileType;
  final String? previewImageUrl;
  final List<String>? galleryImages;

  // Added/Updated Relations
  final String? productCategory;
  final UserDetails? creatorDetails;
  final UserDetails? approverDetails;
  final Buyer? buyer;
  final SubcategoryRelation? subcategoryRelation;
  final Craftsman? craftsman;
  final List<String>? images;

  WorkOrder({
    this.id,
    this.createdBy,
    this.creatorType,
    this.creatorUserCode,
    this.workOrderNumber,
    this.productImage,
    this.bpCode,
    this.customerName,
    this.referenceNo,
    this.dueDate,
    this.productCategoryId,
    this.subcategory,
    this.subcategoryId,
    this.quantity,
    this.type,
    this.orderType,
    this.weightFrom,
    this.weightTo,
    this.narrationCraftsman,
    this.narrationAdmin,
    this.openClose,
    this.hallmark,
    this.rodium,
    this.hook,
    this.size,
    this.stone,
    this.enamel,
    this.screwName,
    this.length,
    this.productCode,
    this.designCode,
    this.productName,
    this.craftsmanDueDate,
    this.allocatedCraftsmanBpCode,
    this.status,
    this.approvedBy,
    this.craftsmanStatus,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.productImageUrl,
    this.fileType,
    this.previewImageUrl,
    this.galleryImages,
    this.productCategory,
    this.creatorDetails,
    this.approverDetails,
    this.buyer,
    this.subcategoryRelation,
    this.craftsman,
    this.images,
  });

  WorkOrder copyWith({
    int? id,
    int? createdBy,
    String? creatorType,
    String? creatorUserCode,
    String? workOrderNumber,
    String? productImage,
    String? bpCode,
    String? customerName,
    String? referenceNo,
    String? dueDate,
    int? productCategoryId,
    String? subcategory,
    int? subcategoryId,
    String? quantity,
    String? type,
    String? orderType,
    String? weightFrom,
    String? weightTo,
    String? narrationCraftsman,
    String? narrationAdmin,
    String? openClose,
    String? hallmark,
    String? rodium,
    String? hook,
    String? size,
    String? stone,
    String? enamel,
    String? screwName,
    String? length,
    String? productCode,
    String? designCode,
    String? productName,
    String? craftsmanDueDate,
    String? allocatedCraftsmanBpCode,
    String? status,
    int? approvedBy,
    String? craftsmanStatus,
    String? rejectionReason,
    String? createdAt,
    String? updatedAt,
    String? productImageUrl,
    String? fileType,
    String? previewImageUrl,
    List<String>? galleryImages,
    String? productCategory,
    UserDetails? creatorDetails,
    UserDetails? approverDetails,
    Buyer? buyer,
    SubcategoryRelation? subcategoryRelation,
    Craftsman? craftsman,
    List<String>? images,
  }) {
    return WorkOrder(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      creatorType: creatorType ?? this.creatorType,
      creatorUserCode: creatorUserCode ?? this.creatorUserCode,
      workOrderNumber: workOrderNumber ?? this.workOrderNumber,
      productImage: productImage ?? this.productImage,
      bpCode: bpCode ?? this.bpCode,
      customerName: customerName ?? this.customerName,
      referenceNo: referenceNo ?? this.referenceNo,
      dueDate: dueDate ?? this.dueDate,
      productCategoryId: productCategoryId ?? this.productCategoryId,
      subcategory: subcategory ?? this.subcategory,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      orderType: orderType ?? this.orderType,
      weightFrom: weightFrom ?? this.weightFrom,
      weightTo: weightTo ?? this.weightTo,
      narrationCraftsman: narrationCraftsman ?? this.narrationCraftsman,
      narrationAdmin: narrationAdmin ?? this.narrationAdmin,
      openClose: openClose ?? this.openClose,
      hallmark: hallmark ?? this.hallmark,
      rodium: rodium ?? this.rodium,
      hook: hook ?? this.hook,
      size: size ?? this.size,
      stone: stone ?? this.stone,
      enamel: enamel ?? this.enamel,
      screwName: screwName ?? this.screwName,
      length: length ?? this.length,
      productCode: productCode ?? this.productCode,
      designCode: designCode ?? this.designCode,
      productName: productName ?? this.productName,
      craftsmanDueDate: craftsmanDueDate ?? this.craftsmanDueDate,
      allocatedCraftsmanBpCode: allocatedCraftsmanBpCode ?? this.allocatedCraftsmanBpCode,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      craftsmanStatus: craftsmanStatus ?? this.craftsmanStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      fileType: fileType ?? this.fileType,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      productCategory: productCategory ?? this.productCategory,
      creatorDetails: creatorDetails ?? this.creatorDetails,
      approverDetails: approverDetails ?? this.approverDetails,
      buyer: buyer ?? this.buyer,
      subcategoryRelation: subcategoryRelation ?? this.subcategoryRelation,
      craftsman: craftsman ?? this.craftsman,
      images: images ?? this.images,
    );
  }

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      createdBy: json['created_by'],
      creatorType: json['creator_type'],
      creatorUserCode: json['creator_user_code'],
      workOrderNumber: json['work_order_number'],
      productImage: json['product_image'],
      bpCode: json['bp_code'],
      customerName: json['customer_name'],
      referenceNo: json['reference_no'],
      dueDate: json['due_date'],
      productCategoryId: json['product_category_id'],
      subcategory: json['subcategory'],
      subcategoryId: json['subcategory_id'],
      quantity: json['quantity']?.toString(), // Ensure string
      type: json['type'],
      orderType: json['order_type'],
      weightFrom: json['weight_from']?.toString(),
      weightTo: json['weight_to']?.toString(),
      narrationCraftsman: json['narration_craftsman'],
      narrationAdmin: json['narration_admin'],
      openClose: json['open_close'],
      hallmark: json['hallmark']?.toString(),
      rodium: json['rodium'],
      hook: json['hook'],
      size: json['size']?.toString(),
      stone: json['stone'],
      enamel: json['enamel'],
      screwName: json['screw_name'],
      length: json['length']?.toString(),
      productCode: json['product_code'],
      designCode: json['design_code'],
      productName: json['product_name'],
      craftsmanDueDate: json['craftsman_due_date'],
      allocatedCraftsmanBpCode: json['allocated_craftsman_bp_code'],
      status: json['status'],
      approvedBy: json['approved_by'],
      craftsmanStatus: json['craftsman_status'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      productImageUrl: json['product_image_url'],
      fileType: json['file_type'],
      previewImageUrl: json['preview_image_url'],
      galleryImages: (json['gallery_images'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      productCategory: json['product_category'].toString(),
      creatorDetails: json['creator_details'] != null
          ? UserDetails.fromJson(json['creator_details'])
          : null,
      approverDetails: json['approver_details'] != null
          ? UserDetails.fromJson(json['approver_details'])
          : null,
      buyer: json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null,
      subcategoryRelation: json['subcategory_relation'] != null
          ? SubcategoryRelation.fromJson(json['subcategory_relation'])
          : null,
      craftsman: json['craftsman'] != null
          ? Craftsman.fromJson(json['craftsman'])
          : null,
      images: (json['images'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdBy != null) 'created_by': createdBy,
      if (creatorType != null) 'creator_type': creatorType,
      if (creatorUserCode != null) 'creator_user_code': creatorUserCode,
      if (workOrderNumber != null) 'work_order_number': workOrderNumber,
      if (productImage != null) 'product_image': productImage,
      if (bpCode != null) 'bp_code': bpCode,
      if (customerName != null) 'customer_name': customerName,
      if (referenceNo != null) 'reference_no': referenceNo,
      if (dueDate != null) 'due_date': dueDate,
      if (productCategoryId != null) 'product_category_id': productCategoryId,
      if (productCategory != null ) 'product_category': productCategory,
      if (subcategory != null) 'subcategory': subcategory,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (quantity != null) 'quantity': quantity,
      if (type != null) 'type': type,
      if (orderType != null) 'order_type': orderType,
      if (weightFrom != null) 'weight_from': weightFrom,
      if (weightTo != null) 'weight_to': weightTo,
      if (narrationCraftsman != null) 'narration_craftsman': narrationCraftsman,
      if (narrationAdmin != null) 'narration_admin': narrationAdmin,
      if (openClose != null) 'open_close': openClose,
      if (hallmark != null) 'hallmark': hallmark,
      if (rodium != null) 'rodium': rodium,
      if (hook != null) 'hook': hook,
      if (size != null) 'size': size,
      if (stone != null) 'stone': stone,
      if (enamel != null) 'enamel': enamel,
      if (screwName != null) 'screw_name': screwName,
      if (length != null) 'length': length,
      if (productCode != null) 'select_product': productCode,
      if (designCode != null) 'design_code': designCode,
      if (productName != null) 'product_name': productName,
      if (craftsmanDueDate != null) 'craftsman_due_date': craftsmanDueDate,
      if (allocatedCraftsmanBpCode != null) 'allocated_craftsman_bp_code': allocatedCraftsmanBpCode,
      if (status != null) 'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (craftsmanStatus != null) 'craftsman_status': craftsmanStatus,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}

class Craftsman {
  final int? id;
  final String? craftmanCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? email;

  Craftsman({
    this.id,
    this.craftmanCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
  });

  factory Craftsman.fromJson(Map<String, dynamic> json) {
    return Craftsman(
      id: json['id'],
      craftmanCode: json['craftman_code'],
      businessName: json['business_name'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
    );
  }
}

class SubcategoryRelation {
  final int? id;
  final int? productCategoryId;
  final String? name;

  SubcategoryRelation({this.id, this.productCategoryId, this.name});

  factory SubcategoryRelation.fromJson(Map<String, dynamic> json) {
    return SubcategoryRelation(
      id: json['id'],
      productCategoryId: json['product_category_id'],
      name: json['name'],
    );
  }
}

class WorkOrderImage {
  final int? id;
  final int? workOrderId;
  final String? imagePath;
  final String? imageUrl;

  WorkOrderImage({this.id, this.workOrderId, this.imagePath, this.imageUrl});

  factory WorkOrderImage.fromJson(Map<String, dynamic> json) {
    return WorkOrderImage(
      id: json['id'],
      workOrderId: json['work_order_id'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
    );
  }
}

class Buyer {
  final int? id;
  final String? businessName;
  final String? mobile;
  final String? email;
  final String? city;
  final String? state;

  Buyer({
    this.id,
    this.businessName,
    this.mobile,
    this.email,
    this.city,
    this.state,
  });

  Buyer copyWith({
    int? id,
    String? businessName,
    String? mobile,
    String? email,
    String? city,
    String? state,
  }) {
    return Buyer(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['id'],
      businessName: json['business_name'],
      mobile: json['mobile'],
      email: json['email'],
      city: json['city'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'mobile': mobile,
      'email': email,
      'city': city,
      'state': state,
    };
  }
}
class UserDetails {
  final String? name;
  final String? bpCode;
  final String? userCode;
  final String? type;

  UserDetails({
    this.name,
    this.bpCode,
    this.userCode,
    this.type,
  });

  UserDetails copyWith({
    String? name,
    String? bpCode,
    String? userCode,
    String? type,
  }) {
    return UserDetails(
      name: name ?? this.name,
      bpCode: bpCode ?? this.bpCode,
      userCode: userCode ?? this.userCode,
      type: type ?? this.type,
    );
  }

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      name: json['name'],
      bpCode: json['bp_code'], // will be null for approver
      userCode: json['user_code'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bp_code': bpCode,
      'user_code': userCode,
      'type': type,
    };
  }
}