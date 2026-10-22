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

  factory MessageModel.fromJson(dynamic rawJson, {int? currentUserId, String? currentUserCode, String? partnerCode}) {
    final Map<String, dynamic> json = rawJson is Map
        ? rawJson.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final senderObj = json['sender'] is Map ? json['sender'] : null;

    final senderId = (senderObj != null && senderObj['id'] != null)
        ? (senderObj['id'] is int ? senderObj['id'] : int.tryParse(senderObj['id']?.toString() ?? ''))
        : (json['sender_id'] is int 
            ? json['sender_id'] 
            : int.tryParse(json['sender_id']?.toString() ?? ''));

    final String? senderCode = senderObj != null ? senderObj['code']?.toString() : json['sender_code']?.toString();
    final String? senderName = senderObj != null 
        ? (senderObj['name']?.toString() ?? senderObj['label']?.toString() ?? senderCode)
        : (json['sender_name']?.toString() ?? senderCode);

    final id = json['id'] is int 
        ? json['id'] 
        : int.tryParse(json['id']?.toString() ?? '');
    final conversationId = json['conversation_id'] is int 
        ? json['conversation_id'] 
        : int.tryParse(json['conversation_id']?.toString() ?? '');
        
    // Check if explicitly marked
    bool isMine = false;
    if (json['is_mine'] == true || json['is_mine'] == 1 || json['is_mine']?.toString() == 'true') {
      isMine = true;
    } else if (currentUserCode != null && currentUserCode.isNotEmpty && senderCode != null && senderCode.isNotEmpty) {
      isMine = senderCode.toLowerCase() == currentUserCode.toLowerCase();
    } else if (currentUserId != null && senderId != null) {
      isMine = senderId == currentUserId;
    }

    // If partnerCode is known and matches this sender, it is definitely NOT me
    if (partnerCode != null && partnerCode.isNotEmpty && senderCode != null && senderCode.isNotEmpty) {
      if (senderCode.toLowerCase() == partnerCode.toLowerCase()) {
        isMine = false;
      }
    }

    // Extract text/content from all possible keys
    final String content = json['message']?.toString() ??
        json['text']?.toString() ??
        json['content']?.toString() ??
        json['body']?.toString() ??
        '';

    // Extract attachment / media URL from all possible fields
    String? attachmentUrl;
    if (json['video_url'] != null && json['video_url'].toString().isNotEmpty) {
      attachmentUrl = json['video_url'].toString();
    } else if (json['audio_url'] != null && json['audio_url'].toString().isNotEmpty) {
      attachmentUrl = json['audio_url'].toString();
    } else if (json['voice_url'] != null && json['voice_url'].toString().isNotEmpty) {
      attachmentUrl = json['voice_url'].toString();
    } else if (json['attachment_url'] != null && json['attachment_url'].toString().isNotEmpty) {
      attachmentUrl = json['attachment_url'].toString();
    } else if (json['voice_note'] != null && json['voice_note'].toString().isNotEmpty) {
      attachmentUrl = json['voice_note'].toString();
    } else if (json['voice'] != null && json['voice'].toString().isNotEmpty) {
      attachmentUrl = json['voice'].toString();
    } else if (json['video'] != null && json['video'].toString().isNotEmpty) {
      attachmentUrl = json['video'].toString();
    } else if (json['audio'] != null && json['audio'].toString().isNotEmpty) {
      attachmentUrl = json['audio'].toString();
    } else if (json['file'] != null && json['file'].toString().isNotEmpty) {
      attachmentUrl = json['file'].toString();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      attachmentUrl = json['image'].toString();
    } else if (json['attachments'] is List && (json['attachments'] as List).isNotEmpty) {
      final first = (json['attachments'] as List)[0];
      attachmentUrl = first is Map ? (first['full_url'] ?? first['url'] ?? first['path'])?.toString() : first?.toString();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final first = (json['images'] as List)[0];
      attachmentUrl = first is Map ? (first['full_url'] ?? first['url'] ?? first['path'])?.toString() : first?.toString();
    } else if (json['videos'] is List && (json['videos'] as List).isNotEmpty) {
      final first = (json['videos'] as List)[0];
      attachmentUrl = first is Map ? (first['full_url'] ?? first['url'] ?? first['path'])?.toString() : first?.toString();
    } else if (json['audios'] is List && (json['audios'] as List).isNotEmpty) {
      final first = (json['audios'] as List)[0];
      attachmentUrl = first is Map ? (first['full_url'] ?? first['url'] ?? first['path'])?.toString() : first?.toString();
    } else if (json['files'] is List && (json['files'] as List).isNotEmpty) {
      final first = (json['files'] as List)[0];
      attachmentUrl = first is Map ? (first['full_url'] ?? first['url'] ?? first['path'])?.toString() : first?.toString();
    }

    final String mediaType = json['media_type']?.toString() ??
        json['type']?.toString() ??
        (attachmentUrl != null && attachmentUrl.toLowerCase().contains('/stream') ? 'audio' : 'text');

    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: mediaType,
      attachmentUrl: attachmentUrl,
      createdAt: json['created_at']?.toString(),
      isMe: isMine,
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
