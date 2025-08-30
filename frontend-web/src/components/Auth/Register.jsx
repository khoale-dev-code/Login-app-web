import { useForm } from "react-hook-form";
import styles from "./Auth.module.css";
import { Link } from "react-router-dom";
import axios from "axios";
import { useState, useEffect } from "react";  
const InputField = ({ id, label, type = "text", placeholder, register, rules, error, isPassword = false }) => {
  const [showPassword, setShowPassword] = useState(false);  
  const inputType = isPassword ? (showPassword ? "text" : "password") : type;

  return (
    <div className={styles.inputGroup}>
      <label htmlFor={id} className={styles.label}>
        {label} <span className={styles.required}>*</span>
      </label>
      <div className={styles.passwordWrapper}>  
        <input
          id={id}
          type={inputType}
          className={`${styles.input} ${error ? styles.inputError : ""}`}
          placeholder={placeholder}
          {...register(id, rules)}
          autoComplete="off" 
        />
        {isPassword && (
          <span
            className={styles.eyeIcon}
            onClick={() => setShowPassword(!showPassword)}
          >
            {showPassword ? "👁️" : "👁️‍🗨️"}  
          </span>
        )}
      </div>
      {error && <div className={styles.error}>{error.message}</div>}
    </div>
  );
};

const Register = () => {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset, // Thêm reset từ useForm
  } = useForm({ mode: "onChange", reValidateMode: "onChange" });

  // Reset form khi component mount
  useEffect(() => {
    reset({
      name: "",
      email: "",
      mobile: "",
      password: "",
    });
  }, [reset]);

  const onSubmit = async (data) => {
    try {
      const response = await axios.post("http://localhost:3001/api/auth/register", data);
      if (response.status === 201) alert("Đăng ký thành công!");
    } catch (error) {
      console.error("Lỗi đăng ký:", error);
      alert(error.response?.data?.message || "Đã xảy ra lỗi. Vui lòng thử lại.");
    }
  };

  return (
    <div className={styles.authContainer}>
      <div className={styles.authForm}>
        <div className={styles.authHeader}>
          <h2 className={styles.authTitle}>Tạo tài khoản</h2>
          <p className={styles.authSubtitle}>Đăng ký để truy cập vào tài khoản của bạn</p>
        </div>
        <form 
          onSubmit={handleSubmit(onSubmit)} 
          className={styles.formContainer}
          autoComplete="off" // Tắt autocomplete cho form
        >
          <InputField
            id="name"
            label="Họ và tên"
            placeholder="Nhập họ và tên của bạn"
            register={register}
            rules={{
              required: "Vui lòng nhập họ và tên",
              minLength: { value: 3, message: "Họ và tên phải có ít nhất 3 ký tự" },
            }}
            error={errors.name}
          />
          <InputField
            id="email"
            type="email"
            label="Email"
            placeholder="example@email.com"
            register={register}
            rules={{
              required: "Vui lòng nhập email",
              pattern: { value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "Email không hợp lệ" },
            }}
            error={errors.email}
          />
          <InputField
            id="mobile"
            label="Số điện thoại"
            placeholder="0123456789"
            register={register}
            rules={{
              required: "Vui lòng nhập số điện thoại",
              pattern: { value: /^[0-9]{10,11}$/, message: "Số điện thoại phải có 10-11 chữ số" },
            }}
            error={errors.mobile}
          />
          <InputField
            id="password"
            label="Mật khẩu"
            placeholder="Nhập mật khẩu"
            register={register}
            rules={{
              required: "Vui lòng nhập mật khẩu",
              minLength: { value: 6, message: "Mật khẩu phải có ít nhất 6 ký tự" },
            }}
            error={errors.password}
            isPassword={true} // Kích hoạt toggle password
          />
          <button
            type="submit"
            className={`${styles.submitButton} ${isSubmitting ? styles.submitButtonLoading : ""}`}
            disabled={isSubmitting}
          >
            {isSubmitting ? <span className={styles.loadingSpinner}></span> : "Đăng ký"}
          </button>
        </form>
        <div className={styles.authFooter}>
          <p className={styles.toggleText}>
            Đã có tài khoản?{" "}
            <Link to="/login" className={styles.toggleLink}>
              Đăng nhập ngay
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Register;