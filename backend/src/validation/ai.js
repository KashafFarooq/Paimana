import { z } from "zod";

export const aiRequestSchema = z.object({
  text: z.string().trim().min(3).max(12000),
  context: z.record(z.string(), z.unknown()).optional(),
});

export const aiActions = [
  "order-extraction",
  "measurement-extraction",
  "design-suggestions",
  "fabric-calculator",
  "price-estimator",
  "delivery-prediction",
  "whatsapp-message",
  "business-dashboard",
  "measurement-validation",
  "repeat-order",
  "voice-order",
];
