import pg from "pg";
import config from "./config.js";

const { Pool } = pg;

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  max: config.db.max,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000,
});

export default pool;
