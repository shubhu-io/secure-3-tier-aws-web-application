const API_BASE = "";

async function request(path, options = {}) {
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };

  const token = localStorage.getItem("token");
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });

  let body = null;
  try {
    body = await res.json();
  } catch {
    // non-JSON response
  }

  if (!res.ok) {
    throw new Error(body?.error || `Request failed (${res.status})`);
  }

  return body;
}

export const api = {
  register: (email, password) =>
    request("/api/auth/register", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  login: (email, password) =>
    request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  listItems: () => request("/api/items"),

  createItem: (title, description) =>
    request("/api/items", {
      method: "POST",
      body: JSON.stringify({ title, description }),
    }),

  deleteItem: (id) => request(`/api/items/${id}`, { method: "DELETE" }),

  health: () => request("/health"),
};
