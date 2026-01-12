import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../shared/services/api_client.dart';

class AdminGrantSimple extends StatefulWidget {
  const AdminGrantSimple({super.key});

  @override
  State<AdminGrantSimple> createState() => _AdminGrantSimpleState();
}

class _AdminGrantSimpleState extends State<AdminGrantSimple> {
  final ApiClient _apiClient = ApiClient();
  String _status = 'Nhấn nút để tìm và cấp quyền admin cho user thien';
  bool _isLoading = false;

  Future<void> _grantAdmin() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang tìm user thien...';
    });

    try {
      // Search for user thien
      final response = await _apiClient.searchUsersAdmin('thien');

      if (response.statusCode == 401) {
        setState(() {
          _status =
              'Bạn cần đăng nhập với tài khoản admin để thực hiện chức năng này';
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 403) {
        setState(() {
          _status = 'Bạn không có quyền admin để thực hiện chức năng này';
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _status = 'Lỗi khi tìm user: ${response.statusCode}';
          _isLoading = false;
        });
        return;
      }

      final users = jsonDecode(response.body) as List;

      // Find user with username 'thien' and email 'thien@gmail.com'
      final thienUser = users.firstWhere(
        (u) => u['username'] == 'thien' && u['email'] == 'thien@gmail.com',
        orElse: () => null,
      );

      if (thienUser == null) {
        setState(() {
          _status =
              'Không tìm thấy user thien (thien@gmail.com).\nHãy đăng ký user "thien" trước.';
          _isLoading = false;
        });
        return;
      }

      final userId = thienUser['id'] as int;
      final isAlreadyAdmin = thienUser['is_admin'] as bool;

      if (isAlreadyAdmin) {
        setState(() {
          _status = 'User thien đã là admin rồi!';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Đang cấp quyền admin...';
      });

      // Grant admin status
      final updateResponse = await _apiClient.updateUserAdminStatus(
        userId,
        true,
      );

      if (updateResponse.statusCode == 200) {
        setState(() {
          _status =
              '✅ Đã cấp quyền admin cho thien thành công!\nVui lòng đăng xuất và đăng nhập lại.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status =
              'Không thể cập nhật quyền admin: ${updateResponse.statusCode}';
          _isLoading = false;
        });
      }
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
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
