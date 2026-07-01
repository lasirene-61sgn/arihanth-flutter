class MeetingParticipantModel {
  final int id;
  final String fullName;
  final String? category;
  final String userCode;

  const MeetingParticipantModel({
    required this.id,
    required this.fullName,
    this.category,
    required this.userCode,
  });

  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) {
    return MeetingParticipantModel(
      id: toInt(json['id']),
      fullName: json['full_name']?.toString() ?? '',
      category: json['category']?.toString(),
      userCode: json['user_code']?.toString() ?? '',
    );
  }
}

int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
