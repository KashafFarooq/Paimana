import mongoose from "mongoose";

const orderStatuses = [
  "pending",
  "cutting",
  "stitching",
  "ready",
  "delivered",
  "cancelled",
];

const orderSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      immutable: true,
      index: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      default: null,
    },
    customerName: { type: String, required: true, trim: true, maxlength: 120 },
    garment: { type: String, required: true, trim: true, maxlength: 160 },
    dueDate: { type: Date, required: true },
    totalAmount: { type: Number, required: true, min: 0.01 },
    paidAmount: { type: Number, default: 0, min: 0 },
    status: { type: String, enum: orderStatuses, default: "pending" },
    note: { type: String, trim: true, maxlength: 2000, default: "" },
    clientId: { type: String, trim: true, maxlength: 80 },
    updatedFromClientAt: { type: Date },
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

orderSchema.index(
  { ownerId: 1, clientId: 1 },
  {
    unique: true,
    partialFilterExpression: { clientId: { $type: "string" } },
  },
);
orderSchema.index({ ownerId: 1, dueDate: 1 });
orderSchema.index({ ownerId: 1, status: 1 });

export { orderStatuses };
export default mongoose.model("Order", orderSchema);
