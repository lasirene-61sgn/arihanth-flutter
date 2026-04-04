class PincodeResponse {
  final String status;
  final String message;
  final List<PincodePostOffice>? postOffices;

  PincodeResponse({
    required this.status,
    required this.message,
    this.postOffices,
  });

  factory PincodeResponse.fromJson(Map<String, dynamic> json) {
    return PincodeResponse(
      status: json['Status']?.toString() ?? '',
      message: json['Message']?.toString() ?? '',
      postOffices: json['PostOffice'] != null
          ? (json['PostOffice'] as List)
          .map((item) => PincodePostOffice.fromJson(item))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'Status': status,
    'Message': message,
    'PostOffice': postOffices?.map((e) => e.toJson()).toList(),
  };

  bool get isSuccess => status.toUpperCase() == 'SUCCESS';
  bool get hasData => postOffices != null && postOffices!.isNotEmpty;
}

class PincodePostOffice {
  final String name;
  final String description;
  final String branchType;
  final String deliveryStatus;
  final String divisionName;
  final String regionName;
  final String circleName;
  final String taluk;
  final String districtName;
  final String stateName;
  final String pincode;

  PincodePostOffice({
    required this.name,
    required this.description,
    required this.branchType,
    required this.deliveryStatus,
    required this.divisionName,
    required this.regionName,
    required this.circleName,
    required this.taluk,
    required this.districtName,
    required this.stateName,
    required this.pincode,
  });

// Update these lines in PincodePostOffice.fromJson inside pin_code_model.dart
  factory PincodePostOffice.fromJson(Map<String, dynamic> json) {
    return PincodePostOffice(
      name: json['Name']?.toString() ?? '',
      description: json['Description']?.toString() ?? '',
      branchType: json['BranchType']?.toString() ?? '',
      deliveryStatus: json['DeliveryStatus']?.toString() ?? '',
      divisionName: json['Division']?.toString() ?? '', // Changed from DivisionName
      regionName: json['Region']?.toString() ?? '',     // Changed from RegionName
      circleName: json['Circle']?.toString() ?? '',     // Changed from CircleName
      taluk: json['Block']?.toString() ?? '',          // API often uses 'Block' for Taluk/Area
      districtName: json['District']?.toString() ?? '', // Changed from DistrictName
      stateName: json['State']?.toString() ?? '',       // Changed from StateName
      pincode: json['Pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Description': description,
    'BranchType': branchType,
    'DeliveryStatus': deliveryStatus,
    'DivisionName': divisionName,
    'RegionName': regionName,
    'CircleName': circleName,
    'Taluk': taluk,
    'DistrictName': districtName,
    'StateName': stateName,
    'Pincode': pincode,
  };

  /// Get formatted address string
  String get formattedAddress {
    final parts = [
      if (name.isNotEmpty) name,
      if (taluk.isNotEmpty) taluk,
      if (districtName.isNotEmpty) districtName,
      if (stateName.isNotEmpty) stateName,
      if (pincode.isNotEmpty) pincode,
    ];
    return parts.join(', ');
  }
}