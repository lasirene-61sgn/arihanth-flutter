class ContactInfo {
  final String? value;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branch;
  final String? bankCity;
  final String? bankState;

  const ContactInfo({
    this.value,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.branch,
    this.bankCity,
    this.bankState,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      value: json['value']?.toString(),
      bankName: json['bank_name']?.toString(),
      accountHolderName: json['account_holder_name']?.toString(),
      accountNumber: json['account_number']?.toString(),
      ifscCode: json['ifsc_code']?.toString(),
      branch: json['branch']?.toString(),
      bankCity: json['bank_city']?.toString(),
      bankState: json['bank_state']?.toString(),
    );
  }
}

class CompanyContacts {
  final List<String> mobile;
  final List<String> centrix;
  final List<ContactInfo> bank;
  final List<String> location;
  final List<String> cin;
  final List<String> gst;
  final List<String> hallmark;
  final List<String> email;

  const CompanyContacts({
    this.mobile = const [],
    this.centrix = const [],
    this.bank = const [],
    this.location = const [],
    this.cin = const [],
    this.gst = const [],
    this.hallmark = const [],
    this.email = const [],
  });

  factory CompanyContacts.fromJson(Map<String, dynamic> json) {
    List<String> _parseStrings(String key) =>
        (json[key] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return CompanyContacts(
      mobile: _parseStrings('mobile'),
      centrix: _parseStrings('centrix'),
      bank: (json['bank'] as List<dynamic>? ?? [])
          .map((e) => ContactInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      location: _parseStrings('location'),
      cin: _parseStrings('cin'),
      gst: _parseStrings('gst'),
      hallmark: _parseStrings('hallmark'),
      email: _parseStrings('email'),
    );
  }
}
