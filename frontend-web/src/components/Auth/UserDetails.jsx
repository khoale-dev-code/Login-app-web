import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import styles from "./Auth.module.css";

const UserDetails = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const navigate = useNavigate();

  // Hàm gọi API lấy thông tin user
  const getUser = async (token) => {
    return axios.get("http://localhost:3001/api/auth/getUserDetails", {
      headers: { Authorization: `Bearer ${token}` },
      withCredentials: true,
    });
  };

  // Lấy thông tin user khi load trang
  useEffect(() => {
    const fetchUser = async () => {
      const token = localStorage.getItem("accessToken");
      if (!token) return navigate("/login");

      try {
        const res = await getUser(token);
        setUser(res.data);
      } catch (err) {
        // Nếu token hết hạn → refresh
        if (err.response?.status === 401 || err.response?.status === 403) {
          try {
            const refreshRes = await axios.get(
              "http://localhost:3001/api/auth/refresh",
              { withCredentials: true }
            );
            const newToken = refreshRes.data.accessToken;
            localStorage.setItem("accessToken", newToken);

            const retry = await getUser(newToken);
            setUser(retry.data);
          } catch {
            localStorage.clear();
            navigate("/login");
          }
        } else {
          setError("Không thể tải thông tin người dùng.");
          console.error(err);
        }
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, [navigate]);

  // Xử lý logout
  const handleLogout = async () => {
    setIsLoggingOut(true);
    try {
      await axios.post(
        "http://localhost:3001/api/auth/logout",
        {},
        { withCredentials: true }
      );
      localStorage.clear();
      navigate("/login");
    } catch {
      alert("Đăng xuất thất bại, vui lòng thử lại.");
    } finally {
      setIsLoggingOut(false);
    }
  };

  // Trạng thái loading
  if (loading) {
    return (
      <div className={styles.authContainer}>
        <div className={styles.loadingContainer}>
          <div className={styles.loadingSpinner}></div>
          <p className={styles.loadingText}>Đang tải thông tin...</p>
        </div>
      </div>
    );
  }

  // Trạng thái lỗi
  if (error || !user) {
    return (
      <div className={styles.authContainer}>
        <div className={styles.errorContainer}>
          <p className={styles.errorText}>{error || "Có lỗi xảy ra."}</p>
          <button onClick={() => navigate("/login")} className={styles.submitButton}>
            Quay lại đăng nhập
          </button>
        </div>
      </div>
    );
  }

  // Hiển thị thông tin user
  return (
    <div className={styles.authContainer}>
      <div className={styles.authForm}>
        <div className={styles.authHeader}>
          <h2 className={styles.authTitle}>Thông tin tài khoản</h2>
          <p className={styles.authSubtitle}>Quản lý chi tiết cá nhân của bạn</p>
        </div>

        <div className={styles.userInfoCard}>
          <div className={styles.userInfoItem}>
            <span className={styles.userInfoLabel}>Họ và tên:</span>
            <span className={styles.userInfoValue}>{user.name}</span>
          </div>
          <div className={styles.userInfoItem}>
            <span className={styles.userInfoLabel}>Email:</span>
            <span className={styles.userInfoValue}>{user.email}</span>
          </div>
          <div className={styles.userInfoItem}>
            <span className={styles.userInfoLabel}>Số điện thoại:</span>
            <span className={styles.userInfoValue}>{user.mobile}</span>
          </div>
        </div>

        <button
          onClick={handleLogout}
          disabled={isLoggingOut}
          className={`${styles.submitButton} ${styles.logoutButton}`}
        >
          {isLoggingOut ? "Đang đăng xuất..." : "Đăng xuất"}
        </button>
      </div>
    </div>
  );
};

export default UserDetails;
