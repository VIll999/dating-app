import 'package:dating_app/models/profile.dart';
import 'package:dating_app/models/message.dart';

class Match {
  final String id;
  final String userId;
  final String matchedUserId;
  final Profile? matchedProfile;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime matchedAt;

  Match({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    this.matchedProfile,
    this.lastMessage,
    this.unreadCount = 0,
    required this.matchedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      matchedUserId: json['matched_user_id'] as String,
      matchedProfile: json['matched_profile'] != null
          ? Profile.fromJson(json['matched_profile'] as Map<String, dynamic>)
          : null,
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: (json['unread_count'] as int?) ?? 0,
      matchedAt: DateTime.parse(json['matched_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'matched_user_id': matchedUserId,
      'matched_profile': matchedProfile?.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'matched_at': matchedAt.toIso8601String(),
    };
  }
}
