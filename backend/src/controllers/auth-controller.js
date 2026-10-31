import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import User from "../models/user.js";
import { ApiError } from "../utils/api-error.js";

const passwordRounds = 12;

function issueTokens(user, env) {
  const claims = { type: "access" };
  const accessToken = jwt.sign(claims, env.JWT_ACCESS_SECRET, {
    subject: user.id,
    expiresIn: env.JWT_ACCESS_TTL,
  });
  const refreshToken = jwt.sign(
    { type: "refresh", version: user.tokenVersion },
    env.JWT_REFRESH_SECRET,
    { subject: user.id, expiresIn: env.JWT_REFRESH_TTL },
  );
  return { accessToken, refreshToken, tokenType: "Bearer" };
}

function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email };
}

export function createAuthController(env) {
  return {
    register: async (req, res) => {
      const { name, email, password } = req.body;
      const existing = await User.exists({ email: email.toLowerCase() });
      if (existing) {
        throw new ApiError(409, "EMAIL_IN_USE", "An account with this email already exists.");
      }

      const passwordHash = await bcrypt.hash(password, passwordRounds);
      let user;
      try {
        user = await User.create({ name, email, passwordHash });
      } catch (error) {
        if (error?.code === 11000) {
          throw new ApiError(409, "EMAIL_IN_USE", "An account with this email already exists.");
        }
        throw error;
      }

      res.status(201).json({
        success: true,
        data: { user: publicUser(user), ...issueTokens(user, env) },
      });
    },

    login: async (req, res) => {
      const user = await User.findOne({ email: req.body.email.toLowerCase() })
        .select("+passwordHash");
      const validPassword =
        user && (await bcrypt.compare(req.body.password, user.passwordHash));
      if (!validPassword) {
        throw new ApiError(401, "INVALID_CREDENTIALS", "Email or password is incorrect.");
      }
      res.json({
        success: true,
        data: { user: publicUser(user), ...issueTokens(user, env) },
      });
    },

    refresh: async (req, res) => {
      let claims;
      try {
        claims = jwt.verify(req.body.refreshToken, env.JWT_REFRESH_SECRET);
      } catch {
        throw new ApiError(401, "INVALID_REFRESH_TOKEN", "Your session has expired. Sign in again.");
      }
      if (
        typeof claims !== "object" ||
        claims === null ||
        claims.type !== "refresh" ||
        typeof claims.sub !== "string" ||
        typeof claims.version !== "number"
      ) {
        throw new ApiError(401, "INVALID_REFRESH_TOKEN", "The refresh token is invalid.");
      }
      const user = await User.findOneAndUpdate(
        { _id: claims.sub, tokenVersion: claims.version },
        { $inc: { tokenVersion: 1 } },
        { new: true },
      );
      if (!user || claims.version !== user.tokenVersion) {
        throw new ApiError(401, "INVALID_REFRESH_TOKEN", "This session is no longer active.");
      }
      res.json({
        success: true,
        data: { user: publicUser(user), ...issueTokens(user, env) },
      });
    },

    logout: async (req, res) => {
      await User.updateOne({ _id: req.user.id }, { $inc: { tokenVersion: 1 } });
      res.json({ success: true, data: { message: "Signed out." } });
    },

    me: (req, res) => {
      res.json({ success: true, data: { user: publicUser(req.user) } });
    },
  };
}
