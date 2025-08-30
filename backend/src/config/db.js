import mongoose from "mongoose";
import dotenv from 'dotenv';
dotenv.config();
const connectDB=async()=>{
    try {
        await mongoose.connect(process.env.MONGO_URL);
        console.log("Mongoose Connected!!!");
        
    } catch (error) {
        console.log("Connection Failed",error);
        process.exit(1);
        
    }
}
export default connectDB;