import 'dart:convert';

class CraftsmanStaff {
  final int? id;
  final int? craftsmanId;
  final String? staffCode;
  final String? name;
  final String? email;
  final String? mobileNo;
  final String? aadharNumber;
  final String? image;
  final String? aadharImage;
  final bool isActive;
  final String? passwordPlain;
  final List<String> permissions;

  // Nested Objects
  final Craftsman? craftsman;

  CraftsmanStaff({
    this.id,
    this.craftsmanId,
    this.staffCode,
    this.name,
    this.email,
    this.mobileNo,
    this.aadharNumber,
    this.image,
    this.aadharImage,
    this.isActive = true,
    this.passwordPlain,
    this.permissions = const [],
    this.craftsman,
  });

  factory CraftsmanStaff.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is String) {
        try {
          parsedPermissions = List<String>.from(jsonDecode(json['permissions']));
        } catch (_) {}
      } else if (json['permissions'] is List) {
        parsedPermissions = List<String>.from(json['permissions']);
      }
    }

    return CraftsmanStaff(
      id: json['id'],
      craftsmanId: json['craftsman_id'],
      staffCode: json['staff_code'],
      name: json['name'],
      email: json['email'],
      mobileNo: json['mobile'],
      aadharNumber: json['aadhar_number'],
      image: json['image'],
      aadharImage: json['aadhar_image'],
      isActive: json['is_active'] ?? true,
      passwordPlain: json['password_plain'],
      permissions: parsedPermissions,
      craftsman: json['craftsman'] != null ? Craftsman.fromJson(json['craftsman']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'craftsman_id': craftsmanId,
      'staff_code': staffCode,
      'name': name,
      'email': email,
      'mobile': mobileNo,
      'aadhar_number': aadharNumber,
      'is_active': isActive,
      'permissions': permissions,
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
  final String? city;
  final String? state;

  Craftsman({
    this.id,
    this.craftmanCode,
    this.businessName,
    this.name,
    this.mobile,
    this.email,
    this.city,
    this.state,
  });

  factory Craftsman.fromJson(Map<String, dynamic> json) {
    return Craftsman(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'craftman_code': craftmanCode,
      'business_name': businessName,
      'name': name,
      'mobile': mobile,
      'email': email,
      'city': city,
      'state': state,
    };
  }
}