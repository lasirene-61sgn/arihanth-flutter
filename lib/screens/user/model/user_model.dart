import 'dart:convert';

class User {
  final int? id;
  final String? profilePicture;
  final String? profilePictureUrl;
  final String? bpCode;
  final String? userCode;
  final String? bpName;
  final String? fullName;
  final String? name;
  final String? emailId;
  final String? email;
  final String? mobileNo;
  final String? status;
  final String? dob;
  final String? city;
  final String? state;
  final String? country;
  final String? pinCode;
  final String? aadharPhoto;
  final String? aadharNumber;
  final int isFrozen;
  final List<String> permissions;

  // Nested Objects
  final Buyer? buyer;
  final dynamic createdBy; // Can be an int or a User-like Map

  User({
    this.id,
    this.profilePicture,
    this.profilePictureUrl,
    this.bpCode,
    this.bpName,
    this.userCode,
    this.fullName,
    this.name,
    this.emailId,
    this.email,
    this.mobileNo,
    this.status,
    this.dob,
    this.city,
    this.state,
    this.country,
    this.pinCode,
    this.aadharPhoto,
    this.aadharNumber,
    this.isFrozen = 0,
    this.permissions = const [],
    this.buyer,
    this.createdBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Safely parse the permissions string into a List<String>
    List<String> parsedPermissions = [];
    if (json['permissions'] != null && json['permissions'] is String) {
      try {
        parsedPermissions = List<String>.from(jsonDecode(json['permissions']));
      } catch (_) {}
    }

    return User(
      id: json['id'],
      profilePicture: json['profile_picture'],
      profilePictureUrl: json['profile_picture_url'],
      bpCode: json['bp_code'],
      userCode: json['user_code'],
      bpName: json['business_name'],
      fullName: json['full_name'],
      name: json['name'],
      emailId: json['email_id'],
      email: json['email'],
      mobileNo: json['mobile_no'],
      status: json['status']?.toString(),
      dob: json['dob'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pinCode: json['pincode'],
      aadharPhoto: json['aadhar_photo'],
      aadharNumber: json['aadhar_number'],
      isFrozen: json['is_frozen'] ?? 0,
      permissions: parsedPermissions,
      buyer: json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null,
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'user_code': userCode,
      'email': email,
      'mobile_no': mobileNo,
      'status': status,
      'pincode': pinCode,
      'is_frozen': isFrozen,
      'permissions': jsonEncode(permissions),
      'buyer': buyer?.toJson(),
    };
  }
}

class Buyer {
  final int? id;
  final String? businessName;
  final String? gstNo;
  final String? gstAttachmentUrl;
  final String? kycStatus;
  final String? city;
  final String? state;

  Buyer({
    this.id,
    this.businessName,
    this.gstNo,
    this.gstAttachmentUrl,
    this.kycStatus,
    this.city,
    this.state,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) {
    return Buyer(
      id: json['id'],
      businessName: json['business_name'],
      gstNo: json['gst_no'],
      gstAttachmentUrl: json['gst_attachment_url'],
      kycStatus: json['kyc_status'],
      city: json['city'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'gst_no': gstNo,
      'kyc_status': kycStatus,
    };
  }
}