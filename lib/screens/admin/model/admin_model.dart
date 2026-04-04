import 'dart:convert';

class Admin {
  final int id;
  final String? role;
  final List<String> permissions;
  final String? profilePicture;
  final String? userCode;
  final String? bpCode;
  final String? fullName;
  final String? emailId;
  final String? mobileNo;
  final int? status;
  final String? dob;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final String? aadharPhoto;
  final String? aadharNumber;
  final String? createdAt;
  final String? updatedAt;
  final int? isFrozen;

  Admin({
    required this.id,
    this.role,
    required this.permissions,
    this.profilePicture,
    this.userCode,
    this.bpCode,
    this.fullName,
    this.emailId,
    this.mobileNo,
    this.status,
    this.dob,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.aadharPhoto,
    this.aadharNumber,
    this.createdAt,
    this.updatedAt,
    this.isFrozen,
  });
  factory Admin.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];

    List<String> parsedPermissions = [];

    if (rawPermissions is List) {
      parsedPermissions =
          rawPermissions.map((e) => e.toString()).toList();
    } else if (rawPermissions is String) {
      try {
        final decoded = jsonDecode(rawPermissions);
        if (decoded is List) {
          parsedPermissions = decoded.map((e) => e.toString()).toList();
        } else {
          parsedPermissions = [rawPermissions];
        }
      } catch (e) {
        parsedPermissions = [rawPermissions];
      }
    }

    return Admin(
      id: json['id'] ?? 0,
      role: json['role'],
      permissions: parsedPermissions,
      profilePicture: json['profile_picture'],
      userCode: json['user_code'],
      bpCode: json['bp_code'],
      fullName: json['full_name'],
      emailId: json['email_id'],
      mobileNo: json['mobile_no'],
      status: json['status'],
      dob: json['dob'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      aadharPhoto: json['aadhar_photo'],
      aadharNumber: json['aadhar_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isFrozen: json['is_frozen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'permissions': permissions,
      'profile_picture': profilePicture,
      'user_code': userCode,
      'bp_code': bpCode,
      'full_name': fullName,
      'email_id': emailId,
      'mobile_no': mobileNo,
      'status': status,
      'dob': dob,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'aadhar_photo': aadharPhoto,
      'aadhar_number': aadharNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_frozen': isFrozen,
    };
  }
}