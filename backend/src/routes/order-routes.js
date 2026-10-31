import { Router } from "express";
import { orderController } from "../controllers/order-controller.js";
import { authenticate } from "../middleware/authenticate.js";
import { validate } from "../middleware/validate.js";
import {
  orderCreateSchema,
  orderListQuerySchema,
  orderUpdateSchema,
} from "../validation/orders.js";
import { asyncHandler } from "../utils/async-handler.js";

export function createOrderRouter(env) {
  const router = Router();
  router.use(authenticate(env.JWT_ACCESS_SECRET));
  router.get("/", validate(orderListQuerySchema, "query"), asyncHandler(orderController.list));
  router.post("/", validate(orderCreateSchema), asyncHandler(orderController.create));
  router.get("/:id", asyncHandler(orderController.get));
  router.patch("/:id", validate(orderUpdateSchema), asyncHandler(orderController.update));
  router.delete("/:id", asyncHandler(orderController.remove));
  return router;
}
