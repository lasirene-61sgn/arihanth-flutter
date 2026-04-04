// ================= BUSINESS PARTNER MODEL =================

class BusinessPartner {
  final int id;
  final String? role;
  final String? bpCode;
  final String? businessName;
  final String? name;
  final String? mobile;
  final String? landline;
  final String? businessEmail;
  final String? referedBy;
  final String? more;

  // PAN
  final String? panName;
  final String? panNo;
  final String? panAttachment;
  final String? panAttachmentUrl;

  // GST
  final String? gstNo;
  final String? gstAttachment;
  final String? gstAttachmentUrl;

  final String? imageUrl;
  final String? aadharAttachmentUrl;
  final String? passbookUrl;

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
  final String? country;
  final String? mapLocation;
  final String? locationGuide;

  // Extra Contacts (FIXED – NOT LIST)
  final String? dummyName1;
  final String? dummyEmail1;
  final String? dummyMobile1;

  final String? dummyName2;
  final String? dummyEmail2;
  final String? dummyMobile2;

  final String? dummyName3;
  final String? dummyEmail3;
  final String? dummyMobile3;

  BusinessPartner({
    required this.id,
    this.role,
    this.bpCode,
    this.businessName,
    this.name,
    this.mobile,
    this.landline,
    this.businessEmail,
    this.referedBy,
    this.more,

    this.panName,
    this.panNo,
    this.panAttachment,
    this.panAttachmentUrl,

    this.gstNo,
    this.gstAttachment,
    this.gstAttachmentUrl,

    this.imageUrl,
    this.aadharAttachmentUrl,
    this.passbookUrl,

    this.doorNo,
    this.shopNo,
    this.complexName,
    this.buildingName,
    this.streetName,
    this.area,
    this.pincode,
    this.city,
    this.state,
    this.country,
    this.mapLocation,
    this.locationGuide,

    this.dummyName1,
    this.dummyEmail1,
    this.dummyMobile1,
    this.dummyName2,
    this.dummyEmail2,
    this.dummyMobile2,
    this.dummyName3,
    this.dummyEmail3,
    this.dummyMobile3,
  });

  // ================= FROM JSON =================

  factory BusinessPartner.fromJson(Map<String, dynamic> json) {
    String? safe(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return BusinessPartner(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,

      role: json['role'] ?? (json['bp_code'] != null ? 'Buyer' : (json['craftman_code'] != null ? 'Craftsman' : null)),
      bpCode: safe(json['bp_code'] ?? json['craftman_code']),
      businessName: safe(json['business_name']),
      name: safe(json['name']),
      mobile: safe(json['mobile']),
      landline: safe(json['landline']),
      businessEmail: safe(json['business_email']),
      referedBy: safe(json['refered_by']),
      more: safe(json['more']),

      panName: safe(json['pan_name']),
      panNo: safe(json['pan_no']),
      panAttachment: safe(json['pan_attachment']),
      panAttachmentUrl: safe(json['pan_attachment_url']),

      gstNo: safe(json['gst_no']),
      gstAttachment: safe(json['gst_attachment']),
      gstAttachmentUrl: safe(json['gst_attachment_url']),

      imageUrl: safe(json['image_url']),
      aadharAttachmentUrl: safe(json['aadhar_attach_url']),
      passbookUrl: safe(json['passbook_url']),

      doorNo: safe(json['door_no']),
      shopNo: safe(json['shop_no']),
      complexName: safe(json['complex_name']),
      buildingName: safe(json['building_name']),
      streetName: safe(json['street_name']),
      area: safe(json['area']),
      pincode: safe(json['pincode']),
      city: safe(json['city']),
      state: safe(json['state']),
      country: safe(json['country']),
      mapLocation: safe(json['map_location']),
      locationGuide: safe(json['location_guide']),

      dummyName1: safe(json['dummy_name1']),
      dummyEmail1: safe(json['dummy_email1']),
      dummyMobile1: safe(json['dummy_mobile1']),

      dummyName2: safe(json['dummy_name2']),
      dummyEmail2: safe(json['dummy_email2']),
      dummyMobile2: safe(json['dummy_mobile2']),

      dummyName3: safe(json['dummy_name3']),
      dummyEmail3: safe(json['dummy_email3']),
      dummyMobile3: safe(json['dummy_mobile3']),
    );
  }

  // ================= TO JSON =================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'bp_code': bpCode,
      'business_name': businessName,
      'name': name,
      'mobile': mobile,
      'landline': landline,
      'business_email': businessEmail,
      'refered_by': referedBy,
      'more': more,

      'pan_name': panName,
      'pan_no': panNo,
      'pan_attachment': panAttachment,

      'gst_no': gstNo,
      'gst_attachment': gstAttachment,

      'door_no': doorNo,
      'shop_no': shopNo,
      'complex_name': complexName,
      'building_name': buildingName,
      'street_name': streetName,
      'area': area,
      'pincode': pincode,
      'city': city,
      'state': state,
      'country': country,
      'map_location': mapLocation,
      'location_guide': locationGuide,

      'dummy_name1': dummyName1,
      'dummy_email1': dummyEmail1,
      'dummy_mobile1': dummyMobile1,

      'dummy_name2': dummyName2,
      'dummy_email2': dummyEmail2,
      'dummy_mobile2': dummyMobile2,

      'dummy_name3': dummyName3,
      'dummy_email3': dummyEmail3,
      'dummy_mobile3': dummyMobile3,
    };
  }
}
