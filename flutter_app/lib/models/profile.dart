class Profile {
  final String userId;
  final String? nickname;
  final String? bio;
  final String? gender;
  final DateTime? birthday;
  final double? latitude;
  final double? longitude;
  final String? city;
  final List<String> interests;
  final List<String> photos;
  final String? avatar;

  Profile({
    required this.userId,
    this.nickname,
    this.bio,
    this.gender,
    this.birthday,
    this.latitude,
    this.longitude,
    this.city,
    this.interests = const [],
    this.photos = const [],
    this.avatar,
  });

  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int years = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      years--;
    }
    return years;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : [],
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
      'bio': bio,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'interests': interests,
      'photos': photos,
      'avatar': avatar,
    };
  }

  Profile copyWith({
    String? userId,
    String? nickname,
    String? bio,
    String? gender,
    DateTime? birthday,
    double? latitude,
    double? longitude,
    String? city,
    List<String>? interests,
    List<String>? photos,
    String? avatar,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      interests: interests ?? this.interests,
      photos: photos ?? this.photos,
      avatar: avatar ?? this.avatar,
    );
  }
}
