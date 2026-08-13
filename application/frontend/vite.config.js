import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    proxy: {
      // In dev, /api and /health are forwarded to the backend on :3000
      "/api": "http://localhost:3000",
      "/health": "http://localhost:3000",
    },
  },
});
