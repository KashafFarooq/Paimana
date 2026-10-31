import mongoose from "mongoose";
import Order from "../models/order.js";
import Payment from "../models/payment.js";
import { ApiError } from "../utils/api-error.js";

function findOwnedById(ownerId, id) {
  const identifier = /^[a-f\d]{24}$/i.test(id) ? { _id: id } : { clientId: id };
  return { ownerId, ...identifier };
}

function samePayment(payment, order, input) {
  return (
    payment.orderId.toString() === order._id.toString() &&
    payment.amount === input.amount &&
    payment.paymentType === input.paymentType &&
    payment.method === input.method &&
    payment.paidAt.getTime() === new Date(input.paidAt).getTime() &&
    payment.note === input.note
  );
}

export const paymentController = {
  list: async (req, res) => {
    const { orderId, page, limit } = req.validatedQuery;
    const filter = { ownerId: req.user.id };
    if (orderId) {
      const order = await Order.findOne(findOwnedById(req.user.id, orderId));
      if (!order) throw new ApiError(404, "ORDER_NOT_FOUND", "Order not found.");
      filter.orderId = order._id;
    }

    const [items, total] = await Promise.all([
      Payment.find(filter)
        .sort({ paidAt: -1, _id: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .populate({ path: "orderId", select: "clientId" }),
      Payment.countDocuments(filter),
    ]);
    const serialized = items.map((item) => {
      const value = item.toJSON();
      const order = item.orderId;
      value.orderId = order.clientId ?? order._id.toString();
      return value;
    });
    res.json({
      success: true,
      data: { items: serialized, total, page, limit },
    });
  },

  create: async (req, res) => {
    const session = await mongoose.startSession();
    let payment;
    try {
      await session.withTransaction(async () => {
        const order = await Order.findOne(
          findOwnedById(req.user.id, req.body.orderId),
        ).session(session);
        if (!order) {
          throw new ApiError(404, "ORDER_NOT_FOUND", "Order not found.");
        }

        if (req.body.clientId) {
          const existing = await Payment.findOne({
            ownerId: req.user.id,
            clientId: req.body.clientId,
          }).session(session);
          if (existing) {
            if (!samePayment(existing, order, req.body)) {
              throw new ApiError(
                409,
                "PAYMENT_CLIENT_ID_CONFLICT",
                "This payment identifier is already used for a different payment.",
              );
            }
            payment = existing;
            return;
          }
        }

        if (order.paidAmount + req.body.amount > order.totalAmount) {
          throw new ApiError(
            400,
            "PAYMENT_EXCEEDS_TOTAL",
            "Payment cannot exceed the remaining order balance.",
          );
        }
        const remainingBalance = order.totalAmount - order.paidAmount;
        if (
          req.body.paymentType === "final" &&
          Math.abs(req.body.amount - remainingBalance) > 0.000001
        ) {
          throw new ApiError(
            400,
            "FINAL_PAYMENT_MUST_CLEAR_BALANCE",
            "A final payment must clear the remaining order balance.",
          );
        }

        const update = await Order.updateOne(
          {
            ownerId: req.user.id,
            _id: order._id,
            paidAmount: { $lte: order.totalAmount - req.body.amount },
          },
          { $inc: { paidAmount: req.body.amount } },
          { session },
        );
        if (update.modifiedCount !== 1) {
          throw new ApiError(
            400,
            "PAYMENT_EXCEEDS_TOTAL",
            "Payment cannot exceed the remaining order balance.",
          );
        }

        const [created] = await Payment.create(
          [
            {
              ...req.body,
              ownerId: req.user.id,
              orderId: order._id,
              paidAt: new Date(req.body.paidAt),
            },
          ],
          { session },
        );
        payment = created;
      });
    } finally {
      await session.endSession();
    }
    const serialized = payment.toJSON();
    serialized.orderId = req.body.orderId;
    res.status(201).json({
      success: true,
      data: { payment: serialized },
    });
  },

  remove: async (req, res) => {
    const session = await mongoose.startSession();
    let payment;
    try {
      await session.withTransaction(async () => {
        payment = await Payment.findOne(
          findOwnedById(req.user.id, req.params.id),
        ).session(session);
        if (!payment) {
          throw new ApiError(404, "PAYMENT_NOT_FOUND", "Payment not found.");
        }

        const orderUpdate = await Order.updateOne(
          {
            ownerId: req.user.id,
            _id: payment.orderId,
            paidAmount: { $gte: payment.amount },
          },
          { $inc: { paidAmount: -payment.amount } },
          { session },
        );
        if (orderUpdate.modifiedCount !== 1) {
          throw new ApiError(
            409,
            "PAYMENT_BALANCE_CONFLICT",
            "The order balance no longer matches this payment.",
          );
        }
        await Payment.deleteOne({ _id: payment._id, ownerId: req.user.id }, { session });
      });
    } finally {
      await session.endSession();
    }
    res.json({ success: true, data: { id: payment.id } });
  },
};
