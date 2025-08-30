import express from 'express';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import cookieParser from 'cookie-parser';
import connectDB from './config/db.js';
import corsConfig from './config/cors.js';
import { logger } from './utils/logger.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import { requestLogger } from './middleware/requestLogger.js';
import { platformDetection } from './middleware/platform.js';
import { gracefulShutdown } from './utils/gracefulShutdown.js';
import authRoute from './routes/UserRoutes.js';

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// Compression
app.use(compression({
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  },
  threshold: 1024
}));

// CORS
app.use(corsConfig);

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    success: false,
    message: 'Quá nhiều yêu cầu từ IP này',
    error: 'TOO_MANY_REQUESTS',
    retryAfter: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
    timestamp: new Date().toISOString()
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/api/health';
  }
});
app.use('/api', limiter);

// Body parsing middleware
app.use(express.json({ 
  limit: process.env.JSON_LIMIT || '10mb',
  type: ['application/json', 'text/plain']
}));
app.use(express.urlencoded({ 
  extended: true, 
  limit: process.env.URL_ENCODED_LIMIT || '10mb'
}));
app.use(cookieParser());

// Custom middleware
app.use(requestLogger);
app.use(platformDetection);

// Health check endpoints
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Hệ thống hoạt động bình thường',
    status: 'OK',
    timestamp: new Date().toISOString(),
    platform: req.platform,
    server: 'Express',
    version: process.env.API_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: Math.floor(process.uptime()) + ' giây'
  });
});

app.get('/api/status', async (req, res) => {
  try {
    // Check database connection
    const dbStatus = await checkDatabaseConnection();
    
    res.status(200).json({
      success: true,
      message: 'Trạng thái hệ thống',
      data: {
        database: dbStatus ? 'Đã kết nối' : 'Mất kết nối',
        server: 'Đang hoạt động',
        timestamp: new Date().toISOString(),
        uptime: Math.floor(process.uptime()) + ' giây',
        platform: req.platform,
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
        },
        environment: process.env.NODE_ENV || 'development'
      }
    });
  } catch (error) {
    logger.error('Kiểm tra trạng thái hệ thống thất bại:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi kiểm tra trạng thái hệ thống',
      data: {
        database: 'Lỗi kết nối',
        server: 'Hoạt động với vấn đề',
        timestamp: new Date().toISOString(),
        error: process.env.NODE_ENV === 'development' ? error.message : 'Lỗi nội bộ'
      }
    });
  }
});

// API routes
app.use('/api/auth', authRoute);

// API documentation endpoint
app.get('/api/docs', (req, res) => {
  res.json({
    success: true,
    message: 'Tài liệu API',
    data: {
      title: 'Tài liệu API hệ thống',
      version: process.env.API_VERSION || '1.0.0',
      description: 'API cho ứng dụng xác thực người dùng',
      baseUrl: `http://localhost:${PORT}/api`,
      endpoints: {
        health: {
          method: 'GET',
          path: '/api/health',
          description: 'Kiểm tra tình trạng hoạt động của hệ thống'
        },
        status: {
          method: 'GET',
          path: '/api/status',
          description: 'Thông tin chi tiết về trạng thái hệ thống'
        },
        auth: {
          description: 'Các API liên quan đến xác thực',
          endpoints: {
            register: { 
              method: 'POST', 
              path: '/api/auth/register',
              description: 'Đăng ký tài khoản mới'
            },
            login: { 
              method: 'POST', 
              path: '/api/auth/login',
              description: 'Đăng nhập vào hệ thống'
            },
            logout: { 
              method: 'POST', 
              path: '/api/auth/logout',
              description: 'Đăng xuất khỏi hệ thống'
            },
            refresh: { 
              method: 'GET', 
              path: '/api/auth/refresh',
              description: 'Làm mới token xác thực'
            },
            userDetails: { 
              method: 'GET', 
              path: '/api/auth/getUserDetails',
              description: 'Lấy thông tin chi tiết người dùng'
            }
          }
        }
      }
    }
  });
});

// Error handlers (must be last)
app.use(notFoundHandler);
app.use(errorHandler);

async function checkDatabaseConnection() {
  try {
    return mongoose.connection.readyState === 1; // 1 = connected
  } catch (error) {
    logger.error('Kiểm tra kết nối cơ sở dữ liệu thất bại:', error);
    return false;
  }
}
// Start server
async function startServer() {
  try {
    // Connect to database first
    await connectDB();
    logger.info('Kết nối cơ sở dữ liệu thành công');

    const server = app.listen(PORT, () => {
      logger.info(`Server đang chạy tại http://localhost:${PORT}`);
      logger.info(`Ứng dụng di động có thể kết nối tại:`);
      logger.info(`   Android: http://10.0.2.2:${PORT}`);
      logger.info(`   iOS: http://localhost:${PORT}`);
      logger.info(`Ứng dụng web: http://localhost:${PORT}`);
      logger.info(`Kiểm tra tình trạng: http://localhost:${PORT}/api/health`);
      logger.info(`Tài liệu API: http://localhost:${PORT}/api/docs`);
    });

    // Setup graceful shutdown
    gracefulShutdown(server);

  } catch (error) {
    logger.error('Khởi động server thất bại:', error);
    process.exit(1);
  }
}

// Start the application
startServer();

export default app;