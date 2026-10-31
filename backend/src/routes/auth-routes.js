import { Router } from "express";
import { rateLimit } from "express-rate-limit";
import { createAuthController } from "../controllers/auth-controller.js";
import { authenticate } from "../middleware/authenticate.js";
import { validate } from "../middleware/validate.js";
import { loginSchema, refreshSchema, registerSchema } from "../validation/auth.js";
import { asyncHandler } from "../utils/async-handler.js";

export function createAuthRouter(env) {
  const router = Router();
  const controller = createAuthController(env);
  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    skipSuccessfulRequests: true,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: {
      success: false,
      error: { code: "RATE_LIMITED", message: "Too many sign-in attempts. Try again later." },
    },
  });

  router.use(authLimiter);
  router.post("/register", validate(registerSchema), asyncHandler(controller.register));
  router.post("/login", validate(loginSchema), asyncHandler(controller.login));
  router.post("/refresh", validate(refreshSchema), asyncHandler(controller.refresh));
  router.get("/me", authenticate(env.JWT_ACCESS_SECRET), asyncHandler(controller.me));
  router.post("/logout", authenticate(env.JWT_ACCESS_SECRET), asyncHandler(controller.logout));
  return router;
}
