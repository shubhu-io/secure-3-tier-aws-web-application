import { useEffect, useState } from "react";
import { api } from "../api.js";

export default function ItemsView({ onLogout }) {
  const [items, setItems] = useState([]);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [error, setError] = useState("");
  const [health, setHealth] = useState(null);

  useEffect(() => {
    api.listItems().then(({ items }) => setItems(items)).catch((e) => setError(e.message));
    api.health().then(setHealth).catch(() => {});
  }, []);

  async function addItem(e) {
    e.preventDefault();
    setError("");
    try {
      const { item } = await api.createItem(title, description);
      setItems((prev) => [item, ...prev]);
      setTitle("");
      setDescription("");
    } catch (err) {
      setError(err.message);
    }
  }

  async function removeItem(id) {
    try {
      await api.deleteItem(id);
      setItems((prev) => prev.filter((i) => i.id !== id));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="card">
      <header className="row-between">
        <h1>Your items</h1>
        <button type="button" className="link" onClick={onLogout}>
          Log out ({localStorage.getItem("userEmail") || ""})
        </button>
      </header>

      <p className="muted">
        Backend health: <strong>{health ? `${health.status} · db ${health.db}` : "checking..."}</strong>
      </p>

      <form onSubmit={addItem} className="add-form">
        <input
          placeholder="Title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <input
          placeholder="Description (optional)"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
        <button type="submit">Add</button>
      </form>

      {error && <p className="error">{error}</p>}

      <ul className="items">
        {items.map((item) => (
          <li key={item.id} className="row-between">
            <div>
              <strong>{item.title}</strong>
              {item.description && <p className="muted">{item.description}</p>}
            </div>
            <button type="button" className="link danger" onClick={() => removeItem(item.id)}>
              Delete
            </button>
          </li>
        ))}
        {items.length === 0 && <li className="muted">No items yet — add your first one.</li>}
      </ul>
    </div>
  );
}
