import { useState } from "react";
import AuthView from "./components/AuthView.jsx";
import ItemsView from "./components/ItemsView.jsx";

export default function App() {
  const [authed, setAuthed] = useState(Boolean(localStorage.getItem("token")));

  if (!authed) return <AuthView onAuthed={() => setAuthed(true)} />;

  return (
    <ItemsView
      onLogout={() => {
        localStorage.removeItem("token");
        localStorage.removeItem("userEmail");
        setAuthed(false);
      }}
    />
  );
}
