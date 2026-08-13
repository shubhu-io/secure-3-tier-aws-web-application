import dotenv from "dotenv";

dotenv.config();

const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  nodeEnv: process.env.NODE_ENV || "development",
  db: {
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5432", 10),
    name: process.env.DB_NAME || "appdb",
    user: process.env.DB_USER || "app_user",
    password: process.env.DB_PASSWORD || "",
    max: parseInt(process.env.DB_POOL_MAX || "10", 10),
  },
  jwt: {
    secret: process.env.JWT_SECRET || "",
    expiresIn: process.env.JWT_EXPIRES_IN || "8h",
  },
};

if (config.nodeEnv === "production" && !config.jwt.secret) {
  throw new Error("JWT_SECRET must be set in production");
}

export default config;
