import 'package:flutter/material.dart';
import 'package:login_auth_flutter/screens/register_screen.dart';
import 'package:login_auth_flutter/screens/user_details_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Đăng nhập thành công - load user details trước khi chuyển trang
        try {
          await authProvider.getUserDetails();

          if (!mounted) return;

          // Hiển thị thông báo thành công
          _showMessage('Đăng nhập thành công!', Colors.green);

          // Delay nhỏ để user thấy thông báo
          await Future.delayed(Duration(milliseconds: 1500));

          if (!mounted) return;

          // Chuyển đến UserDetailsScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => UserDetailsScreen()),
          );
        } catch (e) {
          // Lỗi khi load user details
          setState(() => _loading = false);
          _showMessage(
            'Lỗi tải thông tin người dùng: ${e.toString()}',
            Colors.red,
          );
        }
      } else {
        // Đăng nhập thất bại
        setState(() => _loading = false);
        _showMessage(authProvider.error ?? 'Đăng nhập thất bại', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Lỗi: ${e.toString()}', Colors.red);
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

  // Deprecated - kept for compatibility
  void _hienThiLoi(String message) {
    _showMessage(message, Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Nhập'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 100, color: Colors.blue),
                SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_loading,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                    if (!RegExp(
                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                    ).hasMatch(value!)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _hidePassword = !_hidePassword);
                            },
                    ),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: _hidePassword,
                  enabled: !_loading,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Đang đăng nhập...'),
                            ],
                          )
                        : Text('Đăng Nhập', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 16),

                // Register link
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          );
                        },
                  child: Text('Chưa có tài khoản? Đăng ký tại đây'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
