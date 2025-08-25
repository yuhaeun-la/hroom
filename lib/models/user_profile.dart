class UserProfile {
  final String id;
  final String displayName;
  final String role; // 'mentor' 또는 'mentee'
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      displayName: json['display_name'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? role,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isMentor => role == 'mentor';
  bool get isMentee => role == 'mentee';
  
  // 호환성을 위한 기존 이름 유지 (추후 단계적으로 제거)
  bool get isDom => role == 'mentor';
  bool get isSub => role == 'mentee';
  
  // 역할 표시 이름
  String get roleDisplayName {
    return isMentor ? '멘토' : '멘티';
  }
}
