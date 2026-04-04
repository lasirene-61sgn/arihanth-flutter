import 'dart:convert';

class KeyUser {
  final int? id;
  final String? profilePicture;
  final String? userCode;
  final String? bpCode;
  final String? bpName;
  final String? fullName;
  final String? emailId;
  final String? mobileNo;
  final String? status; // Matches "1" from API
  final List<String> permissions;
  final String? dob;
  final String? city;
  final String? state;
  final String? country;
  final String? pinCode;
  final String? aadharPhoto;
  final String? aadharNumber;
  final String? createdAt;
  final String? updatedAt;
  final bool isFrozen;

  KeyUser({
    this.id,
    this.profilePicture,
    this.userCode,
    this.bpCode,
    this.bpName,
    this.fullName,
    this.emailId,
    this.mobileNo,
    this.status,
    this.permissions = const [],
    this.dob,
    this.city,
    this.state,
    this.country,
    this.pinCode,
    this.aadharPhoto,
    this.aadharNumber,
    this.createdAt,
    this.updatedAt,
    this.isFrozen = false,
  });

  factory KeyUser.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is String) {
        try {
          final decoded = jsonDecode(json['permissions']);
          if (decoded is List) {
            parsedPermissions = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      } else if (json['permissions'] is List) {
        parsedPermissions = (json['permissions'] as List).map((e) => e.toString()).toList();
      }
    }

    return KeyUser(
      id: json['id'],
      profilePicture: json['profile_picture'],
      userCode: json['user_code'],
      bpCode: json['bp_code'],
      bpName: json['business_name'],
      fullName: json['full_name'],
      emailId: json['email_id'],
      mobileNo: json['mobile_no'],
      status: json['status']?.toString(), // Handle both int and string
      permissions: parsedPermissions,
      dob: json['dob'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pinCode: json['pincode'],
      aadharPhoto: json['aadhar_photo'],
      aadharNumber: json['aadhar_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isFrozen: json['is_frozen'] == 1 || json['is_frozen'] == true,
    );
  }

  /// Converts model to a Map suitable for ApiClient.requestWithFiles
  /// Null values and empty files are omitted to prevent Dio FormData errors.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (id != null) data['id'] = id.toString();
    if (userCode != null) data['user_code'] = userCode;
    if (bpCode != null) data['bp_code'] = bpCode;
    if (fullName != null) data['full_name'] = fullName;
    if (emailId != null) data['email_id'] = emailId;
    if (mobileNo != null) data['mobile_no'] = mobileNo;
    if (status != null) data['status'] = status;
    
    // Convert permissions list to JSON string (backend format)
    if (permissions.isNotEmpty) {
      data['permissions'] = jsonEncode(permissions);
    }
    
    if (dob != null) data['dob'] = dob;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (country != null) data['country'] = country;
    if (pinCode != null) data['pincode'] = pinCode;
    if (aadharNumber != null) data['aadhar_number'] = aadharNumber;
    
    // Files like profile_picture and aadhar_photo are handled via the `files` param 
    // in requestWithFiles rather than `fields`, but if passed down as string paths, 
    // handle them. Usually for creation, these are local paths passed to `files`.
    
    // data['is_frozen'] = isFrozen ? '1' : '0'; // If needed for creation/edit

    return data;
  }
}