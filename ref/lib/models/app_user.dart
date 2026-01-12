class AppUser {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;
  final bool isAdmin;
  final DateTime? bannedUntil;

  AppUser({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.isAdmin = false,
    this.bannedUntil,
  });

  AppUser copyWith({
    int? id,
    bool? isAdmin,
    DateTime? bannedUntil,
  }) => AppUser(
    id: id ?? this.id,
    username: username,
    email: email,
    passwordHash: passwordHash,
    salt: salt,
    createdAt: createdAt,
    isAdmin: isAdmin ?? this.isAdmin,
    bannedUntil: bannedUntil ?? this.bannedUntil,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'email': email,
    'password_hash': passwordHash,
    'salt': salt,
    'created_at': createdAt.toIso8601String(),
    'is_admin': isAdmin ? 1 : 0,
    'banned_until': bannedUntil?.toIso8601String(),
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as int?,
    username: map['username'] as String,
    email: map['email'] as String,
    passwordHash: map['password_hash'] as String,
    salt: map['salt'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    isAdmin: (map['is_admin'] as int? ?? 0) == 1,
    bannedUntil: map['banned_until'] != null && map['banned_until'].toString().isNotEmpty
        ? DateTime.parse(map['banned_until'] as String)
        : null,
  );
}
