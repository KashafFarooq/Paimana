import mongoose from "mongoose";

const customerSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      immutable: true,
      index: true,
    },
    name: { type: String, required: true, trim: true, maxlength: 120 },
    phone: { type: String, trim: true, maxlength: 32, default: "" },
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

customerSchema.index(
  { ownerId: 1, clientId: 1 },
  {
    unique: true,
    partialFilterExpression: { clientId: { $type: "string" } },
  },
);
customerSchema.index({ ownerId: 1, updatedAt: -1 });

export default mongoose.model("Customer", customerSchema);
