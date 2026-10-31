import { Router } from "express";
import { rateLimit } from "express-rate-limit";
import { createAiController } from "../controllers/ai-controller.js";
import { authenticate } from "../middleware/authenticate.js";
import { validate } from "../middleware/validate.js";
import { aiActions, aiRequestSchema } from "../validation/ai.js";
import { asyncHandler } from "../utils/async-handler.js";
import { ApiError } from "../utils/api-error.js";

export function createAiRouter(env) {
  const router = Router();
  const controller = createAiController(env);
  router.use(authenticate(env.JWT_ACCESS_SECRET));
  router.use(rateLimit({
    windowMs: 60 * 1000,
    limit: 20,
    standardHeaders: "draft-8",
    legacyHeaders: false,
  }));
  router.post("/:action", (req, res, next) => {
    if (!aiActions.includes(req.params.action)) {
      next(new ApiError(404, "AI_ACTION_NOT_FOUND", "This AI action is not available."));
      return;
    }
    next();
  }, validate(aiRequestSchema), asyncHandler(controller.run));
  return router;
}
