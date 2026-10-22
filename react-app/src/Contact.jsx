import React, { useRef, useState } from "react";
import { categories } from "./bikes.js";
import Success from "./Success.jsx";
export default function Contact({ interest, setInterest }) {
  const [busy, setBusy] = useState(false), [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const requestId = useRef("");
  const submitButton = useRef(null);
  async function submit(event) {
    event.preventDefault();
    if (busy) return;
    setBusy(true); setError("");
    requestId.current ||= crypto.randomUUID();
    const form = event.currentTarget, data = new FormData(form);
    try {
      const config = await fetch("/app-config.json", { cache: "no-store" }).then(r => r.json());
      const response = await fetch(`${config.apiUrl}/contact`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: data.get("name"), phone: data.get("phone"),
          email: data.get("email"), interest, consent: data.get("consent") === "on",
          requestId: requestId.current })
      });
      const result = await response.json().catch(() => ({ message: "The service is unavailable. Please try again later." }));
      if (!response.ok) throw new Error(result.message || "Please try again.");
      setSuccess(true); form.reset(); requestId.current = "";
    } catch (err) { setError(err.message || "Connection failed. Please try again."); }
    finally { setBusy(false); }
  }
  return <section className="contact" id="contact"><div className="contact-copy">
    <p className="eyebrow">YOUR NEXT RIDE STARTS WITH A CONVERSATION</p>
    <h2>Let’s find<br />your next ride.</h2><p>No pressure. Just people who love motorcycles.<br />Leave your details and our agent will call you.</p>
    <p className="privacy-note">Your contact details are available only to our authorized administrators.</p></div>
    <form onSubmit={submit}><label>Your name<input name="name" autoComplete="name" maxLength={120} required placeholder="Full name" /></label>
      <div className="form-row"><label>Phone number<input name="phone" type="tel" autoComplete="tel" required maxLength={30}
        minLength={7} placeholder="+1 555 000 0000" /></label>
        <label>Email address<input name="email" type="email" autoComplete="email" maxLength={254} required placeholder="you@example.com" /></label></div>
      <label>What moves you?<select value={interest} onChange={e => setInterest(e.target.value)}>{categories.map(c => <option key={c}>{c}</option>)}</select></label>
      <label className="consent"><input name="consent" type="checkbox" required />I agree to be contacted about my motorcycle enquiry.</label>
      {error && <p role="alert" className="error">{error}</p>}
      <button className="button" ref={submitButton} disabled={busy}>{busy ? "Sending…" : "Request a callback"}<span>↗</span></button>
      <small>We use these details to respond to your enquiry.</small></form>
    {success && <Success close={() => { setSuccess(false); submitButton.current?.focus(); }} />}
  </section>;
}
