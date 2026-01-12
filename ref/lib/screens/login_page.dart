import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../widgets/game_button.dart';
import '../widgets/game_bg.dart';
import '../widgets/app_logo.dart';
import '../widgets/ban_notification_dialog.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _errorMessage = null; // Xóa thông báo lỗi cũ
    });
    
    try {
      await _repo.login(
        usernameOrEmail: _usernameCtl.text.trim(),
        password: _passwordCtl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Kiểm tra nếu là thông báo cấm user
      if (errorMessage.contains('đã bị cấm trong vòng')) {
        // Trích xuất thời gian còn lại từ thông báo
        final regex = RegExp(r'(\d+)\s+(giây|phút|giờ)');
        final match = regex.firstMatch(errorMessage);
        
        int remainingSeconds = 0;
        if (match != null) {
          final value = int.parse(match.group(1)!);
          final unit = match.group(2)!;
          
          switch (unit) {
            case 'giây':
              remainingSeconds = value;
              break;
            case 'phút':
              remainingSeconds = value * 60;
              break;
            case 'giờ':
              remainingSeconds = value * 3600;
              break;
          }
        }
        
        // Hiển thị dialog đẹp
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BanNotificationDialog(
            message: errorMessage,
            remainingSeconds: remainingSeconds,
          ),
        );
      } else {
        // Hiển thị thông báo lỗi dưới ô password
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPw = ValueNotifier<bool>(true);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay with gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x8057BCCE),
                    Color(0x80A8D3CA),
                    Color(0x80DADCB7),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Card(
                        elevation: 20,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xB3FFFFFF), // 70% opacity
                                Color(0xB3F8F9FF), // 70% opacity
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Logo/Icon
                                  const AppLogo(
                                    size: 60,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Title
                                  const Text(
                                    'Tôi đang đợi bạn đấy!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Đăng nhập để vào các mini-games 🎮',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Username Field
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _usernameCtl,
                                      decoration: InputDecoration(
                                        labelText: 'Tài khoản',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                        prefixIcon: Icon(Icons.person_outline, color: Colors.grey[700]),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.9),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF57BCCE), width: 2),
                                        ),
                                        errorStyle: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 10,
                                      ),
                                      validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Password Field
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ValueListenableBuilder(
                                      valueListenable: showPw,
                                      builder: (_, bool obscured, __) {
                                        return TextFormField(
                                          controller: _passwordCtl,
                                          decoration: InputDecoration(
                                            labelText: 'Mật khẩu',
                                            labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                obscured ? Icons.visibility_off : Icons.visibility,
                                                color: Colors.grey[700],
                                              ),
                                              onPressed: () => showPw.value = !showPw.value,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.9),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFF57BCCE), width: 2),
                                            ),
                                            errorStyle: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 10,
                                          ),
                                          obscureText: obscured,
                                          validator: (v) =>
                                          (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  // Hiển thị thông báo lỗi dưới ô password
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.red[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red[600],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red[600],
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Login Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF57BCCE), Color(0xFFA8D3CA)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF57BCCE).withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Icon(Icons.login, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Đăng nhập',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Register Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Chưa có tài khoản? ',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                                        ),
                                        child: const Text(
                                          'Đăng ký ngay',
                                          style: TextStyle(
                                            color: Color(0xFF57BCCE),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
