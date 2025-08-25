class JournalComment {
  final String id;
  final String journalId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalComment({
    required this.id,
    required this.journalId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalComment.fromJson(Map<String, dynamic> json) {
    return JournalComment(
      id: json['id'] as String,
      journalId: json['journal_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'journal_id': journalId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JournalComment copyWith({
    String? id,
    String? journalId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalComment(
      id: id ?? this.id,
      journalId: journalId ?? this.journalId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
