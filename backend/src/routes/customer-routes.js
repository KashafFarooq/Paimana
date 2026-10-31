import { Router } from "express";
import { customerController } from "../controllers/customer-controller.js";
import { authenticate } from "../middleware/authenticate.js";
import { validate } from "../middleware/validate.js";
import {
  customerCreateSchema,
  customerUpdateSchema,
  listQuerySchema,
} from "../validation/customers.js";
import { asyncHandler } from "../utils/async-handler.js";

export function createCustomerRouter(env) {
  const router = Router();
  router.use(authenticate(env.JWT_ACCESS_SECRET));
  router.get("/", validate(listQuerySchema, "query"), asyncHandler(customerController.list));
  router.post("/", validate(customerCreateSchema), asyncHandler(customerController.create));
  router.get("/:id", asyncHandler(customerController.get));
  router.patch("/:id", validate(customerUpdateSchema), asyncHandler(customerController.update));
  router.delete("/:id", asyncHandler(customerController.remove));
  return router;
}
