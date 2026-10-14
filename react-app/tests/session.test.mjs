import test from "node:test";
import assert from "node:assert/strict";
import { saveSession, restoreSession, clearSession } from "../src/session.js";

const config = { clientId: "client", redirectUri: "https://example.com/" };
function storage() {
  const map = new Map();
  return { getItem: key => map.get(key) ?? null, setItem: (key, value) => map.set(key, value), removeItem: key => map.delete(key) };
}
test("same tab restores sign-in after a page reload without extending expiry", () => {
  const store = storage();
  saveSession(config, "access-token", 1000, store);
  assert.deepEqual(restoreSession(config, store, 500), { config, token: "access-token", expires: 1000 });
  assert.equal(restoreSession(config, store, 999).expires, 1000);
});
test("expired session is discarded", () => {
  const store = storage();
  saveSession(config, "access-token", 1000, store);
  assert.equal(restoreSession(config, store, 1000).token, "");
  assert.equal(store.getItem("personal-data-session"), null);
});
test("sign out prevents a reload from restoring the session", () => {
  const store = storage();
  saveSession(config, "access-token", 1000, store);
  clearSession(store);
  assert.equal(restoreSession(config, store, 500).token, "");
});
test("tokens from a different client or website are not restored", () => {
  for (const other of [{ ...config, clientId: "other" }, { ...config, redirectUri: "https://other.example/" }]) {
    const store = storage();
    saveSession(config, "access-token", 1000, store);
    assert.equal(restoreSession(other, store, 500).token, "");
  }
});
test("corrupt or blocked storage does not break the sign-in page", () => {
  const store = storage();
  store.setItem("personal-data-session", "{");
  assert.equal(restoreSession(config, store, 500).token, "");
  const blocked = { getItem() { throw Error("blocked"); }, removeItem() { throw Error("blocked"); } };
  assert.equal(restoreSession(config, blocked, 500).token, "");
});
