class RepairOrder {
  final int? id;
  final int? buyerId;
  final String? repairDate;
  final String? productName;
  final String? weight;
  final String? repairDetails;
  final String? sampleDetails;
  final String? itemGivenTo;
  final String? imageProof;
  final String? imageProofUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? status;
  final String? rejectReason;
  final String? allocatedCraftsmanCode;
  final String? allocationNotes;
  final String? craftsmanStatus;
  final RepairBuyer? buyer;
  final RepairCraftsman? craftsman;
  final String? orderNo;
  final String? repair;
  final String? ref;
  final String? notes;

  RepairOrder({
    this.id,
    this.buyerId,
    this.repairDate,
    this.productName,
    this.weight,
    this.repairDetails,
    this.sampleDetails,
    this.itemGivenTo,
    this.imageProof,
    this.imageProofUrl,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.rejectReason,
    this.allocatedCraftsmanCode,
    this.allocationNotes,
    this.craftsmanStatus,
    this.buyer,
    this.craftsman,
    this.orderNo,
    this.repair,
    this.ref,
    this.notes,
  });

  RepairOrder copyWith({
    int? id,
    int? buyerId,
    String? repairDate,
    String? productName,
    String? weight,
    String? repairDetails,
    String? sampleDetails,
    String? itemGivenTo,
    String? imageProof,
    String? imageProofUrl,
    String? createdAt,
    String? updatedAt,
    String? status,
    String? rejectReason,
    String? allocatedCraftsmanCode,
    String? allocationNotes,
    String? craftsmanStatus,
    RepairBuyer? buyer,
    RepairCraftsman? craftsman,
    String? orderNo,
    String? repair,
    String? ref,
    String? notes,
  }) {
    return RepairOrder(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      repairDate: repairDate ?? this.repairDate,
      productName: productName ?? this.productName,
      weight: weight ?? this.weight,
      repairDetails: repairDetails ?? this.repairDetails,
      sampleDetails: sampleDetails ?? this.sampleDetails,
      itemGivenTo: itemGivenTo ?? this.itemGivenTo,
      imageProof: imageProof ?? this.imageProof,
      imageProofUrl: imageProofUrl ?? this.imageProofUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      allocatedCraftsmanCode: allocatedCraftsmanCode ?? this.allocatedCraftsmanCode,
      allocationNotes: allocationNotes ?? this.allocationNotes,
      craftsmanStatus: craftsmanStatus ?? this.craftsmanStatus,
      buyer: buyer ?? this.buyer,
      craftsman: craftsman ?? this.craftsman,
      orderNo: orderNo ?? this.orderNo,
      repair: repair ?? this.repair,
      ref: ref ?? this.ref,
      notes: notes ?? this.notes,
    );
  }

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    return RepairOrder(
      id: json['id'],
      buyerId: json['buyer_id'],
      repairDate: json['repair_date'],
      productName: json['product_name'],
      weight: json['weight']?.toString(),
      repairDetails: json['repair_details'],
      sampleDetails: json['sample_details'],
      itemGivenTo: json['item_given_to'],
      imageProof: json['image_proof'],
      imageProofUrl: json['image_proof_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      status: json['status'],
      rejectReason: json['reject_reason'],
      allocatedCraftsmanCode: json['allocated_craftsman_code'],
      allocationNotes: json['allocation_notes'],
      craftsmanStatus: json['craftsman_status'],
      buyer: json['buyer'] != null ? RepairBuyer.fromJson(json['buyer']) : null,
      craftsman: json['craftsman'] != null
          ? RepairCraftsman.fromJson(json['craftsman'])
          : null,
      orderNo: json['order_no'],
      repair: json['repair'],
      ref: json['ref'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'repair_date': repairDate,
      'product_name': productName,
      'weight': weight,
      'repair_details': repairDetails,
      'sample_details': sampleDetails,
      'item_given_to': itemGivenTo,
      'image_proof': imageProof,
      'status': status,
      'allocated_craftsman_code': allocatedCraftsmanCode,
      'allocation_notes': allocationNotes,
      'craftsman_status': craftsmanStatus,
      'order_no': orderNo,
      'repair': repair,
      'ref': ref,
      'notes': notes,
    };
  }
}

class RepairBuyer {
  final int? id;
  final String? bpCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? email;
  final String? area;
  final String? pincode;
  final String? city;
  final String? state;

  RepairBuyer({
    this.id,
    this.bpCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
    this.area,
    this.pincode,
    this.city,
    this.state,
  });

  RepairBuyer copyWith({
    int? id,
    String? bpCode,
    String? businessName,
    String? name,
    String? mobile,
    String? email,
    String? area,
    String? pincode,
    String? city,
    String? state,
  }) {
    return RepairBuyer(
      id: id ?? this.id,
      bpCode: bpCode ?? this.bpCode,
      businessName: businessName ?? this.businessName,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      area: area ?? this.area,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  factory RepairBuyer.fromJson(Map<String, dynamic> json) {
    return RepairBuyer(
      id: json['id'],
      bpCode: json['bp_code'],
      businessName: json['business_name'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      area: json['area'],
      pincode: json['pincode'],
      city: json['city'],
      state: json['state'],
    );
  }
}

class RepairCraftsman {
  final int? id;
  final String? craftmanCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? email;
  final String? city;
  final String? state;

  RepairCraftsman({
    this.id,
    this.craftmanCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
    this.city,
    this.state,
  });

  RepairCraftsman copyWith({
    int? id,
    String? craftmanCode,
    String? businessName,
    String? name,
    String? mobile,
    String? email,
    String? city,
    String? state,
  }) {
    return RepairCraftsman(
      id: id ?? this.id,
      craftmanCode: craftmanCode ?? this.craftmanCode,
      businessName: businessName ?? this.businessName,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  factory RepairCraftsman.fromJson(Map<String, dynamic> json) {
    return RepairCraftsman(
      id: json['id'],
      craftmanCode: json['craftman_code'],
      businessName: json['business_name'],
      name: json['name'],
      mobile: json['mobile'],
      email: json['email'],
      city: json['city'],
      state: json['state'],
    );
  }
}
