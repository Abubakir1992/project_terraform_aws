import test from "node:test";
import assert from "node:assert/strict";
import { claims, callback } from "../src/auth.js";
test("malformed display token has no claims", () => {
  assert.deepEqual(claims("not-a-token"), {});
});
test("display claim parsing does not grant API access", () => {
  const payload = btoa(JSON.stringify({"cognito:groups":["administrators"]}));
  assert.deepEqual(claims(`header.${payload}.invalid`)["cognito:groups"],["administrators"]);
});
test("OAuth callback rejects wrong state before token exchange", async () => {
  globalThis.location = {search:"?code=test&state=wrong",pathname:"/admin.html"};
  globalThis.history = {replaceState(){}};
  globalThis.sessionStorage = {getItem:()=>JSON.stringify({state:"expected",verifier:"secret"}),removeItem(){}};
  await assert.rejects(callback({}),/verification failed/);
});
