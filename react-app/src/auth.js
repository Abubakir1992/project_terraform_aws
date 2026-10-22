const encode = bytes => btoa(String.fromCharCode(...bytes)).replace(/\+/g,"-").replace(/\//g,"_").replace(/=+$/,"");
export async function signIn(c) {
  if (!c.clientId) throw new Error("Deploy the Terraform-generated configuration first.");
  const verifier=encode(crypto.getRandomValues(new Uint8Array(32)));
  const state=encode(crypto.getRandomValues(new Uint8Array(32)));
  sessionStorage.setItem("moto-pkce",JSON.stringify({verifier,state}));
  const digest=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(verifier));
  location.assign(`${c.authUrl}/oauth2/authorize?${new URLSearchParams({
    client_id:c.clientId,redirect_uri:c.redirectUri,response_type:"code",scope:"openid email",
    state,code_challenge:encode(new Uint8Array(digest)),code_challenge_method:"S256"})}`);
}
export async function callback(c) {
  const p=new URLSearchParams(location.search);
  if (!p.has("code")&&!p.has("error")) return "";
  const saved=JSON.parse(sessionStorage.getItem("moto-pkce")||"null");
  sessionStorage.removeItem("moto-pkce");history.replaceState(null,"",location.pathname);
  if (!saved||saved.state!==p.get("state")||p.has("error")) throw new Error("Sign-in verification failed. Try again.");
  const response=await fetch(`${c.authUrl}/oauth2/token`,{method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},body:new URLSearchParams({
      grant_type:"authorization_code",client_id:c.clientId,redirect_uri:c.redirectUri,
      code:p.get("code"),code_verifier:saved.verifier})});
  const data=await response.json();
  if (!response.ok||!data.id_token) throw new Error("Sign-in failed.");
  return data.id_token;
}
export function claims(t) {
  try {return JSON.parse(atob(t.split(".")[1].replace(/-/g,"+").replace(/_/g,"/")));}
  catch {return {};}
}
export function signOut(c) {
  location.assign(`${c.authUrl}/logout?${new URLSearchParams({client_id:c.clientId,logout_uri:c.redirectUri})}`);
}
