import { z } from "zod";

const clientId = z.string().trim().min(1).max(80).optional();

export const customerCreateSchema = z.object({
  name: z.string().trim().min(1).max(120),
  phone: z.string().trim().max(32).default(""),
  note: z.string().trim().max(2000).default(""),
  clientId,
});

export const customerUpdateSchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    phone: z.string().trim().max(32).optional(),
    note: z.string().trim().max(2000).optional(),
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: "Provide at least one field to update.",
  });

export const listQuerySchema = z.object({
  q: z.string().trim().max(120).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  updatedSince: z.string().datetime({ offset: true }).optional(),
});
