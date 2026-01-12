class Announcement {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final String createdBy;
  final bool isActive;
  // final int displayDurationMinutes; // Đã bỏ chức năng thời gian hiển thị

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    // this.displayDurationMinutes = 2, // Đã bỏ chức năng
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'created_by': createdBy,
      'is_active': isActive ? 1 : 0,
      // 'display_duration_minutes': displayDurationMinutes, // Đã bỏ chức năng
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
      createdBy: map['created_by'],
      isActive: map['is_active'] == 1,
      // displayDurationMinutes: map['display_duration_minutes'] ?? 2, // Đã bỏ chức năng
    );
  }

  Announcement copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    String? createdBy,
    bool? isActive,
    // int? displayDurationMinutes, // Đã bỏ chức năng
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      // displayDurationMinutes: displayDurationMinutes ?? this.displayDurationMinutes, // Đã bỏ chức năng
    );
  }

  // Kiểm tra thông báo có hết hạn không - Đã bỏ chức năng
  // bool get isExpired {
  //   final createdTime = DateTime.parse(createdAt);
  //   final expiryTime = createdTime.add(Duration(minutes: displayDurationMinutes));
  //   return DateTime.now().isAfter(expiryTime);
  // }

  // Thời gian còn lại (phút) - Đã bỏ chức năng
  // int get remainingMinutes {
  //   final createdTime = DateTime.parse(createdAt);
  //   final expiryTime = createdTime.add(Duration(minutes: displayDurationMinutes));
  //   final remaining = expiryTime.difference(DateTime.now()).inMinutes;
  //   return remaining > 0 ? remaining : 0;
  // }
}
