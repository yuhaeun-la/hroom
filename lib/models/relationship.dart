class Relationship {
  final String id;
  final String mentorId;
  final String menteeId;
  final String status; // 'pending', 'active', 'inactive'
  final DateTime startedAt;
  final DateTime updatedAt;

  Relationship({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      id: json['id'],
      mentorId: json['mentor_id'] ?? json['dom_id'], // 호환성 지원
      menteeId: json['mentee_id'] ?? json['sub_id'], // 호환성 지원
      status: json['status'],
      startedAt: DateTime.parse(json['started_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 호환성을 위한 기존 이름 유지
  String get domId => mentorId;
  String get subId => menteeId;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';
}
