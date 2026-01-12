// Core exports
export 'core/config/api_config.dart';

// Shared exports - Models
export 'shared/models/models.dart';

// Shared exports - Services
export 'shared/services/services.dart';

// Shared exports - Widgets
export 'shared/widgets/widgets.dart';

// Feature exports - Auth
export 'features/auth/screens/login_page.dart';
export 'features/auth/screens/register_page.dart';
export 'features/auth/repositories/auth_repository.dart';
export 'features/auth/services/auth_service.dart';

// Feature exports - Admin
export 'features/admin/screens/admin_page.dart';

// Feature exports - Social
export 'features/social/screens/friends_screen.dart';
export 'features/social/screens/chat_list_screen.dart';
export 'features/social/screens/chat_detail_screen.dart';
export 'features/social/repositories/friend_request_repository.dart';
export 'features/social/repositories/message_repository.dart';
export 'features/social/widgets/message_badge_widget.dart';
export 'features/social/widgets/notification_badge_widget.dart';

// Feature exports - Announcement
export 'features/announcement/screens/announcement_screen.dart';
export 'features/announcement/screens/announcement_detail_screen.dart';
export 'features/announcement/screens/notifications_screen.dart';
export 'features/announcement/screens/user_notification_screen.dart';
export 'features/announcement/repositories/announcement_repository.dart';
export 'features/announcement/widgets/announcement_widget.dart';
export 'features/announcement/widgets/notification_icon_widget.dart';

// Feature exports - Home
export 'features/home/screens/home_screen.dart';
export 'features/home/screens/home_page.dart';

// Feature exports - Profile
export 'features/profile/screens/user_profile_screen.dart';
export 'features/profile/screens/user_activity_screen.dart';
export 'features/profile/utils/user_activity_helper.dart';

// Feature exports - Games
export 'features/games/game_2048/screens/game_2048_screen.dart';
export 'features/games/game_2048/services/game_2048_service.dart';
export 'features/games/game_2048/repositories/game_2048_repository.dart';
export 'features/games/caro/screens/caro_screen.dart';
export 'features/games/caro/services/caro_service.dart';
export 'features/games/caro/repositories/caro_repository.dart';
export 'features/games/sudoku/screens/sudoku_screen.dart';
export 'features/games/sudoku/services/sudoku_service.dart';
export 'features/games/sudoku/repositories/sudoku_repository.dart';

// Feature exports - Leaderboard
export 'features/leaderboard/screens/leaderboard_screen.dart';
export 'features/leaderboard/utils/leaderboard_helper.dart';
