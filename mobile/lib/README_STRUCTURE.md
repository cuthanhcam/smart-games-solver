# Mobile App - Cấu trúc Project

## 📁 Cấu trúc Folder

```
lib/
├── core/                                # Core configurations
│   ├── config/
│   │   └── api_config.dart             # API configuration
│   └── database/
│       └── app_database.dart            # Local database (deprecated)
│
├── features/                            # Feature-based modules
│   ├── auth/                            # Authentication
│   │   ├── screens/
│   │   │   ├── login_page.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_page.dart
│   │   │   └── register_screen.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── services/
│   │       └── auth_service.dart
│   │
│   ├── admin/                           # Admin features
│   │   └── screens/
│   │       ├── admin_page.dart
│   │       └── admin_grant_screen.dart
│   │
│   ├── social/                          # Friends & Messages
│   │   ├── screens/
│   │   │   ├── friends_screen.dart
│   │   │   ├── chat_list_screen.dart
│   │   │   └── chat_detail_screen.dart
│   │   ├── repositories/
│   │   │   ├── friend_request_repository.dart
│   │   │   └── message_repository.dart
│   │   └── widgets/
│   │       ├── message_badge_widget.dart
│   │       └── notification_badge_widget.dart
│   │
│   ├── announcement/                   # Announcements & Notifications
│   │   ├── screens/
│   │   │   ├── announcement_screen.dart
│   │   │   ├── announcement_detail_screen.dart
│   │   │   ├── notifications_screen.dart
│   │   │   └── user_notification_screen.dart
│   │   ├── repositories/
│   │   │   └── announcement_repository.dart
│   │   └── widgets/
│   │       ├── announcement_widget.dart
│   │       └── notification_icon_widget.dart
│   │
│   ├── games/                           # All game features
│   │   ├── game_2048/
│   │   │   ├── screens/
│   │   │   │   └── game_2048_screen.dart
│   │   │   ├── repositories/
│   │   │   │   └── game_2048_repository.dart
│   │   │   ├── services/
│   │   │   │   └── game_2048_service.dart
│   │   │   └── utils/
│   │   │       └── game_2048_logic.dart
│   │   │
│   │   ├── caro/
│   │   │   ├── screens/
│   │   │   │   └── caro_screen.dart
│   │   │   ├── repositories/
│   │   │   │   └── caro_repository.dart
│   │   │   ├── services/
│   │   │   │   └── caro_service.dart
│   │   │   ├── widgets/
│   │   │   │   └── caro/...
│   │   │   └── utils/
│   │   │       └── caro/...
│   │   │
│   │   ├── sudoku/
│   │   │   ├── screens/
│   │   │   │   └── sudoku_screen.dart
│   │   │   ├── repositories/
│   │   │   │   └── sudoku_repository.dart
│   │   │   ├── services/
│   │   │   │   └── sudoku_service.dart
│   │   │   └── utils/
│   │   │       └── sudoku_logic.dart
│   │   │
│   │   └── rubik/
│   │       ├── screens/
│   │       │   └── ...
│   │       └── repositories/
│   │           └── rubik_repository.dart
│   │
│   ├── home/                            # Home screens
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       └── home_page.dart
│   │
│   ├── leaderboard/                     # Leaderboard feature
│   │   ├── screens/
│   │   │   └── leaderboard_screen.dart
│   │   └── utils/
│   │       └── leaderboard_helper.dart
│   │
│   └── profile/                         # User profile
│       ├── screens/
│       │   ├── user_profile_screen.dart
│       │   └── user_activity_screen.dart
│       └── utils/
│           ├── user_activity_helper.dart
│           └── friends_helper.dart
│
├── shared/                              # Shared resources
│   ├── models/                          # Data models
│   │   ├── announcement.dart
│   │   ├── app_user.dart
│   │   ├── caro.dart
│   │   ├── game_2048.dart
│   │   ├── message.dart
│   │   ├── sudoku.dart
│   │   └── user.dart
│   │
│   ├── services/                        # Shared services
│   │   ├── api_client.dart             # API client
│   │   └── api_service.dart            # API service
│   │
│   └── widgets/                         # Reusable widgets
│       ├── animated_dialog.dart
│       ├── app_logo.dart
│       ├── ban_notification_dialog.dart
│       ├── clock_widget.dart
│       ├── game_bg.dart
│       ├── game_button.dart
│       ├── gradient_background.dart
│       ├── gradient_bg.dart
│       ├── gradient_snackbar.dart
│       └── primary_button.dart
│
├── minigames/                   # Legacy game screens (to be migrated)
│   ├── caro/
│   ├── g2048/
│   ├── rubik/
│   └── sudoku/
│
├── app_exports.dart                     # Barrel export file
├── main.dart                            # App entry point
└── test_home.dart                       # Test screen
```

## 🎯 Import Guidelines

### Import từ cùng feature
```dart
// Trong features/auth/screens/login_page.dart
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
```

### Import từ shared resources
```dart
// Trong features/auth/screens/login_page.dart
import '../../../shared/models/user.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/app_logo.dart';
```

### Import từ core
```dart
// Trong features/auth/services/auth_service.dart
import '../../../core/config/api_config.dart';
```

### Import từ feature khác
```dart
// Trong features/home/screens/home_page.dart
import '../../auth/repositories/auth_repository.dart';
import '../../social/screens/friends_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
```

## 🔄 Migration Status

- ✅ Auth feature - Completed
- ✅ Admin feature - Completed
- ✅ Social feature - Completed
- ✅ Announcement feature - Completed
- ✅ Games features - Completed
- ✅ Home feature - Completed
- ✅ Leaderboard feature - Completed
- ✅ Profile feature - Completed
- ✅ Shared resources - Completed
- ⚠️ Legacy minigames - Needs import updates

## 📝 Maintainance Notes

1. **Deprecated Files**:
   - `core/database/app_database.dart` - No longer used (migrated to API)
   - `test_home.dart` - Can be removed

2. **Feature Organization**:
   - Each feature is self-contained
   - Shared resources in `shared/` folder
   - Core config in `core/` folder

3. **Adding New Features**:
   - Create new folder in `features/`
   - Add screens, repositories, services as needed
   - Use shared resources from `shared/` folder

## 🚀 Next Steps

1. Update all imports in legacy minigames folder
2. Test all screens for correct imports
3. Remove deprecated files
4. Add barrel exports for each feature if needed
