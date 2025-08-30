import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (success) {
        _showSuccessMessage('Đăng ký thành công! Vui lòng đăng nhập.');
        // Delay để hiển thị thông báo
        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorMessage(authProvider.error ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorMessage('Lỗi: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Deprecated functions - kept for compatibility
  void _hienThiLoi(String message) {
    _showErrorMessage(message);
  }

  void _hienThiThanhCong(String message) {
    _showSuccessMessage(message);
  }

  void _togglePasswordVisibility() {
    if (!_loading) {
      setState(() => _hidePassword = !_hidePassword);
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Vui lòng nhập họ tên';
    if (name.length < 2) return 'Họ tên ít nhất 2 ký tự';
    if (name.length > 50) return 'Họ tên không quá 50 ký tự';
    // Kiểm tra chỉ chứa chữ cái và khoảng trắng
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(name)) {
      return 'Họ tên chỉ chứa chữ cái và khoảng trắng';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    if (email.length > 100) return 'Email quá dài';
    return null;
  }

  String? _validateMobile(String? value) {
    final mobile = value?.trim().replaceAll(RegExp(r'[^\d]'), '') ?? '';
    if (mobile.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (mobile.length != 10) return 'Số điện thoại phải có 10 chữ số';
    if (!mobile.startsWith(RegExp(r'^0[3|5|7|8|9]'))) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
    if (value!.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
    if (value.length > 50) return 'Mật khẩu không quá 50 ký tự';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Ký'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade50, Colors.white],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),

                    // Header
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add,
                            size: 60,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tạo tài khoản mới',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Điền thông tin để đăng ký',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                    ),
                    SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_loading,
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 16),

                    // Mobile field
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'VD: 0912345678',
                        helperText: 'Số điện thoại Việt Nam (10 chữ số)',
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !_loading,
                      validator: _validateMobile,
                    ),
                    SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock, color: Colors.green),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.green,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Tối thiểu 6 ký tự',
                      ),
                      obscureText: _hidePassword,
                      enabled: !_loading,
                      validator: _validatePassword,
                    ),
                    SizedBox(height: 32),

                    // Register button
                    Container(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
                                  Text(
                                    'Đang đăng ký...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : Text(
                                'Đăng Ký',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: 'Đã có tài khoản? ',
                            style: TextStyle(color: Colors.grey.shade600),
                            children: [
                              TextSpan(
                                text: 'Đăng nhập tại đây',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
