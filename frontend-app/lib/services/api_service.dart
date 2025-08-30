import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_auth_flutter/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service gọi API cho xác thực người dùng với debugging
class ApiService {
  static const String _baseUrl = 'http://localhost:3001/api/auth';

  /// Trả về URL API theo nền tảng
  static String getBaseUrl() {
    if (kIsWeb) return _baseUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3001/api/auth';
      case TargetPlatform.iOS:
        return _baseUrl;
      default:
        return _baseUrl;
    }
  }

  /// Xác định chuỗi nền tảng (cho User-Agent)
  static String _getPlatformString() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Sinh headers mặc định, kèm token nếu cần
  static Future<Map<String, String>> _getHeaders({
    bool needsAuth = false,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': 'FlutterApp/1.0 (${_getPlatformString()})',
    };

    if (needsAuth) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
          debugPrint(
            'Token được thêm vào header: ${token.substring(0, 20)}...',
          );
        } else {
          debugPrint('⚠️ Không tìm thấy token trong SharedPreferences');
        }
      } catch (e) {
        debugPrint('⚠️ Lỗi khi lấy token: $e');
      }
    }
    return headers;
  }

  /// Gọi API đăng ký
  static Future<bool> register(RegisterRequest request) async {
    final url = '${getBaseUrl()}/register';
    debugPrint('Gọi API Register: $url');

    try {
      final headers = await _getHeaders();
      debugPrint('Headers: $headers');

      final body = jsonEncode(request.toJson());
      debugPrint('Body: $body');

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) return true;

      final error = _extractError(response);
      throw Exception(error ?? 'Đăng ký thất bại');
    } on TimeoutException {
      throw Exception('Hết thời gian chờ. Vui lòng thử lại.');
    } catch (e) {
      debugPrint('Lỗi register: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        throw Exception(
          'Lỗi mạng. Hãy chắc chắn backend chạy ở http://localhost:3001',
        );
      }
      throw Exception('Đăng ký thất bại: ${_formatError(e)}');
    }
  }

  /// Gọi API đăng nhập - Fixed cho Vietnamese backend
  static Future<LoginResponse> login(LoginRequest request) async {
    final url = '${getBaseUrl()}/login';
    debugPrint('📤 Gọi API Login: $url');

    try {
      final headers = await _getHeaders();
      debugPrint('📋 Headers: $headers');

      final body = jsonEncode(request.toJson());
      debugPrint(' Body: $body');

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Lưu token vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['accessToken']);
        debugPrint('Đã lưu access_token');

        // Refresh token có thể không có trong response
        if (data['refreshToken'] != null) {
          await prefs.setString('refresh_token', data['refreshToken']);
          debugPrint(' Đã lưu refresh_token');
        }

        // Parse user data theo format Vietnamese backend
        final userData = data['nguoiDung'] ?? data['user'];
        if (userData == null) {
          throw Exception('Không nhận được thông tin người dùng từ server');
        }

        // Convert Vietnamese field names to English for User model
        final userJson = {
          'id': userData['id'],
          'name': userData['hoTen'] ?? userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'mobile': userData['soDienThoai'] ?? userData['mobile'] ?? '',
          'createdAt':
              userData['taoLuc'] ??
              userData['createdAt'] ??
              DateTime.now().toIso8601String(),
          'updatedAt':
              userData['capNhatLuc'] ??
              userData['updatedAt'] ??
              DateTime.now().toIso8601String(),
        };

        debugPrint('Converted user data: $userJson');

        return LoginResponse(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'], // Có thể null
          user: User.fromJson(userJson),
        );
      }

      final error = _extractError(response);
      throw Exception(error ?? 'Đăng nhập thất bại');
    } catch (e) {
      debugPrint('Lỗi login: $e');
      throw Exception(_formatError(e));
    }
  }

  /// Lấy thông tin người dùng - Fixed cho Vietnamese backend
  static Future<User> getUserDetails() async {
    final url = '${getBaseUrl()}/getUserDetails';
    debugPrint(' Gọi API getUserDetails: $url');

    try {
      // Kiểm tra token trước khi gọi API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      debugPrint(
        'Token hiện tại: ${token != null ? '${token.substring(0, 20)}...' : 'null'}',
      );

      final headers = await _getHeaders(needsAuth: true);
      debugPrint('Headers: $headers');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final userData = data['nguoiDung'] ?? data['user'] ?? data;

        final userJson = {
          'id': userData['id'],
          'name': userData['hoTen'] ?? userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'mobile': userData['soDienThoai'] ?? userData['mobile'] ?? '',
          'createdAt':
              userData['taoLuc'] ??
              userData['createdAt'] ??
              DateTime.now().toIso8601String(),
          'updatedAt':
              userData['capNhatLuc'] ??
              userData['updatedAt'] ??
              DateTime.now().toIso8601String(),
        };

        debugPrint('Converted user data: $userJson');
        return User.fromJson(userJson);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Token hết hạn, thử refresh...');
        // Token hết hạn → refresh rồi gọi lại
        final refreshed = await _refreshToken();
        if (refreshed) {
          debugPrint('✅ Refresh token thành công, gọi lại API...');
          final retryHeaders = await _getHeaders(needsAuth: true);
          final retry = await http
              .get(Uri.parse(url), headers: retryHeaders)
              .timeout(const Duration(seconds: 30));

          debugPrint('Retry response status: ${retry.statusCode}');
          debugPrint('Retry response body: ${retry.body}');

          if (retry.statusCode == 200) {
            final retryData = jsonDecode(retry.body);
            final retryUserData =
                retryData['nguoiDung'] ?? retryData['user'] ?? retryData;

            final retryUserJson = {
              'id': retryUserData['id'],
              'name': retryUserData['hoTen'] ?? retryUserData['name'] ?? '',
              'email': retryUserData['email'] ?? '',
              'mobile':
                  retryUserData['soDienThoai'] ?? retryUserData['mobile'] ?? '',
              'createdAt':
                  retryUserData['taoLuc'] ??
                  retryUserData['createdAt'] ??
                  DateTime.now().toIso8601String(),
              'updatedAt':
                  retryUserData['capNhatLuc'] ??
                  retryUserData['updatedAt'] ??
                  DateTime.now().toIso8601String(),
            };

            return User.fromJson(retryUserJson);
          }
        }
        throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.');
      }

      final error = _extractError(response);
      throw Exception(error ?? 'Lấy thông tin người dùng thất bại');
    } catch (e) {
      debugPrint('Lỗi getUserDetails: $e');
      throw Exception(_formatError(e));
    }
  }

  /// Làm mới access token
  static Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      debugPrint('Refresh token: ${refreshToken != null ? 'có' : 'không'}');

      if (refreshToken == null) return false;

      final response = await http
          .post(
            Uri.parse('${getBaseUrl()}/refresh'),
            headers: await _getHeaders(),
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Refresh response status: ${response.statusCode}');
      debugPrint('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['accessToken']);
        debugPrint('✅ Đã cập nhật access token mới');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi refresh token: $e');
      return false;
    }
  }

  /// Đăng xuất
  static Future<bool> logout() async {
    debugPrint('Gọi API logout...');
    try {
      await http
          .post(
            Uri.parse('${getBaseUrl()}/logout'),
            headers: await _getHeaders(needsAuth: true),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('✅ API logout thành công');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi gọi API logout (bỏ qua): $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      debugPrint('Đã xóa tokens khỏi SharedPreferences');
    }
    return true;
  }

  /// Kiểm tra kết nối server
  static Future<bool> checkConnection() async {
    final url = '${getBaseUrl()}/health';
    debugPrint('Kiểm tra kết nối: $url');
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      debugPrint('Health check status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Kết nối thất bại: $e');
      return false;
    }
  }

  /// Trích xuất lỗi từ response API
  static String? _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? data['thongBao'] ?? data['loi'];
    } catch (_) {
      return null;
    }
  }

  /// Chuẩn hóa thông báo lỗi
  static String _formatError(dynamic error) {
    String msg = error.toString();
    if (msg.startsWith('Exception: ')) msg = msg.substring(11);
    return msg;
  }
}

/// Exception cho timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
