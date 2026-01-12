import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static const _dbName = 'game_auth.db';
  static const _dbVersion = 12;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    // Sau khi mở database, kiểm tra và sửa các bảng còn thiếu
    await fixDatabaseIssues();
    return _db!;
  }

  // Phương thức để reset database (xóa và tạo lại)
  Future<void> resetDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    await deleteDatabase(path);
  }

  // Phương thức để kiểm tra và sửa lỗi database
  Future<void> fixDatabaseIssues() async {
    try {
      final db = await database;
      
      // Kiểm tra xem bảng announcements có tồn tại không
      final announcementsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='announcements'"
      );
      
      if (announcementsResult.isEmpty) {
        // Bảng announcements không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            created_by TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
          );
        ''');
      }
      
      // Kiểm tra xem bảng read_announcements có tồn tại không
      final readAnnouncementsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='read_announcements'"
      );
      
      if (readAnnouncementsResult.isEmpty) {
        // Bảng read_announcements không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE read_announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            announcement_id INTEGER NOT NULL,
            read_at TEXT NOT NULL,
            FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
          );
        ''');
      }
      
      // Kiểm tra xem bảng hidden_announcements có tồn tại không
      final hiddenAnnouncementsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hidden_announcements'"
      );
      
      if (hiddenAnnouncementsResult.isEmpty) {
        // Bảng hidden_announcements không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE hidden_announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            announcement_id INTEGER NOT NULL,
            hidden_at TEXT NOT NULL,
            FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
          );
        ''');
      }
      
      // Kiểm tra xem bảng friends có tồn tại không
      final friendsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='friends'"
      );
      
      if (friendsResult.isEmpty) {
        // Bảng friends không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE friends (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            friend_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(user_id, friend_id)
          );
        ''');
      }
      
      // Kiểm tra xem bảng friend_requests có tồn tại không
      final friendRequestsResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='friend_requests'"
      );
      
      if (friendRequestsResult.isEmpty) {
        // Bảng friend_requests không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE friend_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER NOT NULL,
            receiver_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(sender_id, receiver_id)
          );
        ''');
      }
      
      // Kiểm tra xem bảng messages có tồn tại không
      final messagesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='messages'"
      );
      
      if (messagesResult.isEmpty) {
        // Bảng messages không tồn tại, tạo lại
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER NOT NULL,
            receiver_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
          );
        ''');
      }
    } catch (e) {
      print('Database error: $e');
      // Nếu có lỗi, reset database
      await resetDatabase();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        banned_until TEXT
      );
    ''');
    
    await db.execute('''
      CREATE TABLE announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      );
    ''');
    
    await db.execute('''
      CREATE TABLE read_announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        announcement_id INTEGER NOT NULL,
        read_at TEXT NOT NULL,
        FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
      );
    ''');
    
    await db.execute('''
      CREATE TABLE hidden_announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        announcement_id INTEGER NOT NULL,
        hidden_at TEXT NOT NULL,
        FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
      );
    ''');
    
    await db.execute('''
      CREATE TABLE friend_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(sender_id, receiver_id)
      );
    ''');
    
    await db.execute('''
      CREATE TABLE friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        friend_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, friend_id)
      );
    ''');
    
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Thêm cột is_admin cho database cũ
      await db.execute('ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0');
      
      // Cập nhật user "thien" thành admin
      await db.execute('''
        UPDATE users 
        SET is_admin = 1 
        WHERE username = 'thien' AND email = 'thien@gmail.com'
      ''');
    }
    
    if (oldVersion < 3) {
      // Kiểm tra xem cột banned_until đã tồn tại chưa trước khi thêm
      try {
        await db.execute('ALTER TABLE users ADD COLUMN banned_until TEXT');
      } catch (e) {
        // Nếu cột đã tồn tại, bỏ qua lỗi
        if (e.toString().contains('duplicate column name')) {
          // Cột đã tồn tại, không cần làm gì
        } else {
          // Lỗi khác, re-throw
          rethrow;
        }
      }
    }
    
    if (oldVersion < 4) {
      // Tạo bảng announcements nếu chưa tồn tại
      try {
        await db.execute('''
          CREATE TABLE announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            created_by TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
          );
        ''');
      } catch (e) {
        // Nếu bảng đã tồn tại, bỏ qua lỗi
        if (e.toString().contains('table announcements already exists')) {
          // Bảng đã tồn tại, không cần làm gì
        } else {
          // Lỗi khác, re-throw
          rethrow;
        }
      }
      
      // Tạo bảng read_announcements
      try {
        await db.execute('''
          CREATE TABLE read_announcements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            announcement_id INTEGER NOT NULL,
            read_at TEXT NOT NULL,
            FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
          );
        ''');
      } catch (e) {
        // Nếu bảng đã tồn tại, bỏ qua lỗi
        if (e.toString().contains('table read_announcements already exists')) {
          // Bảng đã tồn tại, không cần làm gì
        } else {
          // Lỗi khác, re-throw
          rethrow;
        }
      }
    }
    
    if (oldVersion < 5) {
      // Thêm cột display_duration_minutes cho announcements nếu chưa có
      try {
        // Kiểm tra xem bảng announcements có tồn tại không
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='announcements'"
        );
        
        if (result.isNotEmpty) {
          // Bảng tồn tại, thêm cột
          await db.execute('ALTER TABLE announcements ADD COLUMN display_duration_minutes INTEGER DEFAULT 2');
        }
      } catch (e) {
        // Nếu cột đã tồn tại, bỏ qua lỗi
        if (e.toString().contains('duplicate column name')) {
          // Cột đã tồn tại, không cần làm gì
        } else {
          // Lỗi khác, re-throw
          rethrow;
        }
      }
    }
    
            if (oldVersion < 6) {
              // Tạo bảng friend_requests
              await db.execute('''
                CREATE TABLE friend_requests (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  sender_id INTEGER NOT NULL,
                  receiver_id INTEGER NOT NULL,
                  status TEXT NOT NULL DEFAULT 'pending',
                  created_at TEXT NOT NULL,
                  FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
                  FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
                  UNIQUE(sender_id, receiver_id)
                );
              ''');
              
              // Tạo bảng friends
              await db.execute('''
                CREATE TABLE friends (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  friend_id INTEGER NOT NULL,
                  created_at TEXT NOT NULL,
                  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
                  FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
                  UNIQUE(user_id, friend_id)
                );
              ''');
            }
            
    if (oldVersion < 7) {
      // Tạo bảng friend_requests
      try {
        await db.execute('''
          CREATE TABLE friend_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id INTEGER NOT NULL,
            receiver_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(sender_id, receiver_id)
          );
        ''');
      } catch (e) {
        // Bỏ qua nếu bảng đã tồn tại
      }
      
      // Tạo bảng friends
      try {
        await db.execute('''
          CREATE TABLE friends (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            friend_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
            UNIQUE(user_id, friend_id)
          );
        ''');
      } catch (e) {
        // Bỏ qua nếu bảng đã tồn tại
      }
      
      // Tạo bảng user_notifications
      try {
        await db.execute('''
          CREATE TABLE user_notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            announcement_id INTEGER NOT NULL,
            notification_type TEXT NOT NULL DEFAULT 'general',
            created_at TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
          );
        ''');
      } catch (e) {
        // Bỏ qua nếu bảng đã tồn tại
      }
    }
            
            if (oldVersion < 8) {
              // Tạo bảng messages
              await db.execute('''
                CREATE TABLE messages (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  sender_id INTEGER NOT NULL,
                  receiver_id INTEGER NOT NULL,
                  content TEXT NOT NULL,
                  created_at TEXT NOT NULL,
                  is_read INTEGER DEFAULT 0,
                  FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
                  FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
                );
              ''');
            }
            
            if (oldVersion < 9) {
              // Tạo bảng hidden_announcements
              await db.execute('''
                CREATE TABLE hidden_announcements (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  user_id INTEGER NOT NULL,
                  announcement_id INTEGER NOT NULL,
                  hidden_at TEXT NOT NULL,
                  FOREIGN KEY (announcement_id) REFERENCES announcements (id) ON DELETE CASCADE
                );
              ''');
            }
            
    if (oldVersion < 10) {
      // Đảm bảo tạo các bảng friends và friend_requests nếu chưa tồn tại
      try {
        // Kiểm tra xem bảng friends có tồn tại không
        final friendsResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='friends'"
        );
        
        if (friendsResult.isEmpty) {
          // Tạo bảng friends
          await db.execute('''
            CREATE TABLE friends (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              friend_id INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
              UNIQUE(user_id, friend_id)
            );
          ''');
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
      
      try {
        // Kiểm tra xem bảng friend_requests có tồn tại không
        final friendRequestsResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='friend_requests'"
        );
        
        if (friendRequestsResult.isEmpty) {
          // Tạo bảng friend_requests
          await db.execute('''
            CREATE TABLE friend_requests (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender_id INTEGER NOT NULL,
              receiver_id INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              created_at TEXT NOT NULL,
              FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
              UNIQUE(sender_id, receiver_id)
            );
          ''');
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
    
    if (oldVersion < 11) {
      // Đảm bảo tạo bảng messages nếu chưa tồn tại
      try {
        // Kiểm tra xem bảng messages có tồn tại không
        final messagesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='messages'"
        );
        
        if (messagesResult.isEmpty) {
          // Tạo bảng messages
          await db.execute('''
            CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender_id INTEGER NOT NULL,
              receiver_id INTEGER NOT NULL,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              is_read INTEGER DEFAULT 0,
              FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
            );
          ''');
        }
      } catch (e) {
        // Bỏ qua lỗi
      }
    }
    
    if (oldVersion < 12) {
      // Đảm bảo tất cả các bảng cần thiết đều tồn tại
      try {
        // Tạo bảng friends nếu chưa tồn tại
        final friendsResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='friends'"
        );
        
        if (friendsResult.isEmpty) {
          await db.execute('''
            CREATE TABLE friends (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              friend_id INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (friend_id) REFERENCES users (id) ON DELETE CASCADE,
              UNIQUE(user_id, friend_id)
            );
          ''');
        }
      } catch (e) {
        print('Error creating friends table: $e');
      }
      
      try {
        // Tạo bảng friend_requests nếu chưa tồn tại
        final friendRequestsResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='friend_requests'"
        );
        
        if (friendRequestsResult.isEmpty) {
          await db.execute('''
            CREATE TABLE friend_requests (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender_id INTEGER NOT NULL,
              receiver_id INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              created_at TEXT NOT NULL,
              FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE,
              UNIQUE(sender_id, receiver_id)
            );
          ''');
        }
      } catch (e) {
        print('Error creating friend_requests table: $e');
      }
      
      try {
        // Tạo bảng messages nếu chưa tồn tại
        final messagesResult = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='messages'"
        );
        
        if (messagesResult.isEmpty) {
          await db.execute('''
            CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender_id INTEGER NOT NULL,
              receiver_id INTEGER NOT NULL,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              is_read INTEGER DEFAULT 0,
              FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
            );
          ''');
        }
      } catch (e) {
        print('Error creating messages table: $e');
      }
    }
  }
}