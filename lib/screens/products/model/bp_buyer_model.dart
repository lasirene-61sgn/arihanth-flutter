class BpBuyerModel {
  final int? id;
  final String? bpCode;
  final String? businessName;
  final String? mobile;
  final String? gstNo;
  final String? imageUrl;
  final String? bisAttachmentUrl;
  final String? gstAttachmentUrl;
  final String? msmeAttachmentUrl;
  final String? panAttachmentUrl;
  final String? tanAttachmentUrl;
  final String? cinAttachmentUrl;
  final String? aadharAttachUrl;
  final String? passbookUrl;

  BpBuyerModel({
    this.id,
    this.bpCode,
    this.businessName,
    this.mobile,
    this.gstNo,
    this.imageUrl,
    this.bisAttachmentUrl,
    this.gstAttachmentUrl,
    this.msmeAttachmentUrl,
    this.panAttachmentUrl,
    this.tanAttachmentUrl,
    this.cinAttachmentUrl,
    this.aadharAttachUrl,
    this.passbookUrl,
  });

  /// ✅ From JSON
  factory BpBuyerModel.fromJson(Map<String, dynamic> json) {
    return BpBuyerModel(
      id: json['id'],
      bpCode: json['bp_code'] ?? json['craftman_code'] ?? '',
      businessName: json['business_name'] ?? '',
      mobile: json['mobile'] ?? '',
      gstNo: json['gst_no'] ?? '',
      imageUrl: json['image_url'],
      bisAttachmentUrl: json['bis_attachment_url'],
      gstAttachmentUrl: json['gst_attachment_url'],
      msmeAttachmentUrl: json['msme_attachment_url'],
      panAttachmentUrl: json['pan_attachment_url'],
      tanAttachmentUrl: json['tan_attachment_url'],
      cinAttachmentUrl: json['cin_attachment_url'],
      aadharAttachUrl: json['aadhar_attach_url'],
      passbookUrl: json['passbook_url'],
    );
  }

  /// ✅ To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bp_code': bpCode,
      'business_name': businessName,
      'mobile': mobile,
      'gst_no': gstNo,
      'image_url': imageUrl,
      'bis_attachment_url': bisAttachmentUrl,
      'gst_attachment_url': gstAttachmentUrl,
      'msme_attachment_url': msmeAttachmentUrl,
      'pan_attachment_url': panAttachmentUrl,
      'tan_attachment_url': tanAttachmentUrl,
      'cin_attachment_url': cinAttachmentUrl,
      'aadhar_attach_url': aadharAttachUrl,
      'passbook_url': passbookUrl,
    };
  }

  /// ✅ CopyWith
  BpBuyerModel copyWith({
    int? id,
    String? bpCode,
    String? businessName,
    String? mobile,
    String? gstNo,
    String? imageUrl,
    String? bisAttachmentUrl,
    String? gstAttachmentUrl,
    String? msmeAttachmentUrl,
    String? panAttachmentUrl,
    String? tanAttachmentUrl,
    String? cinAttachmentUrl,
    String? aadharAttachUrl,
    String? passbookUrl,
  }) {
    return BpBuyerModel(
      id: id ?? this.id,
      bpCode: bpCode ?? this.bpCode,
      businessName: businessName ?? this.businessName,
      mobile: mobile ?? this.mobile,
      gstNo: gstNo ?? this.gstNo,
      imageUrl: imageUrl ?? this.imageUrl,
      bisAttachmentUrl: bisAttachmentUrl ?? this.bisAttachmentUrl,
      gstAttachmentUrl: gstAttachmentUrl ?? this.gstAttachmentUrl,
      msmeAttachmentUrl: msmeAttachmentUrl ?? this.msmeAttachmentUrl,
      panAttachmentUrl: panAttachmentUrl ?? this.panAttachmentUrl,
      tanAttachmentUrl: tanAttachmentUrl ?? this.tanAttachmentUrl,
      cinAttachmentUrl: cinAttachmentUrl ?? this.cinAttachmentUrl,
      aadharAttachUrl: aadharAttachUrl ?? this.aadharAttachUrl,
      passbookUrl: passbookUrl ?? this.passbookUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BpBuyerModel &&
      other.id == id &&
      other.bpCode == bpCode &&
      other.businessName == businessName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      bpCode.hashCode ^
      businessName.hashCode;
  }
}