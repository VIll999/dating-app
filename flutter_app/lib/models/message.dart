enum MessageType {
  text,
  image,
  voice,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String from;
  final String to;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;

  Message({
    required this.id,
    required this.from,
    required this.to,
    this.type = MessageType.text,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  bool isMine(String currentUserId) => from == currentUserId;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      type: _parseMessageType(json['type'] as String?),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: _parseMessageStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  static MessageType _parseMessageType(String? value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  Message copyWith({
    String? id,
    String? from,
    String? to,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
