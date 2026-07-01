class NewUpdateModel {
  final int id;
  final String? newupdates;
  final String? title;
  final String? description;
  final String? duration;
  final String? mediaPath;
  final String? mediaType;
  final String? targetAudience;
  final String? targetBuyers;
  final String? targetCraftsmen;

  final String? mediaUrl;
  final bool isSeen;

  const NewUpdateModel({
    required this.id,
    this.newupdates,
    this.title,
    this.description,
    this.duration,
    this.mediaPath,
    this.mediaType,
    this.targetAudience,
    this.targetBuyers,
    this.targetCraftsmen,
    this.mediaUrl,
    this.isSeen = false,
  });

  factory NewUpdateModel.fromJson(Map<String, dynamic> json) {
    return NewUpdateModel(
      id: toInt(json['id']),
      newupdates: json['newupdates']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      duration: json['duration']?.toString(),
      mediaPath: json['media_path']?.toString(),
      mediaType: json['media_type']?.toString(),
      targetAudience: json['target_audience']?.toString(),
      targetBuyers: json['target_buyers']?.toString(),
      targetCraftsmen: json['target_craftsmen']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      isSeen: json['is_seen'] == true,
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
