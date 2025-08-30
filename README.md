# 🔐 Login App Web - Full Stack Authentication System

Hệ thống xác thực người dùng full-stack với đăng ký, đăng nhập và quản lý thông tin cá nhân. Dự án bao gồm backend API, frontend web và mobile app.

## 🚀 Tính năng

- ✅ Đăng ký tài khoản mới
- 🔑 Đăng nhập/đăng xuất
- 👤 Xem và chỉnh sửa thông tin cá nhân  
- 🔒 Xác thực JWT Token
- 📱 Hỗ trợ cả web và mobile app
- 🛡️ Bảo mật mật khẩu với bcrypt

## 🛠️ Công nghệ sử dụng

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **JWT** - Authentication
- **Bcrypt** - Password hashing

### Frontend Web
- **React.js** - Frontend framework
- **HTML/CSS/JavaScript** - Core technologies

### Mobile App  
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language

## 📁 Cấu trúc dự án

```
Login-app-web/
├── backend/           # API Server (Node.js + Express)
├── frontend-web/      # Web Application (React.js)
├── frontend-app/      # Mobile Application (Flutter)
├── README.md
└── .gitignore
```

## 🔧 Cài đặt và chạy dự án

### Yêu cầu hệ thống
- Node.js (v16+)
- MongoDB
- Flutter SDK
- Android Studio/Xcode (cho mobile development)

### 1. Clone repository
```bash
git clone https://github.com/khoale-dev-code/Login-app-web.git
cd Login-app-web
```

### 2. Setup Backend
```bash
cd backend
npm install
# Tạo file .env và cấu hình MongoDB connection
npm start
```

### 3. Setup Frontend Web
```bash
cd frontend-web
npm install
npm start
```

### 4. Setup Mobile App
```bash
cd frontend-app
flutter pub get
flutter run
```

## ⚙️ Cấu hình

### Environment Variables
Tạo file `.env` trong thư mục `backend/`:

```env
MONGODB_URI=mongodb://localhost:27017/loginapp
JWT_SECRET=your_jwt_secret_key
PORT=5000
```

## 📱 Screenshots

Thêm screenshots của ứng dụng web và mobile ở đây

## 🤝 Đóng góp

1. Fork dự án
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📄 License

Dự án này được phân phối dưới MIT License. Xem file `LICENSE` để biết thêm chi tiết.

## 👨‍💻 Tác giả

**Khoa Le** - [khoale-dev-code](https://github.com/khoale-dev-code)

## 📞 Liên hệ

- **GitHub**: [@khoale-dev-code](https://github.com/khoale-dev-code)
- **Email**: Lekhoale30092003@gmail.com
