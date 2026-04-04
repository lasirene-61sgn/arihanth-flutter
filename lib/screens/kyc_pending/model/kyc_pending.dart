class KycBuyer {
  final int id;
  final String bpCode;
  final String businessName;
  final String name;
  final String mobile;
  final String? email;
  final String? city;
  final String? state;
  final String? gstNo;
  final String? panNo;
  final String? aadharNo;
  final String kycStatus;
  final List<AadharDetails> aadharDetails;
  final List<PanDetails> panDetails;

  KycBuyer({
    required this.id,
    required this.bpCode,
    required this.businessName,
    required this.name,
    required this.mobile,
    this.email,
    this.city,
    this.state,
    this.gstNo,
    this.panNo,
    this.aadharNo,
    required this.kycStatus,
    required this.aadharDetails,
    required this.panDetails,
  });

  factory KycBuyer.fromJson(Map<String, dynamic> json) {
    return KycBuyer(
      id: json['id'] ?? 0,
      bpCode: json['bp_code'] ?? '',
      businessName: json['business_name'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      city: json['city'],
      state: json['state'],
      gstNo: json['gst_no'],
      panNo: json['pan_no'],
      aadharNo: json['aadhar_no'],
      kycStatus: json['kyc_status'] ?? '',
      aadharDetails: (json['aadhar_details'] as List? ?? [])
          .map((e) => AadharDetails.fromJson(e))
          .toList(),
      panDetails: (json['pan_details'] as List? ?? [])
          .map((e) => PanDetails.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bp_code': bpCode,
    'business_name': businessName,
    'name': name,
    'mobile': mobile,
    'email': email,
    'city': city,
    'state': state,
    'gst_no': gstNo,
    'pan_no': panNo,
    'aadhar_no': aadharNo,
    'kyc_status': kycStatus,
  };
}
class KycCraftsman {
  final int id;
  final String craftmanCode;
  final String businessName;
  final String name;
  final String mobile;
  final String? email;
  final String? city;
  final String? state;
  final String? gstNo;
  final String? panNo;
  final String? aadharNo;
  final String kycStatus;
  final List<AadharDetails> aadharDetails;
  final List<PanDetails> panDetails;

  KycCraftsman({
    required this.id,
    required this.craftmanCode,
    required this.businessName,
    required this.name,
    required this.mobile,
    this.email,
    this.city,
    this.state,
    this.gstNo,
    this.panNo,
    this.aadharNo,
    required this.kycStatus,
    required this.aadharDetails,
    required this.panDetails,
  });

  factory KycCraftsman.fromJson(Map<String, dynamic> json) {
    return KycCraftsman(
      id: json['id'] ?? 0,
      craftmanCode: json['craftman_code'] ?? '',
      businessName: json['business_name'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'],
      city: json['city'],
      state: json['state'],
      gstNo: json['gst_no'],
      panNo: json['pan_no'],
      aadharNo: json['aadhar_no'],
      kycStatus: json['kyc_status'] ?? '',
      aadharDetails: (json['aadhar_details'] as List? ?? [])
          .map((e) => AadharDetails.fromJson(e))
          .toList(),
      panDetails: (json['pan_details'] as List? ?? [])
          .map((e) => PanDetails.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'craftman_code': craftmanCode,
    'business_name': businessName,
    'name': name,
    'mobile': mobile,
    'email': email,
    'city': city,
    'state': state,
    'gst_no': gstNo,
    'pan_no': panNo,
    'aadhar_no': aadharNo,
    'kyc_status': kycStatus,
  };
}
class AadharDetails {
  final int id;
  final String aadharName;
  final String aadharNumber;
  final String? aadharImageUrl;

  AadharDetails({
    required this.id,
    required this.aadharName,
    required this.aadharNumber,
    this.aadharImageUrl,
  });

  factory AadharDetails.fromJson(Map<String, dynamic> json) {
    return AadharDetails(
      id: json['id'] ?? 0,
      aadharName: json['aadhar_name'] ?? '',
      aadharNumber: json['aadhar_number'] ?? '',
      aadharImageUrl: json['aadhar_image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'aadhar_name': aadharName,
    'aadhar_number': aadharNumber,
  };
}

class PanDetails {
  final int id;
  final String panNumber;
  final String? panImageUrl;

  PanDetails({
    required this.id,
    required this.panNumber,
    this.panImageUrl,
  });

  factory PanDetails.fromJson(Map<String, dynamic> json) {
    return PanDetails(
      id: json['id'] ?? 0,
      panNumber: json['pan_number'] ?? '',
      panImageUrl: json['pan_image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pan_number': panNumber,
  };
}