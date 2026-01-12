import 'package:flutter/material.dart';
import '../data/app_database.dart';

class AdminGrantSimple extends StatefulWidget {
  const AdminGrantSimple({super.key});

  @override
  State<AdminGrantSimple> createState() => _AdminGrantSimpleState();
}

class _AdminGrantSimpleState extends State<AdminGrantSimple> {
  String _status = 'Nhấn nút để cấp quyền admin cho thien';
  bool _isLoading = false;

  Future<void> _grantAdmin() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang xử lý...';
    });

    try {
      // Sử dụng AppDatabase.instance thay vì mở database trực tiếp
      final db = await AppDatabase.instance.database;
      
      // Tìm user thien
      final users = await db.query('users');
      debugPrint('Tất cả users: $users');
      
      var thienUser = users.firstWhere(
        (u) => (u['username'] == 'thien' && u['email'] == 'thien@gmail.com'),
        orElse: () => {},
      );
      
      if (thienUser.isEmpty) {
        setState(() {
          _status = 'Không tìm thấy user thien.\nHãy đăng ký user "thien" trước.';
          _isLoading = false;
        });
        return;
      }
      
      final userId = thienUser['id'] as int;
      
      // Cấp quyền admin
      final result = await db.update(
        'users',
        {'is_admin': 1},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      setState(() {
        if (result > 0) {
          _status = '✅ Đã cấp quyền admin cho thien thành công!\nVui lòng đăng xuất và đăng nhập lại.';
        } else {
          _status = 'Không thể cập nhật quyền admin';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấp quyền Admin'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cấp quyền Admin cho User Thien',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _grantAdmin,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.admin_panel_settings),
                label: Text(_isLoading ? 'Đang xử lý...' : 'Cấp quyền Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

