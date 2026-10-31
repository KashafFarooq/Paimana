import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      maxlength: 254,
    },
    passwordHash: { type: String, required: true, select: false },
    tokenVersion: { type: Number, default: 0 },
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      virtuals: true,
      transform: (_document, value) => {
        value.id = value._id.toString();
        delete value._id;
        delete value.passwordHash;
        delete value.tokenVersion;
        return value;
      },
    },
  },
);

userSchema.index({ email: 1 }, { unique: true });

export default mongoose.model("User", userSchema);
