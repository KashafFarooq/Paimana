import test from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/app.js";

const env = {
  NODE_ENV: "test",
  PORT: 4000,
  MONGODB_URI: "mongodb://127.0.0.1:27017/paimana-test",
  JWT_ACCESS_SECRET: "a".repeat(40),
  JWT_REFRESH_SECRET: "b".repeat(40),
  JWT_ACCESS_TTL: "15m",
  JWT_REFRESH_TTL: "30d",
  CLIENT_ORIGIN: "*",
  GEMINI_API_KEY: "",
  GEMINI_MODEL: "gemini-2.5-flash",
};

test("HTTP API exposes health, protects account data, and uses error envelopes", async (t) => {
  const server = createApp(env).listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  t.after(() => new Promise((resolve, reject) => {
    server.close((error) => error ? reject(error) : resolve());
  }));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const healthResponse = await fetch(`${baseUrl}/health`);
  assert.equal(healthResponse.status, 200);
  assert.deepEqual(await healthResponse.json(), {
    success: true,
    data: { status: "ok" },
  });

  const protectedResponse = await fetch(`${baseUrl}/api/v1/customers`);
  assert.equal(protectedResponse.status, 401);
  assert.equal(
    (await protectedResponse.json()).error.code,
    "AUTH_REQUIRED",
  );
  const protectedPaymentsResponse = await fetch(`${baseUrl}/api/v1/payments`);
  assert.equal(protectedPaymentsResponse.status, 401);
  assert.equal(
    (await protectedPaymentsResponse.json()).error.code,
    "AUTH_REQUIRED",
  );

  const validationResponse = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email: "not-an-email", password: "" }),
  });
  assert.equal(validationResponse.status, 400);
  assert.equal(
    (await validationResponse.json()).error.code,
    "VALIDATION_ERROR",
  );

  const invalidJsonResponse = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: "{invalid",
  });
  assert.equal(invalidJsonResponse.status, 400);
  assert.equal(
    (await invalidJsonResponse.json()).error.code,
    "INVALID_JSON",
  );

  const missingResponse = await fetch(`${baseUrl}/api/v1/unknown`);
  assert.equal(missingResponse.status, 404);
  assert.equal((await missingResponse.json()).error.code, "NOT_FOUND");
});
