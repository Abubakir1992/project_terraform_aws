import React, { useState } from "react";
import { bikes, categories } from "./bikes.js";
export default function Catalogue({ enquire }) {
  const [filter, setFilter] = useState("All motorcycles");
  return <section className="collection" id="collection">
    <div className="section-top"><div><p className="eyebrow">FIND YOUR KIND OF FREEDOM</p>
      <h2>Different machines.<br />Same obsession.</h2></div><p>Three riding worlds. One open road.<br />Start with what speaks to you.</p></div>
    <div className="filters" aria-label="Motorcycle category">{categories.map(category =>
      <button key={category} aria-pressed={filter === category} onClick={() => setFilter(category)}>{category}</button>)}</div>
    <div className="bike-grid">{bikes.filter(b => filter === "All motorcycles" || b.category === filter).map((bike, i) =>
      <article className="bike" key={bike.name}><div className="bike-photo">
        <img src={`/images/${bike.image}.jpg`} alt={bike.alt} loading="lazy" />
        <span className="bike-tag">{bike.category}</span></div><div className="bike-heading">
        <span className="bike-number">0{bikes.indexOf(bike) + 1}</span><h3>{bike.name}</h3></div>
        <p className="engine">{bike.engine}</p><p>{bike.text}</p>
        <p className="photo-caption">Illustrative riding-style photograph; not the model shown.</p>
        <div className="bike-actions"><button onClick={() => enquire(bike.category)}>Let’s talk about this ride ↗</button>
          <a href={bike.source} target="_blank" rel="noreferrer">Model details</a></div>
      </article>)}</div>
  </section>;
}
