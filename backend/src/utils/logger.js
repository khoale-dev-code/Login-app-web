import winston from 'winston';

// Định dạng log
const logFormat = winston.format.combine(
  winston.format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss' // Thêm timestamp vào log
  }),
  winston.format.errors({ stack: true }), // Hiển thị cả stack trace nếu có lỗi
  winston.format.json() // Log ở dạng JSON (dễ tích hợp hệ thống log)
);

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info', // Mức log mặc định (info trở lên)
  format: logFormat,
  defaultMeta: { service: 'express-api' }, // Thông tin mặc định gắn kèm
  transports: [
    // In log ra màn hình console (dùng khi dev)
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(), // Tô màu log theo level (error đỏ, warn vàng, info xanh…)
        winston.format.simple()    // Hiển thị ngắn gọn hơn cho dễ đọc
      )
    })
  ]
});

// Nếu chạy môi trường production thì ghi log vào file
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({
    filename: 'logs/error.log',   // File chứa log lỗi
    level: 'error',               // Chỉ ghi lỗi
    maxsize: 5242880,             // Giới hạn file 5MB
    maxFiles: 10                  // Giữ tối đa 10 file xoay vòng
  }));
  
  logger.add(new winston.transports.File({
    filename: 'logs/combined.log', // File chứa tất cả log (info, warn, error…)
    maxsize: 5242880,
    maxFiles: 10
  }));
}

export { logger };
