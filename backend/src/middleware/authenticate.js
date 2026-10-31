import jwt from "jsonwebtoken";
import { ApiError } from "../utils/api-error.js";
import { asyncHandler } from "../utils/async-handler.js";
import User from "../models/user.js";

export function authenticate(accessSecret) {
  return asyncHandler(async (req, res, next) => {
    const authorization = req.get("authorization");
    const [scheme, token] = authorization?.split(" ") ?? [];
    if (scheme !== "Bearer" || !token) {
      throw new ApiError(401, "AUTH_REQUIRED", "Sign in to continue.");
    }

    let claims;
    try {
      claims = jwt.verify(token, accessSecret);
    } catch {
      throw new ApiError(401, "INVALID_ACCESS_TOKEN", "Your session has expired.");
    }
    if (
      typeof claims !== "object" ||
      claims === null ||
      claims.type !== "access" ||
      typeof claims.sub !== "string"
    ) {
      throw new ApiError(401, "INVALID_ACCESS_TOKEN", "Your session is invalid.");
    }

    const user = await User.findById(claims.sub).select("_id name email");
    if (!user) {
      throw new ApiError(401, "ACCOUNT_NOT_FOUND", "Your account is no longer available.");
    }
    req.user = user;
    next();
  });
}
