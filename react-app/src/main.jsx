import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { clearSession, saveSession, restoreSession, isAdministrator } from "./session.js";

const empty = { full_name: "", email: "", phone: "", address: "" };
const base64url = bytes => btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const random = () => base64url(crypto.getRandomValues(new Uint8Array(32)));

async function initialize() {
  if (location.protocol !== "https:") throw new Error("Open the configured HTTPS website to enter personal information.");
  const response = await fetch("/app-config.json", { cache: "no-store" });
  if (!response.ok) throw new Error("Configuration unavailable. Apply the updated Terraform first.");
  const config = await response.json();
  if (location.origin + "/" !== config.redirectUri) throw new Error("Open " + config.redirectUri + " to use this form.");
  const query = new URLSearchParams(location.search);
  if (query.has("error")) {
    history.replaceState({}, "", "/");
    sessionStorage.removeItem("oauth");
    throw new Error("Sign-in cancelled or failed. Reload to try again.");
  }
  if (query.has("code")) {
    const saved = sessionStorage.getItem("oauth");
    sessionStorage.removeItem("oauth");
    history.replaceState({}, "", "/");
    const transaction = saved ? JSON.parse(saved) : null;
    if (!transaction || transaction.state !== query.get("state") || Date.now() - transaction.created > 600000) {
      throw new Error("Sign-in expired. Reload and sign in again.");
    }
    const tokens = await fetch(config.authUrl + "/oauth2/token", {
      method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "authorization_code", client_id: config.clientId,
        code: query.get("code"), redirect_uri: config.redirectUri, code_verifier: transaction.verifier })
    });
    if (!tokens.ok) throw new Error("Could not finish sign-in. Reload to try again.");
    const data = await tokens.json();
    const expires = Date.now() + data.expires_in * 1000;
    saveSession(config, data.access_token, expires);
    return { config, token: data.access_token, expires };
  }
  return restoreSession(config);
}

