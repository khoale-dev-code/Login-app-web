import jwt from "jsonwebtoken";

export const generateAccessToken = (userId, platform = 'web') => {
  return jwt.sign(
    { 
      userId: userId,
      platform: platform,
      type: 'access'
    }, 
    process.env.ACCESS_SECRET, 
    { expiresIn: "15m" }
  );
}

export const generateRefreshToken = (userId, platform = 'web') => {
  const expiresIn = platform === 'mobile' ? "30d" : "7d";
  
  return jwt.sign(
    { 
      userId: userId,
      platform: platform,
      type: 'refresh'
    }, 
    process.env.REFRESH_SECRET, 
    { expiresIn: expiresIn }
  );
}