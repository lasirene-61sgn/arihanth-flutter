class BuyerAadharDetail {
  final int? id;
  final String? aadharName;
  final String? aadharNumber;
  final String? aadharImageUrl;

  BuyerAadharDetail({this.id, this.aadharName, this.aadharNumber, this.aadharImageUrl});

  factory BuyerAadharDetail.fromJson(Map<String, dynamic> json) {
    return BuyerAadharDetail(
      id: json['id'],
      aadharName: json['aadhar_name'],
      aadharNumber: json['aadhar_number'],
      aadharImageUrl: json['aadhar_image_url'] ?? json['aadhar_image'],
    );
  }

  BuyerAadharDetail copyWith({
    int? id,
    String? aadharName,
    String? aadharNumber,
    String? aadharImageUrl,
  }) {
    return BuyerAadharDetail(
      id: id ?? this.id,
      aadharName: aadharName ?? this.aadharName,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      aadharImageUrl: aadharImageUrl ?? this.aadharImageUrl,
    );
  }
}

class BuyerPanDetail {
  final int? id;
  final String? panNumber;
  final String? panImageUrl;

  BuyerPanDetail({this.id, this.panNumber, this.panImageUrl});

  factory BuyerPanDetail.fromJson(Map<String, dynamic> json) {
    return BuyerPanDetail(
      id: json['id'],
      panNumber: json['pan_number'],
      panImageUrl: json['pan_image_url'] ?? json['pan_image'],
    );
  }

  BuyerPanDetail copyWith({
    int? id,
    String? panNumber,
    String? panImageUrl,
  }) {
    return BuyerPanDetail(
      id: id ?? this.id,
      panNumber: panNumber ?? this.panNumber,
      panImageUrl: panImageUrl ?? this.panImageUrl,
    );
  }
}

class BuyerBankDetail {
  final int? id;
  final String? bankName;
  final String? accountNo;
  final String? accountName;
  final String? ifscCode;
  final String? branch;
  final String? bankCity;
  final String? bankState;
  final String? passbookUrl;

  BuyerBankDetail({
    this.id, this.bankName, this.accountNo, this.accountName,
    this.ifscCode, this.branch, this.bankCity, this.bankState, this.passbookUrl,
  });

  factory BuyerBankDetail.fromJson(Map<String, dynamic> json) {
    return BuyerBankDetail(
      id: json['id'],
      bankName: json['bank_name'],
      accountNo: json['account_no'],
      accountName: json['account_name'],
      ifscCode: json['ifsc_code'],
      branch: json['branch'],
      bankCity: json['bank_city'],
      bankState: json['bank_state'],
      passbookUrl: json['passbook_url'] ?? json['passbook'],
    );
  }

  BuyerBankDetail copyWith({
    int? id,
    String? bankName,
    String? accountNo,
    String? accountName,
    String? ifscCode,
    String? branch,
    String? bankCity,
    String? bankState,
    String? passbookUrl,
  }) {
    return BuyerBankDetail(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      accountName: accountName ?? this.accountName,
      ifscCode: ifscCode ?? this.ifscCode,
      branch: branch ?? this.branch,
      bankCity: bankCity ?? this.bankCity,
      bankState: bankState ?? this.bankState,
      passbookUrl: passbookUrl ?? this.passbookUrl,
    );
  }
}

class BuyerProfileModel {
  final int id;
  final String? bpCode;
  final String? businessName;
  final String? name; // Contact Name
  final String? mobile;
  final String? landline;
  final String? email;
  final String? businessEmail;
  final String? referedBy;
  final String? moreInfo;

  // Address
  final String? doorNo;
  final String? shopNo;
  final String? complexName;
  final String? buildingName;
  final String? streetName;
  final String? area;
  final String? pincode;
  final String? city;
  final String? state;
  final String? mapLocation;
  final String? locationGuide;

  // KYC
  final String? gstNo;
  final String? gstAttachment;
  final String? tanNo;
  final String? tanAttachment;
  final String? msmeNo;
  final String? msmeAttachment;
  final String? bisNo;
  final String? bisAttachment;
  final String? brandLogo;
  final String? cinNo;
  final String? cinAttachment;
  final String? shopAttachment;

  final List<BuyerAadharDetail> aadharDetails;
  final List<BuyerPanDetail> panDetails;
  final List<BuyerBankDetail> bankDetails;

  final int? isFrozen;
  final String? kycStatus;

  BuyerProfileModel({
    required this.id,
    this.bpCode,
    this.businessName,
    this.name,
    this.mobile,
    this.landline,
    this.email,
    this.businessEmail,
    this.referedBy,
    this.moreInfo,
    this.doorNo,
    this.shopNo,
    this.complexName,
    this.buildingName,
    this.streetName,
    this.area,
    this.pincode,
    this.city,
    this.state,
    this.mapLocation,
    this.locationGuide,
    this.gstNo,
    this.gstAttachment,
    this.tanNo,
    this.tanAttachment,
    this.msmeNo,
    this.msmeAttachment,
    this.bisNo,
    this.bisAttachment,
    this.brandLogo,
    this.cinNo,
    this.cinAttachment,
    this.shopAttachment,
    this.aadharDetails = const [],
    this.panDetails = const [],
    this.bankDetails = const [],
    this.isFrozen,
    this.kycStatus,
  });

