import cors from "cors";

const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(",").map((origin) => origin.trim())
  : [
      "http://localhost:5173",   // React dev (Vite default)
      "http://localhost:3000",   // React dev (CRA default)
      "http://127.0.0.1",        // Local IP
      "http://10.0.2.2:3001",    // Android Emulator
      "http://localhost:3001",   // iOS Simulator
    ];

const corsConfig = cors({
  origin: (origin, callback) => {
    // Cho phép request không có origin (mobile app, Postman)
    if (!origin) return callback(null, true);

    // ✅ Cho phép tất cả localhost & 127.0.0.1 (mọi port)
    const localhostRegex = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

    if (
      allowedOrigins.includes(origin) ||
      localhostRegex.test(origin)
    ) {
      callback(null, true);
    } else {
      console.warn(`Blocked CORS request from: ${origin}`);
      const error = new Error("Không được phép truy cập từ nguồn này (CORS)");
      error.statusCode = 403;
      callback(error);
    }
  },

  credentials: true, // cho phép gửi cookie/token
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "X-Requested-With",
    "User-Agent",
    "Accept",
    "Origin",
  ],
  exposedHeaders: ["set-cookie"],
  maxAge: 86400, // cache preflight 24h
});

export default corsConfig;
