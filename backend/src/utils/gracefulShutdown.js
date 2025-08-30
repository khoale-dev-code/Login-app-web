import { logger } from './logger.js';

export const gracefulShutdown = (server) => {
  const shutdown = (signal) => {
    logger.info(`Nhận tín hiệu ${signal}, tiến hành tắt server an toàn...`);
    
    server.close((err) => {
      if (err) {
        logger.error('Lỗi khi đóng server:', err);
        process.exit(1);
      }
      
      logger.info('Server đã đóng thành công');
      process.exit(0);
    });

    // Nếu sau 10 giây vẫn chưa tắt thì ép tắt
    setTimeout(() => {
      logger.error('Không thể đóng kết nối kịp thời, buộc dừng server ngay!');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM')); // Dừng do hệ thống gửi
  process.on('SIGINT', () => shutdown('SIGINT'));   // Dừng do Ctrl+C
  
  // Xử lý lỗi không được bắt
  process.on('uncaughtException', (err) => {
    logger.error('Lỗi nghiêm trọng (Uncaught Exception):', err);
    process.exit(1);
  });

  // Xử lý Promise bị reject mà không có catch
  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Promise bị reject mà không xử lý (Unhandled Rejection):', {
      promise,
      reason
    });
    process.exit(1);
  });
};
