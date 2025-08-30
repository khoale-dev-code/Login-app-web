// middleware/platform.js
export const platformDetection = (req, res, next) => {
  const userAgent = req.headers['user-agent'] || '';
  const ua = userAgent.toLowerCase();

  let platform = 'unknown';

  // Detect mobile devices
  if (/mobile|android|iphone|ipad|ipod/.test(ua)) {
    platform = 'mobile';
  }
  // Detect Flutter (mobile or web)
  else if (/flutter|dart/.test(ua)) {
    platform = 'flutter';
  }
  // Detect web browsers
  else if (/mozilla|chrome|safari|firefox|edge/.test(ua)) {
    platform = 'web';
  }
  // Detect Postman or API testing tools
  else if (/postman/.test(ua)) {
    platform = 'postman';
  }
  // Detect Node.js scripts (axios/fetch default UA)
  else if (/node|axios|fetch/.test(ua)) {
    platform = 'script';
  }

  req.platform = platform;
  next();
};
