import React, { useState } from "react";
import Catalogue from "./Catalogue.jsx";
import Contact from "./Contact.jsx";
export default function App() {
  const [interest, setInterest] = useState("All motorcycles");
  function enquire(category) {
    setInterest(category);
    document.getElementById("contact").scrollIntoView({ behavior: "smooth" });
  }
  return <>
    <header><a className="brand" href="#">MOTO<span> / </span>HAUS</a>
      <nav aria-label="Main"><a href="#collection">The collection</a>
        <a href="#story">Our philosophy</a><a className="nav-cta" href="#contact">Contact us ↗</a></nav></header>
    <main>
      <section className="hero" aria-labelledby="hero-title">
        <img src="/images/hero.jpg" alt="Black Harley-Davidson motorcycle at sunset" fetchPriority="high" />
        <div className="hero-shade" /><div className="hero-content">
          <p className="eyebrow">FOR THE LOVE OF THE RIDE</p>
          <h1 id="hero-title">Life looks better<br />on two wheels.</h1>
          <p>Character. Craft. A little rebellion.<br />Find the motorcycle that moves you.</p>
          <a className="button" href="#collection">Explore the collection <span>↗</span></a>
        </div><div className="hero-note"><span>01 / THE OPEN ROAD</span><span>Built for the way you feel.</span></div>
      </section>
      <div className="ticker"><span>MORE THAN A MACHINE.</span><span>IT’S A STATE OF MIND.</span><span>FIND YOUR NEXT CHAPTER. ↗</span></div>
      <Catalogue enquire={enquire} />
      <section className="story" id="story"><p className="eyebrow">THE MOTOHAUS PHILOSOPHY</p>
        <h2>A good motorcycle takes you places.<br />A great one makes you feel something.</h2>
        <p>From a quiet Sunday ride to the long way home, we help you explore the machines
          and riding styles that fit your life. Tell us what you have in mind. Let’s talk motorcycles.</p>
        <div className="values"><span>01 / DISTINCTIVE MACHINES</span><span>02 / HUMAN CONVERSATIONS</span><span>03 / YOUR KIND OF FREEDOM</span></div>
      </section>
      <Contact interest={interest} setInterest={setInterest} />
    </main>
    <footer><a className="brand" href="#">MOTO / HAUS</a><p>A demonstration motorcycle showroom. Images are illustrative.</p>
      <a href="/credits.html">Photography & model sources ↗</a><span>© {new Date().getFullYear()} Motohaus</span></footer>
  </>;
}
