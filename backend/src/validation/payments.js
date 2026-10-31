import { z } from "zod";

const clientId = z.string().trim().min(1).max(80).optional();
const orderId = z.string().trim().min(1).max(80);

export const paymentCreateSchema = z.object({
  orderId,
  clientId,
  amount: z.number().finite().positive(),
  paymentType: z.enum(["advance", "partial", "final"]),
  method: z.enum(["cash", "bank_transfer", "mobile_wallet", "other"]),
  paidAt: z.string().datetime({ offset: true }),
  note: z.string().trim().max(500).default(""),
});

export const paymentListQuerySchema = z.object({
  orderId: orderId.optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
