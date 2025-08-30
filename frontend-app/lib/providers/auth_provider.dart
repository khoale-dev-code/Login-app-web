import 'package:flutter/material.dart';
import 'package:login_auth_flutter/models/user.dart';
import 'package:login_auth_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  User? _user;
  bool _isAuthenticated = false;
  Timer? _tokenRefreshTimer;
  Timer? _heartbeatTimer;
  bool _disposed = false; // Đã dispose hay chưa?

  // Getter cho UI
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    debugPrint('AuthProvider được khởi tạo');
    _initAuth(); // Kiểm tra trạng thái ban đầu
    _startHeartbeat(); // Bắt đầu kiểm tra kết nối định kỳ
  }

  /// Giải phóng tài nguyên
  @override
  void dispose() {
    debugPrint('AuthProvider dispose');
    _disposed = true;
    _tokenRefreshTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  /// Gọi notifyListeners an toàn (chỉ khi chưa dispose)
  void _safeNotify() {
    if (!_disposed) {
      debugPrint(
        'Notifying listeners - isAuth: $_isAuthenticated, hasUser: ${_user != null}',
      );
      notifyListeners();
    }
  }

  /// Cập nhật trạng thái loading
  void _setLoading(bool value) {
    if (!_disposed && _isLoading != value) {
      debugPrint('⏳ Loading: $value');
      _isLoading = value;
      _safeNotify();
    }
  }

  /// Cập nhật lỗi
  void _setError(String? error) {
    if (!_disposed) {
      debugPrint('❌ Error: $error');
      _error = error;
      _safeNotify();
    }
  }

  /// Set user và cập nhật trạng thái authenticated
  void _setUser(User? user) {
    if (!_disposed) {
      _user = user;
      _isAuthenticated = user != null;
      debugPrint(
        '👤 User set: ${user?.name ?? 'null'}, Authenticated: $_isAuthenticated',
      );
      _safeNotify();
    }
  }

  /// Khởi tạo: kiểm tra token có sẵn không
  Future<void> _initAuth() async {
    if (_disposed) return;
    debugPrint('Initializing auth...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null) {
        debugPrint('Found existing token, trying to get user details...');
        _setLoading(true);
        try {
          await getUserDetails();
          _scheduleTokenRefresh();
        } catch (e) {
          debugPrint('⚠️ Failed to get user details on init: $e');
          // Clear invalid token
          await prefs.remove('access_token');
          await prefs.remove('refresh_token');
        } finally {
          _setLoading(false);
        }
      } else {
        debugPrint(' No existing token found');
      }
    } catch (e) {
      debugPrint('Error in _initAuth: $e');
      _setLoading(false);
    }
  }

  /// Bắt đầu heartbeat: kiểm tra kết nối mạng mỗi 5 phút
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (_isAuthenticated) {
        try {
          final ok = await ApiService.checkConnection();
          if (!ok) {
            _setError('Mất kết nối. Vui lòng kiểm tra internet.');
          } else if (_error?.contains('Mất kết nối') == true) {
            _setError(null);
          }
        } catch (_) {
          // Bỏ qua lỗi heartbeat
        }
      }
    });
  }

  /// Lên lịch tự động refresh token sau 14 phút
  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer(const Duration(minutes: 14), () async {
      if (_disposed || !_isAuthenticated) return;
      debugPrint('🔄 Auto refreshing token...');
      try {
        await getUserDetails();
      } catch (_) {
        await logout();
      }
    });
  }

  /// Đăng ký tài khoản
  Future<bool> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    if (_disposed) return false;

    _setLoading(true);
    _setError(null);

    try {
      final request = RegisterRequest(
        name: name,
        email: email,
        mobile: mobile,
        password: password,
      );
      final success = await ApiService.register(request);

      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Đăng nhập
  Future<bool> login({required String email, required String password}) async {
    if (_disposed) return false;

    debugPrint('Starting login process...');
    _setLoading(true);
    _setError(null);

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await ApiService.login(request);

      debugPrint('✅ Login API successful, setting user...');
      _setUser(response.user);

      _scheduleTokenRefresh();
      _setLoading(false);

      debugPrint(' Login process completed successfully');
      return true;
    } catch (e) {
      debugPrint('Login failed: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setUser(null); // Make sure user is null on login failure
      _setLoading(false);
      return false;
    }
  }

  /// Lấy thông tin người dùng từ API
  Future<void> getUserDetails() async {
    if (_disposed) return;

    debugPrint(' Getting user details...');
    try {
      final user = await ApiService.getUserDetails();
      debugPrint(' Got user details: ${user.name}');
      _setUser(user);
      _setError(null); // Clear any existing error
    } catch (e) {
      debugPrint(' Failed to get user details: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setUser(null); // Clear user on error

      // If it's an auth error, logout completely
      if (e.toString().contains('hết hạn') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        await _clearTokens();
      }
    }
  }

  /// Clear tokens from storage
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      debugPrint('Tokens cleared from storage');
    } catch (e) {
      debugPrint('⚠️ Error clearing tokens: $e');
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    if (_disposed) return;

    debugPrint('📤 Logging out...');
    _setLoading(true);
    _tokenRefreshTimer?.cancel();

    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint('⚠️ Error during API logout (ignoring): $e');
    }

    _setUser(null);
    _setError(null);
    _setLoading(false);
    debugPrint('Logout completed');
  }

  /// Xóa thông báo lỗi hiện tại
  void clearError() => _setError(null);

  /// Force refresh user data
  Future<void> refreshUserData() async {
    if (_disposed) return;

    debugPrint('Force refreshing user data...');
    _setError(null);
    await getUserDetails();
  }
}
