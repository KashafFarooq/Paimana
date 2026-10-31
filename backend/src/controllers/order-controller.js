import mongoose from "mongoose";
import Customer from "../models/customer.js";
import Order from "../models/order.js";
import Payment from "../models/payment.js";
import { ApiError } from "../utils/api-error.js";

function findOwnedById(ownerId, id) {
  const identifier = /^[a-f\d]{24}$/i.test(id) ? { _id: id } : { clientId: id };
  return { ownerId, ...identifier };
}

function assertPaymentWithinTotal(order) {
  if (order.paidAmount > order.totalAmount) {
    throw new ApiError(
      400,
      "PAYMENT_EXCEEDS_TOTAL",
      "Paid amount cannot exceed the order total.",
    );
  }
}

async function validateCustomerOwnership(customerId, ownerId) {
  if (!customerId) return;
  const customerExists = await Customer.exists({ _id: customerId, ownerId });
  if (!customerExists) {
    throw new ApiError(404, "CUSTOMER_NOT_FOUND", "The selected customer was not found.");
  }
}

export const orderController = {
  list: async (req, res) => {
    const { status, page, limit, updatedSince } = req.validatedQuery;
    const filter = { ownerId: req.user.id };
    if (status) filter.status = status;
    if (updatedSince) filter.updatedAt = { $gte: new Date(updatedSince) };

    const [items, total] = await Promise.all([
      Order.find(filter)
        .sort({ dueDate: 1, _id: 1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Order.countDocuments(filter),
    ]);
    res.json({ success: true, data: { items, total, page, limit } });
  },

  create: async (req, res) => {
    const { clientId, ...fields } = req.body;
    await validateCustomerOwnership(fields.customerId, req.user.id);
    if (clientId) {
      const { paidAmount, ...mutableFields } = fields;
      const item = await Order.findOneAndUpdate(
        { ownerId: req.user.id, clientId },
        {
          $set: {
            ...mutableFields,
            clientId,
            updatedFromClientAt: new Date(),
          },
          $setOnInsert: { paidAmount },
        },
        { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
      );
      res.status(201).json({ success: true, data: { order: item } });
      return;
    }
    const item = await Order.create({ ...fields, ownerId: req.user.id });
    res.status(201).json({ success: true, data: { order: item } });
  },

  get: async (req, res) => {
    const item = await Order.findOne(findOwnedById(req.user.id, req.params.id));
    if (!item) throw new ApiError(404, "ORDER_NOT_FOUND", "Order not found.");
    res.json({ success: true, data: { order: item } });
  },

  update: async (req, res) => {
    const existing = await Order.findOne(findOwnedById(req.user.id, req.params.id));
    if (!existing) throw new ApiError(404, "ORDER_NOT_FOUND", "Order not found.");

    const nextCustomerId = req.body.customerId === undefined
      ? existing.customerId
      : req.body.customerId;
    await validateCustomerOwnership(nextCustomerId, req.user.id);
    const nextTotal = req.body.totalAmount ?? existing.totalAmount;
    const nextPaid = req.body.paidAmount ?? existing.paidAmount;
    assertPaymentWithinTotal({ paidAmount: nextPaid, totalAmount: nextTotal });

    Object.assign(existing, req.body, { updatedFromClientAt: new Date() });
    await existing.save();
    res.json({ success: true, data: { order: existing } });
  },

  remove: async (req, res) => {
    const session = await mongoose.startSession();
    let item;
    try {
      await session.withTransaction(async () => {
        item = await Order.findOneAndDelete(
          findOwnedById(req.user.id, req.params.id),
          { session },
        );
        if (!item) {
          throw new ApiError(404, "ORDER_NOT_FOUND", "Order not found.");
        }
        await Payment.deleteMany(
          { ownerId: req.user.id, orderId: item._id },
          { session },
        );
      });
    } finally {
      await session.endSession();
    }
    res.json({ success: true, data: { id: item.id } });
  },
};
