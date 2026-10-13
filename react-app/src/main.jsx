import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function App() {
  const [instanceId, setInstanceId] = useState("Loading...");
  const [error, setError] = useState("");

  useEffect(() => {
    async function loadInstance() {
      try {
        const response = await fetch("/instance.json", {
          cache: "no-store"
        });

        if (!response.ok) {
          throw new Error("Could not load EC2 instance information.");
        }

        const data = await response.json();
        setInstanceId(data.instanceId);
      } catch (err) {
        setError(err.message);
      }
    }

    loadInstance();
  }, []);

  return (
    <main
      style={{
        fontFamily: "Arial, sans-serif",
        maxWidth: 720,
        margin: "80px auto",
        padding: 32,
        backgroundColor: "#f1f5f9",
        borderRadius: 16,
        color: "#0f172a"
      }}
    >
      <h1>React deployed with GitHub Actions</h1>

      <p>This application is hosted on AWS EC2 behind an ALB.</p>

      <h2>EC2 instance serving the instance information</h2>

      {error ? (
        <p style={{ color: "#b91c1c" }}>{error}</p>
      ) : (
        <code>{instanceId}</code>
      )}

      <p>Change this text, push to main, and watch the deployment run.</p>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);