class Message {
  final int? id;
  final int senderId;
  final int receiverId;
  final String content;
  final String createdAt;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      content: map['content'],
      createdAt: map['created_at'],
      isRead: map['is_read'] == 1,
    );
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    String? createdAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
