import { logger } from '../utils/logger.js';

export const requestLogger = (req, res, next) => {
  const startTime = Date.now();
  const timestamp = new Date().toISOString();
  
  // Ghi log request
  logger.info('Yêu cầu đến', {
    method: req.method,
    url: req.url,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.headers['user-agent'],
    origin: req.headers.origin,
    timestamp
  });

  // Ghi log response khi hoàn tất
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logLevel = res.statusCode >= 400 ? 'error' : 'info';
    
    logger.log(logLevel, 'Yêu cầu hoàn tất', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip || req.connection.remoteAddress,
      timestamp: new Date().toISOString()
    });
  });

  next();
};
