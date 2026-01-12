import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../widgets/game_button.dart';
import '../widgets/game_bg.dart';
import '../widgets/app_logo.dart';
import '../widgets/animated_dialog.dart';
import '../admin_grant_simple.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;
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
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AnimatedDialog(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(29),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF57BCCE),
                  Color(0xFFA8D3CA),
                  Color(0xFFDADCB7),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF57BCCE).withOpacity(0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon với animation và hiệu ứng
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Title với emoji và animation
                const Text(
                  'Tuyệt vời!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message chính
                const Text(
                  'Đăng ký thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message phụ
                const Text(
                  'Tài khoản của bạn đã được tạo thành công.\nBây giờ bạn có thể đăng nhập và khám phá!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 36),
                
                // Action Button với gradient
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFF8F9FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng dialog
                        Navigator.pop(context); // Về Login
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: Color(0xFF57BCCE),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Color(0xFF57BCCE),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.register(
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passwordCtl.text,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPw = ValueNotifier<bool>(true);
    final showCf = ValueNotifier<bool>(true);

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
                                    'Tạo tài khoản mới',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bắt đầu cuộc phiêu lưu của bạn',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                        labelText: 'Tên đăng nhập',
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
                                  
                                  // Email Field
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
                                      controller: _emailCtl,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
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
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                                        if (!v.contains('@')) return 'Email không hợp lệ';
                                        return null;
                                      },
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
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                                            if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                                            return null;
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Confirm Password Field
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
                                      valueListenable: showCf,
                                      builder: (_, bool obscured, __) {
                                        return TextFormField(
                                          controller: _confirmCtl,
                                          decoration: InputDecoration(
                                            labelText: 'Xác nhận mật khẩu',
                                            labelStyle: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                            prefixIcon: Icon(Icons.verified_user_outlined, color: Colors.grey[700]),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                obscured ? Icons.visibility_off : Icons.visibility,
                                                color: Colors.grey[700],
                                              ),
                                              onPressed: () => showCf.value = !showCf.value,
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
                                          (v != _passwordCtl.text) ? 'Mật khẩu không khớp' : null,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Register Button
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
                                      onPressed: _loading ? null : _handleRegister,
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
                                                // Icon(Icons.person_add, color: Colors.white, size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Tạo tài khoản',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Đã có tài khoản? ',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Text(
                                          'Đăng nhập ngay',
                                          style: TextStyle(
                                            color: Color(0xFF57BCCE),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Nút cấp quyền admin
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AdminGrantSimple()),
                                      );
                                    },
                                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                                    label: const Text(
                                      'Cấp quyền admin cho thien',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
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
