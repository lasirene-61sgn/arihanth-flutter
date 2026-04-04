import 'dart:convert';

class Buyer {
  final int id;
  final String? bpCode;
  final String? businessName;
  final String? name;
  final String? dear;
  final String? mobile;
  final String? landline; // Added
  final String? email;
  final String? businessEmail;
  final String? referedBy;
  final String? more;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;

  // Address breakdown
  final String? doorNo;
  final String? shopNo;
  final String? complexName;
  final String? buildingName;
  final String? streetName;

  // Location details
  final String? mapLocation;
  final String? locationGuide;

  // KYC Numbers
  final String? gstNo;
  final String? panNo;
  final String? aadharNo;
  final String? tanNo;
  final String? msmeNo;
  final String? bisNo;
  final String? cinNo;

  final String? kycStatus;
  final int? isFrozen;
  final List<String> permissions;

  // Attachment URLs
  final String? gstAttachmentUrl;
  final String? panAttachmentUrl;
  final String? aadharAttachmentUrl;
  final String? tanAttachmentUrl;
  final String? msmeAttachmentUrl;
  final String? bisAttachmentUrl;
  final String? cinAttachmentUrl;
  final String? brandAttachmentUrl;
  final String? passbookUrl;
  final String? imageUrl; // Profile image

  // Nested details
  final List<AadharDetail> aadharDetails;
  final List<PanDetail> panDetails;
  final List<BankDetail> bankDetails;

  Buyer({
    required this.id,
    this.bpCode,
    this.businessName,
    this.name,
    this.dear,
    this.mobile,
    this.landline,
    this.email,
    this.businessEmail,
    this.referedBy,
    this.more,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.mapLocation,
    this.locationGuide,
    this.doorNo,
    this.shopNo,
    this.complexName,
    this.buildingName,
    this.streetName,
    this.gstNo,
    this.panNo,
    this.aadharNo,
    this.tanNo,
    this.msmeNo,
    this.bisNo,
    this.cinNo,
    this.kycStatus,
    this.isFrozen,
    required this.permissions,
    this.gstAttachmentUrl,
    this.panAttachmentUrl,
    this.aadharAttachmentUrl,
    this.tanAttachmentUrl,
    this.msmeAttachmentUrl,
    this.bisAttachmentUrl,
    this.cinAttachmentUrl,
    this.brandAttachmentUrl,
    this.passbookUrl,
    this.imageUrl,
    required this.aadharDetails,
    required this.panDetails,
    required this.bankDetails,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = [];
    final rawPermissions = json['permissions'];
    if (rawPermissions is List) {
      parsedPermissions = rawPermissions.map((e) => e.toString()).toList();
    }

    return Buyer(
      id: json['id'] ?? 0,
      bpCode: json['bp_code'],
      businessName: json['business_name'],
      name: json['name'],
      dear: json['dear'],
      mobile: json['mobile'],
      landline: json['landline'],
      email: json['email'],
      businessEmail: json['business_email'],
      referedBy: json['refered_by'],
      more: json['more'],
      area: json['area'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      mapLocation: json['map_location'],
      locationGuide: json['location_guide'],
      doorNo: json['door_no'],
      shopNo: json['shop_no'],
      complexName: json['complex_name'],
      buildingName: json['building_name'],
      streetName: json['street_name'],
      gstNo: json['gst_no'],
      panNo: json['pan_no'],
      aadharNo: json['aadhar_no'],
      tanNo: json['tan_no'],
      msmeNo: json['msme_no'],
      bisNo: json['bis_no'],
      cinNo: json['cin_no'],
      kycStatus: json['kyc_status'],
      isFrozen: json['is_frozen'],
      permissions: parsedPermissions,
      imageUrl: json['image_url'],

      // Document URLs matching JSON keys
      gstAttachmentUrl: json['gst_attachment_url'],
      panAttachmentUrl: json['pan_attachment_url'],
      aadharAttachmentUrl: json['aadhar_attach_url'], // Matches JSON key
      tanAttachmentUrl: json['tan_attachment_url'],
      msmeAttachmentUrl: json['msme_attachment_url'],
      bisAttachmentUrl: json['bis_attachment_url'],
      cinAttachmentUrl: json['cin_attachment_url'],
      brandAttachmentUrl: json['brand_attachment_url'],
      passbookUrl: json['passbook_url'],

      aadharDetails: (json['aadhar_details'] as List?)
          ?.map((e) => AadharDetail.fromJson(e))
          .toList() ?? [],
      panDetails: (json['pan_details'] as List?)
          ?.map((e) => PanDetail.fromJson(e))
          .toList() ?? [],
      bankDetails: (json['bank_details'] as List?)
          ?.map((e) => BankDetail.fromJson(e))
          .toList() ?? [],
    );
  }
}

class BankDetail {
  final String? bankName;
  final String? accountName;
  final String? accountNo;
  final String? ifscCode;
  final String? branch;
  final String? bankCity;
  final String? bankState;
  final String? note;
  final String? passbookUrl;

  BankDetail({
    this.bankName,
    this.accountName,
    this.accountNo,
    this.ifscCode,
    this.branch,
    this.bankCity,
    this.bankState,
    this.note,
    this.passbookUrl,
  });

  factory BankDetail.fromJson(Map<String, dynamic> json) {
    return BankDetail(
      bankName: json['bank_name'],
      accountName: json['account_holder_name'],
      accountNo: json['account_number'],
      ifscCode: json['ifsc_code'],
      branch: json['branch'],
      bankCity: json['bank_city'],
      bankState: json['bank_state'],
      note: json['note'],
      passbookUrl:  json['passbook_image_url'],
    );
  }
}

class AadharDetail {
  final int id;
  final int buyerId;
  final String? aadharName;
  final String? aadharNumber;
  final String? aadharImageUrl;

  AadharDetail({
    required this.id,
    required this.buyerId,
    this.aadharName,
    this.aadharNumber,
    this.aadharImageUrl,
  });

  factory AadharDetail.fromJson(Map<String, dynamic> json) {
    return AadharDetail(
      id: json['id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      aadharName: json['aadhar_name'],
      aadharNumber: json['aadhar_number'],
      aadharImageUrl: json['aadhar_image_url'],
    );
  }
}

class PanDetail {
  final int id;
  final int buyerId;
  final String? panNumber;
  final String? panImageUrl;

  PanDetail({
    required this.id,
    required this.buyerId,
    this.panNumber,
    this.panImageUrl,
  });

  factory PanDetail.fromJson(Map<String, dynamic> json) {
    return PanDetail(
      id: json['id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      panNumber: json['pan_number'],
      panImageUrl: json['pan_image_url'],
    );
  }
}