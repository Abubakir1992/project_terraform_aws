import React,{useEffect,useState} from "react";
import {createRoot} from "react-dom/client";
import {signIn,callback,claims,signOut} from "./auth.js";
import People from "./People.jsx";
import "./styles/base.css";
import "./styles/admin.css";
function Admin(){
  const [config,setConfig]=useState(null),[token,setToken]=useState("");
  const [error,setError]=useState("");
  useEffect(()=>{fetch("/app-config.json",{cache:"no-store"}).then(r=>r.json()).then(async c=>{
    setConfig(c);setToken(await callback(c));
  }).catch(e=>setError(e.message));},[]);
  useEffect(()=>{
    if(!token)return;
    const timer=setTimeout(()=>setToken(""),Math.max(0,claims(token).exp*1000-Date.now()));
    return ()=>clearTimeout(timer);
  },[token]);
  const admin=(claims(token)["cognito:groups"]||[]).includes("administrators");
  return <><header><a className="brand" href="/">MOTO / HAUS</a><span>Administrator portal</span></header>
    <main className="admin"><p className="eyebrow">PRIVATE WORKSPACE</p><h1>Customer enquiries.</h1>
    <p>Personal information is available only to authorized administrators.</p>
    {error&&<p role="alert">{error}</p>}
    {!token&&<button className="button" disabled={!config} onClick={()=>signIn(config).catch(e=>setError(e.message))}>Administrator sign in ↗</button>}
    {token&&!admin&&<p role="alert">Your account does not have administrator access.</p>}
    {token&&<button onClick={()=>{setToken("");signOut(config);}}>Sign out</button>}
    {token&&admin&&<People config={config} token={token}/>}</main></>;
}
createRoot(document.getElementById("root")).render(<Admin/>);
