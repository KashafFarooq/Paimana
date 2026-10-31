import { Router } from "express";
import { paymentController } from "../controllers/payment-controller.js";
import { authenticate } from "../middleware/authenticate.js";
import { validate } from "../middleware/validate.js";
import { asyncHandler } from "../utils/async-handler.js";
import {
  paymentCreateSchema,
  paymentListQuerySchema,
} from "../validation/payments.js";

export function createPaymentRouter(env) {
  const router = Router();
  router.use(authenticate(env.JWT_ACCESS_SECRET));
  router.get(
    "/",
    validate(paymentListQuerySchema, "query"),
    asyncHandler(paymentController.list),
  );
  router.post(
    "/",
    validate(paymentCreateSchema),
    asyncHandler(paymentController.create),
  );
  router.delete("/:id", asyncHandler(paymentController.remove));
  return router;
}
