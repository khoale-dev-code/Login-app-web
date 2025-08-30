import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import styles from './Auth.module.css';
import { useState, useEffect } from 'react'; // Thêm useState và useEffect

const Login = () => {
  const navigate = useNavigate();
  const { register, handleSubmit, formState: { errors, isSubmitting }, reset } = useForm({
    mode: 'onBlur',
    reValidateMode: 'onBlur',
  });

  // Reset form khi component mount
  useEffect(() => {
    reset({
      email: "",
      password: "",
    });
  }, [reset]);

  // Hàm đăng nhập
  const onSubmit = async (data) => {
    try {
      const { data: res, status } = await axios.post(
        'http://localhost:3001/api/auth/login',
        data,
        { withCredentials: true }
      );

      if (status === 200) {
        const { accessToken } = res;
        if (accessToken) {
          localStorage.setItem('accessToken', accessToken);
          alert('Đăng nhập thành công!');
          navigate('/userDetails');
        } else {
          console.error("Không nhận được token");
        }
      }
    } catch (error) {
      const msg = error.response?.data?.message || 'Đăng nhập thất bại';
      console.error('Lỗi đăng nhập:', error);
      alert(msg);
    }
  };

 
  const renderInput = (id, label, type, rules, placeholder, isPassword = false) => {
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
            className={`${styles.input} ${errors[id] ? styles.inputError : ''}`}
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
        {errors[id] && <div className={styles.error}>{errors[id].message}</div>}
      </div>
    );
  };

  return (
    <div className={styles.authContainer}>
      <div className={styles.authForm}>
        <div className={styles.authHeader}>
          <h2 className={styles.authTitle}>Chào mừng trở lại</h2>
          <p className={styles.authSubtitle}>Đăng nhập vào tài khoản của bạn</p>
        </div>

        <form 
          onSubmit={handleSubmit(onSubmit)} 
          className={styles.formContainer}
          autoComplete="off" 
        >
          {renderInput('email', 'Email', 'email', {
            required: 'Vui lòng nhập email',
            pattern: {
              value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
              message: 'Địa chỉ email không hợp lệ',
            },
          }, 'Nhập địa chỉ email')}

          {renderInput('password', 'Mật khẩu', 'password', {
            required: 'Vui lòng nhập mật khẩu',
            minLength: { value: 6, message: 'Mật khẩu phải có ít nhất 6 ký tự' },
          }, 'Nhập mật khẩu', true)}  
         

          <button 
            type="submit" 
            className={`${styles.submitButton} ${isSubmitting ? styles.submitButtonLoading : ''}`}
            disabled={isSubmitting}
          >
            {isSubmitting ? <span className={styles.loadingSpinner}></span> : 'Đăng nhập'}
          </button>
        </form>

        <div className={styles.authFooter}>
          <p className={styles.toggleText}>
            Chưa có tài khoản?{' '}
            <Link to="/register" className={styles.toggleLink}>Đăng ký ngay</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;