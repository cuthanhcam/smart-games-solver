import 'package:flutter/material.dart';

// App exports
import 'features/auth/repositories/auth_repository.dart';
import 'features/home/screens/home_page.dart';
import 'features/auth/screens/login_page.dart';

// Game screens from features
import 'features/games/sudoku/screens/sudoku_screen.dart';
import 'features/games/caro/screens/caro_home_screen.dart';
import 'features/games/game_2048/screens/game_2048_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ColorScheme _scheme() => ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C4DFF), // tím neon
        brightness: Brightness.dark,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neon Game Auth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4299E1), // Professional Blue
          brightness: Brightness.light,
          primary: const Color(0xFF4299E1),
          secondary: const Color(0xFF48BB78), // Green accent
          surface: Colors.white,
        ),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7FAFC), // Very light gray blue
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF2D3748), // Dark slate for text
              displayColor: const Color(0xFF1A202C),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF4299E1), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            elevation: const WidgetStatePropertyAll(2),
            shadowColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.1)),
            backgroundColor: const WidgetStatePropertyAll(Color(0xFF4299E1)),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          margin: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide.none,
          ),
        ),
      ),
      routes: {
        '/login': (_) => const LoginPage(), // Login
        '/sudoku': (_) => const SudokuScreen(), // Sudoku Game
        '/caro': (_) => const CaroHomeScreen(), // Caro Game
        '/2048': (_) => const Game2048Screen(), // 2048 Game
      },
      home: const _Gate(),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final _repo = AuthRepository();
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final user = await _repo.getCurrentUser();
      if (mounted) {
        setState(() {
          _loggedIn = user != null;
          _loading = false;
        });
      }
    } catch (e) {
      // Nếu có lỗi, chuyển về trang login
      if (mounted) {
        setState(() {
          _loggedIn = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn ? const HomePage() : const LoginPage();
  }
}
