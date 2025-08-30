import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    minlength: 3,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    match: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    trim: true,
  },
  mobile: {
    type: String,
    required: true,
    match: /^[0-9]{10}$/,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  lastLogin: {
    type: Date,
    default: null,
  },
}, { 
  timestamps: true,
  toJSON: { 
    transform: function(doc, ret) {
      delete ret.password;
      return ret;
    }
  }
});

// Index for performance
userSchema.index({ email: -1 });
userSchema.index({ createdAt: 1 });

export default mongoose.model("UserData", userSchema);