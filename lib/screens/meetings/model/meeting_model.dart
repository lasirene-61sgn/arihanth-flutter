class MeetingModel {
  final int? id;
  final String? roomId;
  final String? hostType;
  final int? hostId;
  final String? participantType;
  final int? participantId;
  final String? scheduledAt;
  final int? durationMinutes;
  final String? startedAt;
  final String? endedAt;
  final String? status;
  final Host? host;

  MeetingModel({
    this.id,
    this.roomId,
    this.hostType,
    this.hostId,
    this.participantType,
    this.participantId,
    this.scheduledAt,
    this.durationMinutes,
    this.startedAt,
    this.endedAt,
    this.status,
    this.host,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      roomId: json['room_id']?.toString(),
      hostType: json['host_type']?.toString(),
      hostId: json['host_id'],
      participantType: json['participant_type']?.toString(),
      participantId: json['participant_id'],
      scheduledAt: json['scheduled_at']?.toString(),
      durationMinutes: json['duration_minutes'],
      startedAt: json['started_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      status: json['status']?.toString(),
      host: json['host'] != null ? Host.fromJson(json['host']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'host_type': hostType,
      'host_id': hostId,
      'participant_type': participantType,
      'participant_id': participantId,
      'scheduled_at': scheduledAt,
      'duration_minutes': durationMinutes,
      'started_at': startedAt,
      'ended_at': endedAt,
      'status': status,
      'host': host?.toJson(),
    };
  }

  MeetingModel copyWith({
    int? id,
    String? roomId,
    String? hostType,
    int? hostId,
    String? participantType,
    int? participantId,
    String? scheduledAt,
    int? durationMinutes,
    String? startedAt,
    String? endedAt,
    String? status,
    Host? host,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      hostType: hostType ?? this.hostType,
      hostId: hostId ?? this.hostId,
      participantType: participantType ?? this.participantType,
      participantId: participantId ?? this.participantId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      host: host ?? this.host,
    );
  }
}

class Host {
  final int? id;
  final String? fullName;
  final String? emailId;
  final String? mobileNo;

  Host({
    this.id,
    this.fullName,
    this.emailId,
    this.mobileNo,
  });

  factory Host.fromJson(Map<String, dynamic> json) {
    return Host(
      id: json['id'],
      fullName: json['full_name']?.toString(),
      emailId: json['email_id']?.toString(),
      mobileNo: json['mobile_no']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email_id': emailId,
      'mobile_no': mobileNo,
    };
  }
}
