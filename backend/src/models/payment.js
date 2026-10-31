import mongoose from "mongoose";

const paymentSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      immutable: true,
      index: true,
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      required: true,
      immutable: true,
    },
    clientId: { type: String, trim: true, maxlength: 80 },
    amount: { type: Number, required: true, min: 0.01 },
    paymentType: {
      type: String,
      enum: ["advance", "partial", "final"],
      required: true,
    },
    method: {
      type: String,
      enum: ["cash", "bank_transfer", "mobile_wallet", "other"],
      required: true,
    },
    paidAt: { type: Date, required: true },
    note: { type: String, trim: true, maxlength: 500, default: "" },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform: (_document, value) => {
        value.id = value._id.toString();
        delete value._id;
        delete value.ownerId;
        return value;
      },
    },
  },
);

paymentSchema.index(
  { ownerId: 1, clientId: 1 },
  {
    unique: true,
    partialFilterExpression: { clientId: { $type: "string" } },
  },
);
paymentSchema.index({ ownerId: 1, orderId: 1, paidAt: -1 });

export default mongoose.model("Payment", paymentSchema);
