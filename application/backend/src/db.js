import mysql from "mysql2/promise";
import config from "./config.js";

const pool = mysql.createPool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  connectionLimit: config.db.max,
  connectTimeout: 5000,
});

export default pool;