function App({ session: initialSession }) {
  const [session, setSession] = useState(initialSession);
  const [values, setValues] = useState(empty);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const [instance, setInstance] = useState("");
  const [people, setPeople] = useState([]);
  const [nextCursor, setNextCursor] = useState("");
  const [loadingPeople, setLoadingPeople] = useState(false);
  const [listError, setListError] = useState("");
  const administrator = isAdministrator(session.token);
  function expireSession() {
    clearSession();
    setSession(previous => ({ ...previous, token: "", expires: 0 }));
    setValues(empty);
    setPeople([]);
    setNextCursor("");
    setMessage("Your session expired. Sign in again.");
  }
  useEffect(() => {
    if (!session.token) return;
    const timer = setTimeout(expireSession, Math.max(0, session.expires - Date.now()));
    return () => clearTimeout(timer);
  }, [session.token, session.expires]);

  async function loadPeople(cursor = "", signal) {
    if (!session.token) return;
    setLoadingPeople(true);
    setListError("");
    try {
      const path = administrator ? "/people" + (cursor ? "?cursor=" + encodeURIComponent(cursor) : "") : "/personal-data";
      const response = await fetch(session.config.apiUrl + path, {
        headers: { Authorization: "Bearer " + session.token }, cache: "no-store", signal
      });
      const data = await response.json();
      if (signal?.aborted) return;
      if (response.status === 401) { expireSession(); return; }
      if (!response.ok) throw new Error(data.message || "Could not load saved details.");
      setPeople(previous => cursor ? [...previous, ...data.people] : data.people);
      setNextCursor(data.next_cursor || "");
    } catch (error) {
      if (error.name !== "AbortError") setListError(error.message);
    } finally {
      if (!signal?.aborted) setLoadingPeople(false);
    }
  }
  useEffect(() => {
    const controller = new AbortController();
    if (session.token) loadPeople("", controller.signal);
    return () => controller.abort();
  }, [session.token]);
  useEffect(() => {
    fetch("/instance.json", { cache: "no-store" }).then(r => r.ok ? r.json() : null)
      .then(data => setInstance(data?.instanceId || "")).catch(() => {});
  }, []);

  async function signIn() {
    clearSession();
    setBusy(true);
    try {
      const verifier = random();
      const state = random();
      const challenge = base64url(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier))));
      sessionStorage.setItem("oauth", JSON.stringify({ state, verifier, created: Date.now() }));
      location.assign(session.config.authUrl + "/oauth2/authorize?" + new URLSearchParams({
        response_type: "code", client_id: session.config.clientId, redirect_uri: session.config.redirectUri,
        scope: "openid email", state, code_challenge: challenge, code_challenge_method: "S256"
      }));
    } catch {
      setMessage("Could not start sign-in. Enable browser session storage and try again.");
      setBusy(false);
    }
  }

  async function save(event) {
    event.preventDefault();
    if (Date.now() >= session.expires) {
      expireSession();
      return;
    }
    setBusy(true);
    setMessage("");
    try {
      const response = await fetch(session.config.apiUrl + "/personal-data", {
        method: "PUT", headers: { "Content-Type": "application/json", Authorization: "Bearer " + session.token },
        body: JSON.stringify(values)
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(response.status === 401 || response.status === 403
        ? "Please sign out and sign in again." : data.message || "Could not save. Please try again.");
      setValues(empty);
      setMessage(data.message);
      await loadPeople();
    } catch (error) {
      setMessage(error.message || "Could not connect. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  function signOut() {
    clearSession();
    sessionStorage.removeItem("oauth");
    setSession(previous => ({ ...previous, token: "", expires: 0 }));
    setValues(empty);
    setPeople([]);
    location.assign(session.config.authUrl + "/logout?" + new URLSearchParams({
      client_id: session.config.clientId, logout_uri: session.config.redirectUri
    }));
  }

  return <main style={{ fontFamily: "Arial, sans-serif", maxWidth: 1000, margin: "48px auto", padding: 24, color: "#0f172a" }}>
    <h1>Your personal details</h1>
    <p>Save your name, email, phone number, and address.</p>
    {session.token ? <>
      <button onClick={signOut} disabled={busy}>Sign out</button>
      <form onSubmit={save} style={{ display: "grid", gap: 18, marginTop: 24 }}>
        <fieldset disabled={busy} style={{ border: 0, padding: 0, display: "grid", gap: 18 }}>
          {[["full_name", "Full name", "text", 120, "name"], ["email", "Email", "email", 254, "email"],
            ["phone", "Phone (optional)", "tel", 30, "tel"], ["address", "Address (optional)", "text", 500, "street-address"]].map(([key, label, type, max, auto]) =>
            <label key={key} style={{ display: "grid", gap: 6 }}>{label}
              <input name={key} type={type} autoComplete={auto} maxLength={max} value={values[key]}
                required={key === "full_name" || key === "email"} style={{ padding: 12, fontSize: 16 }}
                onChange={event => setValues(previous => ({ ...previous, [key]: event.target.value }))} />
            </label>)}
          <button type="submit" style={{ padding: 14, fontSize: 16 }}>{busy ? "Saving..." : "Save details"}</button>
        </fieldset>
      </form>
      <p>Saving again replaces your previous details.</p>
      <section aria-label="Saved people">
        <h2>{administrator ? "All saved people" : "Your saved details"}</h2>
        <button disabled={loadingPeople} onClick={() => loadPeople()}>Refresh saved details</button>
        {loadingPeople && <p role="status">Loading saved details...</p>}
        {listError && <p role="alert">{listError}</p>}
        {!loadingPeople && !listError && people.length === 0 && <p>No saved details yet.</p>}
        {people.length > 0 && <div style={{ overflowX: "auto", marginTop: 16 }}>
          <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left" }}>
            <caption style={{ textAlign: "left", marginBottom: 8 }}>{people.length} saved {people.length === 1 ? "person" : "people"}{nextCursor ? " loaded" : ""}</caption>
            <thead><tr>{["Full name", "Email", "Phone", "Address", "Last updated"].map(label =>
              <th key={label} scope="col" style={{ padding: 10, borderBottom: "2px solid #cbd5e1" }}>{label}</th>)}</tr></thead>
            <tbody>{people.map(person => <tr key={person.owner_sub}>
              {[person.full_name, person.email, person.phone || "—", person.address || "—", person.updated_at].map((value, index) =>
                <td key={index} style={{ padding: 10, borderBottom: "1px solid #cbd5e1", overflowWrap: "anywhere" }}>{value}</td>)}
            </tr>)}</tbody>
          </table>
        </div>}
        {nextCursor && <button disabled={loadingPeople} onClick={() => loadPeople(nextCursor)}>Load more people</button>}
      </section>
    </> : <><p>Sign in with the account invitation sent by your administrator.</p>
      <button onClick={signIn} disabled={busy}>{busy ? "Opening sign-in..." : "Sign in"}</button></>}
    <p role="status" aria-live="polite">{message}</p>
    {instance && <small>Served by EC2 instance: {instance}</small>}
  </main>;
}

initialize().then(session => createRoot(document.getElementById("root")).render(<App session={session} />))
  .catch(error => { document.getElementById("root").textContent = error.message; });
