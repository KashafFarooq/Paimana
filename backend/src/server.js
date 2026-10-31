import "dotenv/config";
import { createApp } from "./app.js";
import { connectDatabase } from "./config/database.js";
import { readEnv } from "./config/env.js";

const env = readEnv();
await connectDatabase(env.MONGODB_URI);
console.info("Connected to MongoDB.");

const server = createApp(env).listen(env.PORT, "0.0.0.0", () => {
  console.info(`Paimana API listening on port ${env.PORT}.`);
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    server.close(async (error) => {
      if (error) {
        console.error("HTTP server shutdown failed.", error);
        process.exitCode = 1;
      }
      const mongoose = await import("mongoose");
      await mongoose.default.disconnect();
    });
  });
}
