import 'package:flutter/material.dart';
import 'package:login_auth_flutter/providers/auth_provider.dart';
import 'package:login_auth_flutter/screens/login_screen.dart';
import 'package:provider/provider.dart';

class UserDetailsScreen extends StatefulWidget {
  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Kiểm tra và load user data khi màn hình khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadUserData();
    });
  }

  Future<void> _checkAndLoadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Nếu chưa có user data, thử load lại
    if (authProvider.user == null && !authProvider.isLoading) {
      try {
        await authProvider.getUserDetails();
      } catch (e) {
        if (mounted) {
          _showMessage('Lỗi tải thông tin: ${e.toString()}', Colors.red);
        }
      }
    }
  }

  void _showMessage(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.green
                  ? Icons.check_circle
                  : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _refreshUserData(),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmDialog(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải thông tin...'),
                ],
              ),
            );
          }

          if (authProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Lỗi: ${authProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshUserData(),
                    child: Text('Thử lại'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _handleLogout(context),
                    child: Text(
                      'Đăng nhập lại',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            );
          }

          if (authProvider.user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không có thông tin người dùng'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshUserData(),
                    child: Text('Tải lại'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _handleLogout(context),
                    child: Text('Về trang đăng nhập'),
                  ),
                ],
              ),
            );
          }

          final user = authProvider.user!;
          return RefreshIndicator(
            onRefresh: _refreshUserData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.yellow[700],
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 20),

                  // Welcome message
                  Text(
                    'Chào mừng, ${user.name}!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[700],
                    ),
                  ),
                  SizedBox(height: 20),

                  // User info card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow[700],
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(Icons.person, 'Tên', user.name),
                          SizedBox(height: 12),
                          _buildInfoRow(Icons.email, 'Email', user.email),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.phone,
                            'Số điện thoại',
                            user.mobile,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Ngày tạo',
                            _formatDate(user.createdAt),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.update,
                            'Cập nhật cuối',
                            _formatDate(user.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _refreshUserData(),
                          icon: Icon(Icons.refresh),
                          label: Text('Làm mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showLogoutConfirmDialog(context),
                          icon: Icon(Icons.logout),
                          label: Text('Đăng xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.yellow[700]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.getUserDetails();
      if (mounted) {
        _showMessage('Đã cập nhật thông tin!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi khi tải thông tin: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout(context);
              },
              child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.logout();
      if (mounted) {
        _showMessage('Đã đăng xuất thành công!', Colors.green);
        // Delay nhỏ để hiển thị thông báo
        await Future.delayed(Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi khi đăng xuất: ${e.toString()}', Colors.red);
      }
    }
  }
}
