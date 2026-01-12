// API Configuration
// Contains base URLs and endpoints for backend API

class ApiConfig {
  // Backend API Base URL
  // For Android Emulator: Use 10.0.2.2
  // For iOS Simulator: Use localhost or 127.0.0.1
  // For Physical Device: Use your computer's IP address (e.g., 192.168.1.100)
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Android Emulator default
  static const String apiPrefix = '/api';

  // Full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';

  // Endpoints
  static const String auth = '/auth';
  static const String games = '/games';


  // Auth endpoints
  static String get register => '$apiUrl$auth/register';
  static String get login => '$apiUrl$auth/login';
  static String get logout => '$apiUrl$auth/logout';
  static String get currentUser => '$apiUrl$auth/me';



  // Game 2048 endpoints
  static String get game2048 => '$apiUrl$games/2048';
  static String get game2048New => '$game2048/new';
  static String get game2048Move => '$game2048/move';
  static String get game2048SaveScore => '$game2048/save-score';
  static String get game2048Leaderboard => '$game2048/leaderboard';

  // Sudoku endpoints
  static String get sudoku => '$apiUrl$games/sudoku';
  static String get sudokuNew => '$sudoku/new';
  static String get sudokuMove => '$sudoku/move';
  static String get sudokuValidate => '$sudoku/validate';
  static String get sudokuHint => '$sudoku/hint';
  static String get sudokuSaveScore => '$sudoku/save-score';
  static String get sudokuLeaderboard => '$sudoku/leaderboard';

  // Caro endpoints
  static String get caro => '$apiUrl$games/caro';
  static String get caroNew => '$caro/new';
  static String get caroMove => '$caro/move';
  static String get caroAIMove => '$caro/ai-move';
  static String get caroSaveScore => '$caro/save-score';
  static String get caroLeaderboard => '$caro/leaderboard';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
