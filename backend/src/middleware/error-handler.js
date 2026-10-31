import mongoose from "mongoose";
import { ApiError } from "../utils/api-error.js";

export function notFound(req, res) {
  res.status(404).json({
    success: false,
    error: { code: "NOT_FOUND", message: "The requested resource was not found." },
  });
}

export function errorHandler(error, req, res, next) {
  if (res.headersSent) {
    next(error);
    return;
  }
  if (error?.type === "entity.parse.failed") {
    res.status(400).json({
      success: false,
      error: { code: "INVALID_JSON", message: "Request body must be valid JSON." },
    });
    return;
  }
  if (error?.type === "entity.too.large") {
    res.status(413).json({
      success: false,
      error: { code: "REQUEST_TOO_LARGE", message: "Request body exceeds the allowed size." },
    });
    return;
  }
  if (error instanceof mongoose.Error.ValidationError) {
    res.status(400).json({
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "One or more fields are invalid.",
        details: Object.values(error.errors).map(({ path, message }) => ({
          field: path,
          message,
        })),
      },
    });
    return;
  }
  if (error instanceof mongoose.Error.CastError) {
    res.status(400).json({
      success: false,
      error: { code: "INVALID_ID", message: "The supplied identifier is invalid." },
    });
    return;
  }
  if (error instanceof ApiError) {
    res.status(error.status).json({
      success: false,
      error: {
        code: error.code,
        message: error.message,
        ...(error.details ? { details: error.details } : {}),
      },
    });
    return;
  }

  console.error("Unhandled API error", {
    method: req.method,
    path: req.originalUrl,
    error,
  });
  res.status(500).json({
    success: false,
    error: { code: "INTERNAL_ERROR", message: "An unexpected server error occurred." },
  });
}
