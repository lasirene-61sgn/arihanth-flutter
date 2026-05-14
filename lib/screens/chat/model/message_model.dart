class MessageModel {
  final int? id;
  final int? conversationId;
  final int? senderId;
  final String? senderName;
  final String? content;
  final String? type; // 'text', 'image', etc.
  final String? attachmentUrl;
  final String? createdAt;
  final bool isMe;

  MessageModel({
    this.id,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.content,
    this.type,
    this.attachmentUrl,
    this.createdAt,
    this.isMe = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      content: json['content'],
      type: json['type'] ?? 'text',
      attachmentUrl: json['attachment_url'],
      createdAt: json['created_at'],
      isMe: currentUserId != null && json['sender_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'attachment_url': attachmentUrl,
      'created_at': createdAt,
    };
  }
}
