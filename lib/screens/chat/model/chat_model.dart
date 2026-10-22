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

  final int? conversationId;
  final String? badge;
  final bool? canMessage;
  final bool isGroup;
  final String? chatType;

  ChatModel({
    this.id,
    this.conversationId,
    this.bpCode,
    this.name,
    this.type,
    this.mobile,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
    this.imageUrl,
    this.badge,
    this.canMessage,
    this.isGroup = false,
    this.chatType,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final bool isGroupChat = json['is_group'] == true ||
        json['chat_type'] == 'group' ||
        json['type'] == 'group';

    // If it's a recent chat object, conversation details are at top level or partner is inside
    final partner = json['partner'] is Map<String, dynamic>
        ? json['partner'] as Map<String, dynamic>
        : (json['partner'] is Map ? Map<String, dynamic>.from(json['partner']) : null);
    final group = json['group'] is Map<String, dynamic>
        ? json['group'] as Map<String, dynamic>
        : (json['group'] is Map ? Map<String, dynamic>.from(json['group']) : null);

    final target = partner ?? group ?? json;

    final id = target['id'] is int ? target['id'] : int.tryParse(target['id']?.toString() ?? '');
    final convId = json['conversation_id'] is int 
        ? json['conversation_id'] 
        : (json['id'] is int && (partner != null || isGroupChat)
            ? json['id']
            : int.tryParse(json['conversation_id']?.toString() ?? ''));

    // Extract recent/latest message
    final msgObj = json['recent_message'] ?? json['latest_message'] ?? json['last_message'];
    String? lastMsgText;
    String? lastMsgTime;
    if (msgObj is Map) {
      lastMsgText = msgObj['body']?.toString() ??
          msgObj['content']?.toString() ??
          msgObj['message']?.toString() ??
          msgObj['text']?.toString();
      lastMsgTime = msgObj['created_at']?.toString();
    } else if (msgObj is String) {
      lastMsgText = msgObj;
    }

    // Fallback timestamp to last_message_at or updated_at or created_at
    lastMsgTime ??= json['last_message_at']?.toString() ??
        json['last_message_time']?.toString() ??
        json['updated_at']?.toString() ??
        json['created_at']?.toString();

    // Group name or individual name
    final displayName = json['name']?.toString() ??
        target['name']?.toString() ??
        target['label']?.toString() ??
        target['title']?.toString() ??
        target['group_name']?.toString() ??
        target['business_name']?.toString() ??
        '';

    return ChatModel(
      id: id,
      conversationId: convId,
      bpCode: target['code']?.toString() ?? target['bp_code']?.toString() ?? '',
      name: displayName,
      type: isGroupChat ? 'group' : (target['type']?.toString() ?? json['chat_type']?.toString()),
      mobile: target['mobile']?.toString() ?? '',
      lastMessage: lastMsgText,
      lastMessageTime: lastMsgTime,
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : (int.tryParse(json['unread_count']?.toString() ?? '') ?? 0),
      imageUrl: target['avatar_url']?.toString() ??
          target['avatar']?.toString() ??
          target['image_url']?.toString() ??
          json['avatar_url']?.toString(),
      badge: target['badge']?.toString() ?? (isGroupChat ? 'Group' : null),
      canMessage: target['can_message'] == true,
      isGroup: isGroupChat,
      chatType: json['chat_type']?.toString(),
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
