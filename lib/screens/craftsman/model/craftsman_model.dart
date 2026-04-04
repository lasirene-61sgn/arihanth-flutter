import 'dart:convert';

class Craftsman {
  final int id;
  final String? craftmanCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? landline;
  final String? email;
  final String? businessEmail;
  final String? referedBy; // Matches JSON 'refered_by'
  final String? more;
  final String? dear;

  // Address & Location
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

  // KYC Numbers
  final String? panNo;
  final String? gstNo;
  final String? aadharNo;
  final String? bisNo;
  final String? msmeNo;
  final String? tanNo;
  final String? cinNo;

  // Attachment URLs
  final String? panAttachmentUrl;
  final String? gstAttachmentUrl;
  final String? aadharAttachmentUrl; // Mapped from 'aadhar_attach_url'
  final String? bisAttachmentUrl;
  final String? msmeAttachmentUrl;
  final String? tanAttachmentUrl;
  final String? cinAttachmentUrl;
  final String? brandAttachmentUrl;
  final String? passbookUrl;
  final String? imageUrl;

  // Status & Metadata
  final String? kycStatus;
  final int? isFrozen;
  final List<String> permissions;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested details
  final List<AadharDetail> aadharDetails;
  final List<PanDetail> panDetails;
  final List<BankDetail> bankDetails;
  final List<WorkerDetail> workerDetails;

  Craftsman({
    required this.id,
    this.craftmanCode,
    this.businessName,
    this.name,
    this.mobile,
    this.landline,
    this.email,
    this.businessEmail,
    this.referedBy,
    this.more,
    this.dear,
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
    this.panNo,
    this.gstNo,
    this.aadharNo,
    this.bisNo,
    this.msmeNo,
    this.tanNo,
    this.cinNo,
    this.panAttachmentUrl,
    this.gstAttachmentUrl,
    this.aadharAttachmentUrl,
    this.bisAttachmentUrl,
    this.msmeAttachmentUrl,
    this.tanAttachmentUrl,
    this.cinAttachmentUrl,
    this.brandAttachmentUrl,
    this.passbookUrl,
    this.imageUrl,
    this.kycStatus,
    this.isFrozen,
    required this.permissions,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    required this.aadharDetails,
    required this.panDetails,
    required this.bankDetails,
    required this.workerDetails,
  });

  factory Craftsman.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date);
      } catch (_) {
        return null;
      }
    }

    return Craftsman(
      id: json['id'] ?? 0,
      craftmanCode: json['craftman_code'],
      businessName: json['business_name'],
      name: json['name'],
      mobile: json['mobile'],
      landline: json['landline'],
      email: json['email'],
      businessEmail: json['business_email'],
      referedBy: json['refered_by'],
      more: json['more'],
      dear: json['dear'],
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
      panNo: json['pan_no'],
      gstNo: json['gst_no'],
      aadharNo: json['aadhar_no'],
      bisNo: json['bis_no'],
      msmeNo: json['msme_no'],
      tanNo: json['tan_no'],
      cinNo: json['cin_no'],
      panAttachmentUrl: json['pan_attachment_url'],
      gstAttachmentUrl: json['gst_attachment_url'],
      aadharAttachmentUrl: json['aadhar_attach_url'],
      bisAttachmentUrl: json['bis_attachment_url'],
      msmeAttachmentUrl: json['msme_attachment_url'],
      tanAttachmentUrl: json['tan_attachment_url'],
      cinAttachmentUrl: json['cin_attachment_url'],
      brandAttachmentUrl: json['brand_logo'],
      passbookUrl: json['passbook_url'],
      imageUrl: json['image_url'],
      kycStatus: json['kyc_status'],
      isFrozen: json['is_frozen'],
      fcmToken: json['fcm_token'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      aadharDetails: (json['aadhar_details'] as List?)
          ?.map((e) => AadharDetail.fromJson(e))
          .toList() ?? [],
      panDetails: (json['pan_details'] as List?)
          ?.map((e) => PanDetail.fromJson(e))
          .toList() ?? [],
      bankDetails: (json['bank_details'] as List?)
          ?.map((e) => BankDetail.fromJson(e))
          .toList() ?? [],
      workerDetails: (json['workers'] as List?)
          ?.map((e) => WorkerDetail.fromJson(e))
          .toList() ?? [],
    );
  }
}

class AadharDetail {
  final int id;
  final int craftmanId;
  final String? aadharName;
  final String? aadharNumber;
  final String? aadharImageUrl;

  AadharDetail({
    required this.id,
    required this.craftmanId,
    this.aadharName,
    this.aadharNumber,
    this.aadharImageUrl,
  });

  factory AadharDetail.fromJson(Map<String, dynamic> json) {
    return AadharDetail(
      id: json['id'] ?? 0,
      craftmanId: json['craftman_id'] ?? 0,
      aadharName: json['aadhar_name'],
      aadharNumber: json['aadhar_number'],
      aadharImageUrl: json['aadhar_image_url'],
    );
  }
}

class PanDetail {
  final int id;
  final int craftmanId;
  final String? panNumber;
  final String? panImageUrl;

  PanDetail({
    required this.id,
    required this.craftmanId,
    this.panNumber,
    this.panImageUrl,
  });

  factory PanDetail.fromJson(Map<String, dynamic> json) {
    return PanDetail(
      id: json['id'] ?? 0,
      craftmanId: json['craftman_id'] ?? 0,
      panNumber: json['pan_number'],
      panImageUrl: json['pan_image_url'],
    );
  }
}
class WorkerDetail {
  final int id;
  final int workerId;
  final String? workerNumber;
  final String? workerName;
  final String? workerImage; // This maps to worker_image_url
  final String? createdAt;
  final String? updatedAt;

  WorkerDetail({
    required this.id,
    required this.workerId,
    this.workerNumber,
    this.workerName,
    this.workerImage,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkerDetail.fromJson(Map<String, dynamic> json) {
    return WorkerDetail(
      // Parsing ID as int, handles if the server sends it as a string accidentally
      id: int.tryParse(json['id'].toString()) ?? 0,
      workerId: int.tryParse(json['craftman_id'].toString()) ?? 0,
      workerNumber: json['worker_number']?.toString(),
      workerName: json['worker_name']?.toString(),
      // Use worker_image_url for the full path to display in the UI
      workerImage: json['worker_image_url'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'craftman_id': workerId,
      'worker_name': workerName,
      'worker_number': workerNumber,
      'worker_image_url': workerImage,
    };
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
      passbookUrl: json['passbook_image_url'],
    );
  }
}