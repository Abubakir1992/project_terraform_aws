import React, { useEffect, useRef } from "react";
export default function Success({ close }) {
  const dialog = useRef(null);
  useEffect(() => { dialog.current.showModal(); }, []);
  return <dialog ref={dialog} onCancel={e => { e.preventDefault(); close(); }} aria-labelledby="success-title">
    <div className="success-icon" aria-hidden="true">✓</div><p className="eyebrow">YOU’RE ON OUR LIST</p>
    <h2 id="success-title">Our agent will call you.</h2><p>Your enquiry has been received.<br />We look forward to talking about your next ride.</p>
    <button className="button" autoFocus onClick={close}>Back to the collection ↗</button>
  </dialog>;
}
