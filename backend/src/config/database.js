import mongoose from "mongoose";

export async function connectDatabase(uri) {
  await mongoose.connect(uri, {
    autoIndex: process.env.NODE_ENV !== "production",
    serverSelectionTimeoutMS: 10000,
  });
  return mongoose.connection;
}
