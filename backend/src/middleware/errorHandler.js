import { logger } from '../utils/logger.js';

export const errorHandler = (err, req, res, next) => {
  const isDev = process.env.NODE_ENV !== 'production';
  
  logger.error('Lỗi phát sinh', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    platform: req.platform,
    timestamp: new Date().toISOString()
  });

  // Phản hồi lỗi mặc định
  const errorResponse = {
    success: false,
    message: err.message || 'Lỗi máy chủ nội bộ',
    timestamp: new Date().toISOString(),
    path: req.path,
    method: req.method
  };

   if (isDev) {
    errorResponse.stack = err.stack;
    errorResponse.details = 'Chi tiết lỗi chỉ hiển thị trong môi trường phát triển';

  }

  // Trả về status code phù hợp
  const statusCode = err.statusCode || err.status || 500;
  res.status(statusCode).json(errorResponse);
};

export const notFoundHandler = (req, res) => {
  const availableEndpoints = [
    'GET /api/health - Kiểm tra tình trạng hệ thống',
    'GET /api/status - Thông tin chi tiết về trạng thái',
    'GET /api/docs - Tài liệu API',
    'POST /api/auth/register - Đăng ký tài khoản',
    'POST /api/auth/login - Đăng nhập',
    'GET /api/auth/getUserDetails - Thông tin người dùng',
    'POST /api/auth/logout - Đăng xuất',
    'GET /api/auth/refresh - Làm mới token'
  ];

 res.status(404).json({
    success: false,
    message: 'Không tìm thấy đường dẫn API',
    error: 'ENDPOINT_NOT_FOUND',
    path: req.path,
    method: req.method,
    availableEndpoints,
    suggestion: `Có thể bạn đang tìm: ${availableEndpoints[0]}`,
    timestamp: new Date().toISOString()
  });
};
