class ChatModel {
  final int? id;
  final String? bpCode;
  final String? name;
  final String? mobile;
  final String? lastMessage;
  final String? lastMessageTime;
  final int? unreadCount;
  final String? type;
  final String? imageUrl;

  ChatModel({
    this.id,
    this.bpCode,
    this.name,
    this.type,
    this.mobile,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
    this.imageUrl,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      bpCode: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? json['business_name']?.toString() ?? '',
      type: json['type']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time']?.toString(),
      unreadCount: json['unread_count'] is int ? json['unread_count'] : 0,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bp_code': bpCode,
      'name': name,
      'type': type,
      'mobile': mobile,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
      'image_url': imageUrl,
    };
  }

  ChatModel copyWith({
    int? id,
    String? bpCode,
    String? name,
    String? type,
    String? mobile,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    String? imageUrl,
  }) {
    return ChatModel(
      id: id ?? this.id,
      bpCode: bpCode ?? this.bpCode,
      name: name ?? this.name,
      type: type ?? this.type,
      mobile: mobile ?? this.mobile,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
