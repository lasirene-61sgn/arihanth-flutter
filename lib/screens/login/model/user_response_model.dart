class UserLoginResponse {
  final bool success;
  final String message;
  final String token;
  final int userId;
  final String fullName;
  final String email;
  final String? mobile;
  final String role;
  final String? userCode;
  final String? bpCode;
  final String? businessName;
  final String? image;
  final String? aadharNo;

  UserLoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    this.mobile,
    required this.role,
    this.userCode,
    this.bpCode,
    this.businessName,
    this.image,
    this.aadharNo,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    // ApiClient wraps the response body in 'data'
    final data = json['data'] ?? {};
    final user = data['user'] ?? {};

    return UserLoginResponse(
      success: data['success'] ?? false,
      message: data['message'] ?? '',
      token: data['token'] ?? '',
      userId: user['id'] ?? 0,
      fullName: user['name'] ?? user['full_name'] ?? '',
      email: user['email'] ?? user['email_id'] ?? '',
      mobile: user['mobile'] ?? user['mobile_no'],
      role: data['role'] ?? user['role'] ?? '',
      userCode: user['user_code'],
      bpCode: user['bp_code'],
      businessName: user['business_name'],
      image: user['image'],
      aadharNo: user['aadhar_no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'role': role,
      'user_code': userCode,
      'bp_code': bpCode,
      'business_name': businessName,
      'image': image,
      'aadhar_no': aadharNo,
    };
  }
}
