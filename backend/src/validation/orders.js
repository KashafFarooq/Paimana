import { z } from "zod";

const clientId = z.string().trim().min(1).max(80).optional();
const customerId = z.string().regex(/^[a-f\d]{24}$/i).nullable().optional();
const amount = z.number().finite().min(0);

export const orderCreateSchema = z
  .object({
    customerId,
    customerName: z.string().trim().min(1).max(120),
    garment: z.string().trim().min(1).max(160),
    dueDate: z.string().datetime({ offset: true }),
    totalAmount: z.number().finite().positive(),
    paidAmount: amount.default(0),
    status: z
      .enum(["pending", "cutting", "stitching", "ready", "delivered", "cancelled"])
      .default("pending"),
    note: z.string().trim().max(2000).default(""),
    clientId,
  })
  .refine((order) => order.paidAmount <= order.totalAmount, {
    path: ["paidAmount"],
    message: "Paid amount cannot exceed the order total.",
  });

export const orderUpdateSchema = z
  .object({
    customerId,
    customerName: z.string().trim().min(1).max(120).optional(),
    garment: z.string().trim().min(1).max(160).optional(),
    dueDate: z.string().datetime({ offset: true }).optional(),
    totalAmount: z.number().finite().positive().optional(),
    paidAmount: amount.optional(),
    status: z
      .enum(["pending", "cutting", "stitching", "ready", "delivered", "cancelled"])
      .optional(),
    note: z.string().trim().max(2000).optional(),
  })
  .refine((order) => Object.keys(order).length > 0, {
    message: "Provide at least one field to update.",
  })
  .refine(
    (order) =>
      order.paidAmount === undefined ||
      order.totalAmount === undefined ||
      order.paidAmount <= order.totalAmount,
    {
      path: ["paidAmount"],
      message: "Paid amount cannot exceed the order total.",
    },
  );

export const orderListQuerySchema = z.object({
  status: z
    .enum(["pending", "cutting", "stitching", "ready", "delivered", "cancelled"])
    .optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  updatedSince: z.string().datetime({ offset: true }).optional(),
});
