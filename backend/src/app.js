import cors from "cors";
import express from "express";
import helmet from "helmet";
import { createAiRouter } from "./routes/ai-routes.js";
import { createAuthRouter } from "./routes/auth-routes.js";
import { createCustomerRouter } from "./routes/customer-routes.js";
import { createOrderRouter } from "./routes/order-routes.js";
import { createPaymentRouter } from "./routes/payment-routes.js";
import { errorHandler, notFound } from "./middleware/error-handler.js";

export function createApp(env) {
  const app = express();
  const origins = env.CLIENT_ORIGIN === "*"
    ? true
    : env.CLIENT_ORIGIN.split(",").map((origin) => origin.trim());

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(cors({ origin: origins }));
  app.use(express.json({ limit: "64kb" }));
  app.get("/health", (req, res) => {
    res.json({ success: true, data: { status: "ok" } });
  });

  const api = express.Router();
  api.use("/auth", createAuthRouter(env));
  api.use("/customers", createCustomerRouter(env));
  api.use("/orders", createOrderRouter(env));
  api.use("/payments", createPaymentRouter(env));
  api.use("/ai", createAiRouter(env));
  app.use("/api/v1", api);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
