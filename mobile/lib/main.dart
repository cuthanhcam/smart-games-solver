import 'package:flutter/material.dart';

// App exports
import 'features/auth/repositories/auth_repository.dart';
import 'features/home/screens/home_page.dart';
import 'features/auth/screens/login_page.dart';

// Sudoku Game
import 'minigames/sudoku/sudoku_screen.dart';

// Caro Game
import 'minigames/caro/home_screen.dart';

// 2048 Game
import 'minigames/g2048/screen_2048.dart';

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
        colorScheme: scheme,
        brightness: Brightness.dark,
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xAA1A1E2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFF5CE1E6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFF5CE1E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
          ),
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize:
                const WidgetStatePropertyAll(Size(double.infinity, 52)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            elevation: const WidgetStatePropertyAll(8),
            shadowColor: const WidgetStatePropertyAll(Color(0xFF7C4DFF)),
            backgroundColor: const WidgetStatePropertyAll(Color(0xFF7C4DFF)),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xAA0E1220),
          elevation: 12,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
            side: BorderSide(color: Color(0xFF5CE1E6), width: 1.2),
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
