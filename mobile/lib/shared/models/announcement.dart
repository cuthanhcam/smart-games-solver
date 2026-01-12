class Announcement {
  final int? id;
  final int? adminId;
  final String title;
  final String content;
  final String type;
  final String createdAt;
  final String? updatedAt;
  final bool isActive;

  Announcement({
    this.id,
    this.adminId,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'admin_id': adminId,
      'title': title,
      'content': content,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_active': isActive,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      adminId: map['admin_id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'info',
      createdAt:
          map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString(),
      isActive: map['is_active'] == true || map['is_active'] == 1,
    );
  }

  Announcement copyWith({
    int? id,
    int? adminId,
    String? title,
    String? content,
    String? type,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
  }) {
    return Announcement(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
