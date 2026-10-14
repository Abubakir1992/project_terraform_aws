const key = "personal-data-session";

export function clearSession(storage = sessionStorage) {
  try { storage.removeItem(key); } catch { /* Storage can be disabled. */ }
}

export function saveSession(config, token, expires, storage = sessionStorage) {
  try {
    storage.setItem(key, JSON.stringify({ clientId: config.clientId, redirectUri: config.redirectUri, token, expires }));
  } catch { /* Sign-in still works in memory if storage is unavailable. */ }
}

export function restoreSession(config, storage = sessionStorage, now = Date.now()) {
  try {
    const value = JSON.parse(storage.getItem(key));
    if (value && value.clientId === config.clientId && value.redirectUri === config.redirectUri &&
        typeof value.token === "string" && value.token.length > 0 && Number.isFinite(value.expires) && value.expires > now) {
      return { config, token: value.token, expires: value.expires };
    }
  } catch { /* Corrupt or disabled storage should not prevent sign-in. */ }
  clearSession(storage);
  return { config, token: "", expires: 0 };
}

// This only controls presentation. The API verifies JWTs and enforces permissions.
export function isAdministrator(token) {
  try {
    const payload = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    const groups = JSON.parse(atob(payload))["cognito:groups"];
    return Array.isArray(groups) && groups.includes("administrators");
  } catch { return false; }
}