  factory BuyerProfileModel.fromJson(Map<String, dynamic> json) {
    return BuyerProfileModel(
      id: json['id'] ?? 0,
      bpCode: json['bp_code'],
      businessName: json['business_name'],
      name: json['name'],
      mobile: json['mobile'],
      landline: json['landline'],
      email: json['email'],
      businessEmail: json['business_email'],
      referedBy: json['refered_by'],
      moreInfo: json['more'] ?? json['more_info'],
      doorNo: json['door_no'],
      shopNo: json['shop_no'],
      complexName: json['complex_name'],
      buildingName: json['building_name'],
      streetName: json['street_name'],
      area: json['area'],
      pincode: json['pincode'],
      city: json['city'],
      state: json['state'],
      mapLocation: json['map_location'],
      locationGuide: json['location_guide'],
      gstNo: json['gst_no'],
      gstAttachment: json['gst_attachment_url'] ?? json['gst_attachment'],
      tanNo: json['tan_no'],
      tanAttachment: json['tan_attachment_url'] ?? json['tan_attachment'],
      msmeNo: json['msme_no'],
      msmeAttachment: json['msme_attachment_url'] ?? json['msme_attachment'],
      bisNo: json['bis_no'],
      bisAttachment: json['bis_attachment_url'] ?? json['bis_attachment'],
      brandLogo: json['brand_logo_url'] ?? json['brand_logo'],
      cinNo: json['cin_no'],
      cinAttachment: json['cin_attachment_url'] ?? json['cin_attachment'],
      shopAttachment: json['shop_attachment_url'] ?? json['shop'] ?? json['shop_attachment'],
      aadharDetails: (json['aadhar_details'] as List?)?.map((e) => BuyerAadharDetail.fromJson(e)).toList() ?? [],
      panDetails: (json['pan_details'] as List?)?.map((e) => BuyerPanDetail.fromJson(e)).toList() ?? [],
      bankDetails: (json['bank_details'] as List?)?.map((e) => BuyerBankDetail.fromJson(e)).toList() ?? [],
      isFrozen: json['is_frozen'] is int ? json['is_frozen'] : (int.tryParse(json['is_frozen']?.toString() ?? '')),
      kycStatus: json['kyc_status'],
    );
  }

  BuyerProfileModel copyWith({
    int? id,
    String? bpCode,
    String? businessName,
    String? name,
    String? mobile,
    String? landline,
    String? email,
    String? businessEmail,
    String? referedBy,
    String? moreInfo,
    String? doorNo,
    String? shopNo,
    String? complexName,
    String? buildingName,
    String? streetName,
    String? area,
    String? pincode,
    String? city,
    String? state,
    String? mapLocation,
    String? locationGuide,
    String? gstNo,
    String? gstAttachment,
    String? tanNo,
    String? tanAttachment,
    String? msmeNo,
    String? msmeAttachment,
    String? bisNo,
    String? bisAttachment,
    String? brandLogo,
    String? cinNo,
    String? cinAttachment,
    String? shopAttachment,
    List<BuyerAadharDetail>? aadharDetails,
    List<BuyerPanDetail>? panDetails,
    List<BuyerBankDetail>? bankDetails,
    int? isFrozen,
    String? kycStatus,
  }) {
    return BuyerProfileModel(
      id: id ?? this.id,
      bpCode: bpCode ?? this.bpCode,
      businessName: businessName ?? this.businessName,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      landline: landline ?? this.landline,
      email: email ?? this.email,
      businessEmail: businessEmail ?? this.businessEmail,
      referedBy: referedBy ?? this.referedBy,
      moreInfo: moreInfo ?? this.moreInfo,
      doorNo: doorNo ?? this.doorNo,
      shopNo: shopNo ?? this.shopNo,
      complexName: complexName ?? this.complexName,
      buildingName: buildingName ?? this.buildingName,
      streetName: streetName ?? this.streetName,
      area: area ?? this.area,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      mapLocation: mapLocation ?? this.mapLocation,
      locationGuide: locationGuide ?? this.locationGuide,
      gstNo: gstNo ?? this.gstNo,
      gstAttachment: gstAttachment ?? this.gstAttachment,
      tanNo: tanNo ?? this.tanNo,
      tanAttachment: tanAttachment ?? this.tanAttachment,
      msmeNo: msmeNo ?? this.msmeNo,
      msmeAttachment: msmeAttachment ?? this.msmeAttachment,
      bisNo: bisNo ?? this.bisNo,
      bisAttachment: bisAttachment ?? this.bisAttachment,
      brandLogo: brandLogo ?? this.brandLogo,
      cinNo: cinNo ?? this.cinNo,
      cinAttachment: cinAttachment ?? this.cinAttachment,
      shopAttachment: shopAttachment ?? this.shopAttachment,
      aadharDetails: aadharDetails ?? this.aadharDetails,
      panDetails: panDetails ?? this.panDetails,
      bankDetails: bankDetails ?? this.bankDetails,
      isFrozen: isFrozen ?? this.isFrozen,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }
}
