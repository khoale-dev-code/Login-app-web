import User from "../models/User.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { generateAccessToken, generateRefreshToken } from "../token.js";

dotenv.config();

// Đăng ký tài khoản
export const registerUser = async (req, res) => {
  try {
    const { name, email, mobile, password } = req.body;
    const platform = req.platform || 'web';
    
    // Kiểm tra dữ liệu đầu vào
    if (!name || !email || !mobile || !password) {
      return res.status(400).json({ 
        thongBao: "Vui lòng nhập đầy đủ thông tin",
        truongThieu: { 
          hoTen: name, 
          email, 
          soDienThoai: mobile, 
          matKhau: password ? '***' : null 
        }
      });
    }

    // Kiểm tra email đã tồn tại
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ thongBao: "Email đã được đăng ký" });
    }

    // Mã hoá mật khẩu
    const saltRounds = 12;
    const hashed = await bcrypt.hash(password, saltRounds);

    // Tạo user mới
    const user = new User({ name, email, mobile, password: hashed });
    const savedUser = await user.save();

    res.status(201).json({ 
      thongBao: "Đăng ký thành công",
      maNguoiDung: savedUser._id,
      nenTang: platform,
      thoiGian: new Date().toISOString()
    });
  } catch (error) {
    console.error('Lỗi đăng ký:', error);
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({ 
        thongBao: "Lỗi xác thực dữ liệu", 
        chiTiet: Object.keys(error.errors).map(key => ({
          truong: key,
          loi: error.errors[key].message
        }))
      });
    }
    
    res.status(500).json({ thongBao: "Lỗi máy chủ", loi: error.message });
  }
};

// Đăng nhập
export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    const platform = req.platform || 'web';
    
    if (!email || !password) {
      return res.status(400).json({ thongBao: "Vui lòng nhập email và mật khẩu" });
    }

    // Tìm người dùng
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ thongBao: "Sai thông tin đăng nhập" });
    }

    // Kiểm tra mật khẩu
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ thongBao: "Sai thông tin đăng nhập" });
    }

    // Sinh token
    const accessToken = generateAccessToken(user._id, platform);
    const refreshToken = generateRefreshToken(user._id, platform);

    // Lưu cookie cho web
    if (platform === 'web') {
      res.cookie("refreshToken", refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: process.env.NODE_ENV === 'production' ? 'None' : 'Lax',
        maxAge: 7 * 24 * 60 * 60 * 1000, // 7 ngày
      });
    }

    // Cập nhật lần đăng nhập cuối
    user.lastLogin = new Date();
    await user.save();

    res.status(200).json({
      thongBao: "Đăng nhập thành công",
      accessToken,
      refreshToken: platform === 'mobile' ? refreshToken : undefined,
      nguoiDung: {
        id: user._id,
        hoTen: user.name,
        email: user.email,
        soDienThoai: user.mobile,
        taoLuc: user.createdAt,
        capNhatLuc: user.updatedAt
      },
      nenTang: platform,
      hetHanSau: "15 phút"
    });
  } catch (error) {
    console.error('Lỗi đăng nhập:', error);
    res.status(500).json({ thongBao: "Lỗi máy chủ", loi: error.message });
  }
};

// Lấy thông tin người dùng
export const getUserDetails = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(" ")[1];
    
    if (!token) {
      return res.status(401).json({ thongBao: "Thiếu access token" });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.ACCESS_SECRET);
    } catch (jwtError) {
      return res.status(403).json({ 
        thongBao: "Token không hợp lệ hoặc đã hết hạn",
        maLoi: "TOKEN_INVALID"
      });
    }

    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      return res.status(404).json({ thongBao: "Không tìm thấy người dùng" });
    }

    res.status(200).json({
      id: user._id,
      hoTen: user.name,
      email: user.email,
      soDienThoai: user.mobile,
      taoLuc: user.createdAt,
      capNhatLuc: user.updatedAt,
      dangNhapCuoi: user.lastLogin,
      nenTang: decoded.platform || 'không xác định'
    });
  } catch (error) {
    console.error('Lỗi lấy thông tin:', error);
    return res.status(500).json({ thongBao: "Lỗi máy chủ", loi: error.message });
  }
};

// Làm mới access token
export const refreshAccessToken = async (req, res) => {
  try {
    const platform = req.platform || 'web';
    let refreshToken;

    if (platform === 'web') {
      refreshToken = req.cookies.refreshToken;
    } else {
      refreshToken = req.body.refreshToken;
    }
    
    if (!refreshToken) {
      return res.status(401).json({ 
        thongBao: "Thiếu refresh token",
        nenTang: platform
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);
    } catch (jwtError) {
      return res.status(403).json({ 
        thongBao: "Refresh token không hợp lệ hoặc đã hết hạn",
        maLoi: "REFRESH_TOKEN_INVALID"
      });
    }

    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(404).json({ thongBao: "Không tìm thấy người dùng" });
    }

    const newAccessToken = generateAccessToken(user._id, decoded.platform || platform);
    
    res.status(200).json({ 
      accessToken: newAccessToken,
      nenTang: decoded.platform || platform,
      hetHanSau: "15 phút"
    });
  } catch (error) {
    console.error('Lỗi làm mới token:', error);
    return res.status(500).json({ thongBao: "Lỗi máy chủ", loi: error.message });
  }
};

// Đăng xuất
export const logout = async (req, res) => {
  try {
    const platform = req.platform || 'web';
    
    if (platform === 'web') {
      res.clearCookie("refreshToken");
    }
    
    res.status(200).json({ 
      thongBao: "Đăng xuất thành công",
      nenTang: platform,
      thoiGian: new Date().toISOString()
    });
  } catch (error) {
    console.error('Lỗi đăng xuất:', error);
    return res.status(500).json({ thongBao: "Lỗi máy chủ", loi: error.message });
  }
};
