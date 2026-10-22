import React,{useEffect,useState} from "react";
export default function People({config,token}){
  const [people,setPeople]=useState([]),[cursor,setCursor]=useState("");
  const [error,setError]=useState(""),[busy,setBusy]=useState(false);
  async function load(next=""){
    setBusy(true);setError("");
    try{
      const response=await fetch(`${config.apiUrl}/people?${new URLSearchParams({cursor:next})}`,{
        headers:{Authorization:token},cache:"no-store"});
      const data=await response.json();
      if(!response.ok)throw new Error(data.message||"Access denied or session expired.");
      setPeople(old=>next?[...old,...data.people]:data.people);setCursor(data.next_cursor);
    }catch(e){setError(e.message);}finally{setBusy(false);}
  }
  useEffect(()=>{load();},[token]);
  return <section><button disabled={busy} onClick={()=>load()}>Refresh enquiries</button>
    {error&&<p role="alert">{error}</p>}{busy&&<p role="status">Loading…</p>}
    <div className="table-scroll"><table><caption>Saved callback requests</caption><thead><tr>
      {["Name","Phone","Email","Interest","Received (UTC)"].map(h=><th key={h}>{h}</th>)}
    </tr></thead><tbody>{people.map(p=><tr key={p.request_id}>
      <td>{p.name}</td><td>{p.phone}</td><td>{p.email}</td><td>{p.interest}</td><td>{p.created_at}</td>
    </tr>)}</tbody></table></div>
    {!busy&&!error&&!people.length&&<p>No enquiries yet.</p>}
    {cursor&&<button disabled={busy} onClick={()=>load(cursor)}>Load more</button>}</section>;
}
