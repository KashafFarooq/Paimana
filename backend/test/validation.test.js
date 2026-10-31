import test from "node:test";
import assert from "node:assert/strict";
import { readEnv } from "../src/config/env.js";
import { registerSchema } from "../src/validation/auth.js";
import { customerCreateSchema } from "../src/validation/customers.js";
import { orderCreateSchema, orderUpdateSchema } from "../src/validation/orders.js";
import { aiActions, aiRequestSchema } from "../src/validation/ai.js";
import User from "../src/models/user.js";
import Customer from "../src/models/customer.js";
import Order from "../src/models/order.js";
import Payment from "../src/models/payment.js";
import {
  paymentCreateSchema,
  paymentListQuerySchema,
} from "../src/validation/payments.js";

test("backend rejects missing or weak JWT secrets at startup", () => {
  assert.throws(() => readEnv({}), /JWT_ACCESS_SECRET/);
  assert.throws(
    () =>
      readEnv({
        MONGODB_URI: "mongodb://localhost/test",
        JWT_ACCESS_SECRET: "short",
        JWT_REFRESH_SECRET: "also-short",
      }),
    /32 characters/,
  );
});

test("registration validation normalizes email and enforces password strength", () => {
  const parsed = registerSchema.parse({
    name: " Ayesha Khan ",
    email: "AYESHA@example.com ",
    password: "a-secure-password",
  });
  assert.equal(parsed.name, "Ayesha Khan");
  assert.equal(parsed.email, "ayesha@example.com");
  assert.equal(
    registerSchema.safeParse({
      name: "Ayesha",
      email: "ayesha@example.com",
      password: "short",
    }).success,
    false,
  );
});

test("customer validation applies defaults and rejects overlong notes", () => {
  assert.deepEqual(
    customerCreateSchema.parse({ name: "Ayesha" }),
    { name: "Ayesha", phone: "", note: "" },
  );
  assert.equal(
    customerCreateSchema.safeParse({ name: "Ayesha", note: "x".repeat(2001) })
      .success,
    false,
  );
});

test("order validation checks payment totals and partial updates", () => {
  const order = {
    customerName: "Ayesha",
    garment: "Suit",
    dueDate: "2026-11-12T00:00:00.000Z",
    totalAmount: 18000,
    paidAmount: 5000,
  };
  assert.equal(orderCreateSchema.safeParse(order).success, true);
  assert.equal(
    orderCreateSchema.safeParse({ ...order, paidAmount: 19000 }).success,
    false,
  );
  assert.equal(orderUpdateSchema.safeParse({ status: "ready" }).success, true);
  assert.equal(orderUpdateSchema.safeParse({}).success, false);
});

test("payment validation requires valid amounts and supported tender types", () => {
  const payment = {
    orderId: "local-order",
    clientId: "local-payment",
    amount: 5000,
    paymentType: "advance",
    method: "cash",
    paidAt: "2026-10-28T08:00:00.000Z",
  };
  assert.deepEqual(paymentCreateSchema.parse(payment), {
    ...payment,
    note: "",
  });
  assert.equal(
    paymentCreateSchema.safeParse({ ...payment, amount: 0 }).success,
    false,
  );
  assert.equal(
    paymentCreateSchema.safeParse({ ...payment, method: "crypto" }).success,
    false,
  );
  assert.deepEqual(paymentListQuerySchema.parse({ page: "2" }), {
    page: 2,
    limit: 50,
  });
});

test("AI request validation bounds prompt size and publishes supported routes", () => {
  assert.equal(aiActions.includes("order-extraction"), true);
  assert.equal(aiActions.includes("measurement-validation"), true);
  assert.equal(aiRequestSchema.safeParse({ text: "extract an order" }).success, true);
  assert.equal(
    aiRequestSchema.safeParse({ text: "x".repeat(12001) }).success,
    false,
  );
});

test("Mongo response JSON includes client IDs but never account secrets", () => {
  const user = new User({
    name: "Ayesha",
    email: "ayesha@example.com",
    passwordHash: "never-return-this",
    tokenVersion: 4,
  }).toJSON();
  assert.equal(typeof user.id, "string");
  assert.equal("passwordHash" in user, false);
  assert.equal("tokenVersion" in user, false);

  const customer = new Customer({
    ownerId: "68f000000000000000000001",
    clientId: "local-customer",
    name: "Ayesha",
  }).toJSON();
  assert.equal(customer.clientId, "local-customer");
  assert.equal(typeof customer.id, "string");
  assert.equal("ownerId" in customer, false);

  const order = new Order({
    ownerId: "68f000000000000000000001",
    clientId: "local-order",
    customerName: "Ayesha",
    garment: "Suit",
    dueDate: "2026-11-12T00:00:00.000Z",
    totalAmount: 18000,
  }).toJSON();
  assert.equal(order.clientId, "local-order");
  assert.equal(typeof order.id, "string");
  assert.equal("ownerId" in order, false);

  const payment = new Payment({
    ownerId: "68f000000000000000000001",
    orderId: "68f000000000000000000003",
    clientId: "local-payment",
    amount: 5000,
    paymentType: "advance",
    method: "cash",
    paidAt: "2026-10-28T08:00:00.000Z",
  }).toJSON();
  assert.equal(payment.clientId, "local-payment");
  assert.equal(typeof payment.id, "string");
  assert.equal("ownerId" in payment, false);
});
