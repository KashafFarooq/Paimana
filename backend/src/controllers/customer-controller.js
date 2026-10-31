import Customer from "../models/customer.js";
import { ApiError } from "../utils/api-error.js";

function findOwnedById(ownerId, id) {
  const identifier = /^[a-f\d]{24}$/i.test(id) ? { _id: id } : { clientId: id };
  return { ownerId, ...identifier };
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export const customerController = {
  list: async (req, res) => {
    const { q, page, limit, updatedSince } = req.validatedQuery;
    const filter = { ownerId: req.user.id };
    if (q) {
      const term = new RegExp(escapeRegex(q), "i");
      filter.$or = [{ name: term }, { phone: term }];
    }
    if (updatedSince) filter.updatedAt = { $gte: new Date(updatedSince) };

    const [items, total] = await Promise.all([
      Customer.find(filter)
        .sort({ updatedAt: -1, _id: 1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Customer.countDocuments(filter),
    ]);
    res.json({
      success: true,
      data: { items, total, page, limit },
    });
  },

  create: async (req, res) => {
    const { clientId, ...fields } = req.body;
    if (clientId) {
      const item = await Customer.findOneAndUpdate(
        { ownerId: req.user.id, clientId },
        {
          $set: {
            ...fields,
            clientId,
            updatedFromClientAt: new Date(),
          },
        },
        { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
      );
      res.status(201).json({ success: true, data: { customer: item } });
      return;
    }

    const item = await Customer.create({ ...fields, ownerId: req.user.id });
    res.status(201).json({ success: true, data: { customer: item } });
  },

  get: async (req, res) => {
    const item = await Customer.findOne(findOwnedById(req.user.id, req.params.id));
    if (!item) throw new ApiError(404, "CUSTOMER_NOT_FOUND", "Customer not found.");
    res.json({ success: true, data: { customer: item } });
  },

  update: async (req, res) => {
    const item = await Customer.findOneAndUpdate(
      findOwnedById(req.user.id, req.params.id),
      { $set: { ...req.body, updatedFromClientAt: new Date() } },
      { new: true, runValidators: true },
    );
    if (!item) throw new ApiError(404, "CUSTOMER_NOT_FOUND", "Customer not found.");
    res.json({ success: true, data: { customer: item } });
  },

  remove: async (req, res) => {
    const item = await Customer.findOneAndDelete({
      ...findOwnedById(req.user.id, req.params.id),
    });
    if (!item) throw new ApiError(404, "CUSTOMER_NOT_FOUND", "Customer not found.");
    res.json({ success: true, data: { id: item.id } });
  },
};
