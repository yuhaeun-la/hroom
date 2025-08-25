class InvitationCode {
  final String id;
  final String code;
  final String mentorId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedBy;

  InvitationCode({
    required this.id,
    required this.code,
    required this.mentorId,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedBy,
  });

  factory InvitationCode.fromJson(Map<String, dynamic> json) {
    return InvitationCode(
      id: json['id'],
      code: json['code'],
      mentorId: json['mentor_id'] ?? json['dom_id'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['is_used'] ?? false,
      usedBy: json['used_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'mentor_id': mentorId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'used_by': usedBy,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  // 하위 호환성을 위한 getter
  String get domId => mentorId;
}
