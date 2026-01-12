// User Model
// Represents a user in the system with authentication and profile data

class User {
  final int? id;
  final String username;
  final String email;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? bannedUntil;
  final bool isBanned;
  final String? banReason;

  User({
    this.id,
    required this.username,
    required this.email,
    this.isAdmin = false,
    this.createdAt,
    this.bannedUntil,
    this.isBanned = false,
    this.banReason,
  });

  User copyWith({
    int? id,
    String? username,
    String? email,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? bannedUntil,
    bool? isBanned,
    String? banReason,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      email: json['email'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      bannedUntil: json['banned_until'] != null
          ? DateTime.parse(json['banned_until'] as String)
          : null,
      isBanned: json['is_banned'] as bool? ?? false,
      banReason: json['ban_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'is_admin': isAdmin,
      'created_at': createdAt?.toIso8601String(),
      'banned_until': bannedUntil?.toIso8601String(),
      'is_banned': isBanned,
      'ban_reason': banReason,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, isAdmin: $isAdmin)';
  }
}

/// Auth Response Models
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
