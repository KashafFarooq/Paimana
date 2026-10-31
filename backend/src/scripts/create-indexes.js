import "dotenv/config";
import mongoose from "mongoose";
import { connectDatabase } from "../config/database.js";
import { readEnv } from "../config/env.js";
import Customer from "../models/customer.js";
import Order from "../models/order.js";
import Payment from "../models/payment.js";
import User from "../models/user.js";

const env = readEnv();
try {
  await connectDatabase(env.MONGODB_URI);
  for (const model of [User, Customer, Order, Payment]) {
    await model.createIndexes();
    console.info(`Indexes ensured for ${model.collection.collectionName}.`);
  }
} finally {
  await mongoose.disconnect();
}
