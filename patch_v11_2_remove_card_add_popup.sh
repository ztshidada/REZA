#!/bin/bash
set -e

echo "✨ Applying Reza V11.2 richer theme + announcement popup..."

# 1. Make theme richer and remove permanent hero card
cat >> frontend/css/app.css <<'CSS'

/* ================================
   REZA V11.2 — RICHER CHAMPAGNE + POPUP
   ================================ */

body {
  background:
    radial-gradient(circle at 18% 0%, rgba(201,148,61,.24), transparent 30%),
    radial-gradient(circle at 88% 10%, rgba(190,122,92,.20), transparent 28%),
    linear-gradient(180deg, #f6ead8 0%, #ead6bc 52%, #f7ead8 100%) !important;
}

.announce {
  background: linear-gradient(90deg, #ead0a1, #f7ead8, #dfb88b) !important;
  color: #5a3516 !important;
}

.header {
  background: rgba(246,234,216,.86) !important;
}

.hero {
  min-height: calc(100vh - 104px);
  background:
    linear-gradient(90deg, rgba(238,217,190,.94), rgba(238,217,190,.72), rgba(238,217,190,.42)),
    var(--hero) !important;
  background-size: cover !important;
  background-position: center !important;
}

.hero-grid {
  grid-template-columns: minmax(0, 760px) !important;
  justify-content: start !important;
}

.hero-card {
  display: none !important;
}

.hero h1 {
  color: #21140f !important;
  text-shadow: 0 18px 45px rgba(74,52,43,.16);
}

.lead {
  color: #5f4a3b !important;
  font-weight: 650;
}

.reza-chip {
  background: rgba(255,250,242,.78) !important;
  color: #4b3429 !important;
}

.page-hero {
  background:
    radial-gradient(circle at 86% 0%, rgba(201,148,61,.34), transparent 28%),
    linear-gradient(135deg, #f0d8b8, #ead0b1) !important;
}

.product,
.card,
.glass,
.summary,
.form-card {
  background: rgba(255,250,242,.78) !important;
}

.product:hover {
  box-shadow: 0 28px 85px rgba(74,52,43,.22) !important;
}

/* Premium announcement popup */
.reza-popup-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9998;
  background: rgba(33, 20, 15, .42);
  backdrop-filter: blur(10px);
  display: none;
  align-items: center;
  justify-content: center;
  padding: 22px;
}

.reza-popup-backdrop.show {
  display: flex;
  animation: popupFade .25s ease both;
}

@keyframes popupFade {
  from { opacity: 0; }
  to { opacity: 1; }
}

.reza-popup {
  width: min(520px, 94vw);
  border-radius: 34px;
  overflow: hidden;
  background:
    radial-gradient(circle at top right, rgba(255,255,255,.75), transparent 34%),
    linear-gradient(145deg, #fffaf2, #ead0a8);
  border: 1px solid rgba(255,255,255,.88);
  box-shadow: 0 35px 110px rgba(33,20,15,.32);
  position: relative;
  animation: popupRise .35s cubic-bezier(.2,.9,.2,1) both;
}

@keyframes popupRise {
  from { transform: translateY(24px) scale(.96); opacity: 0; }
  to { transform: translateY(0) scale(1); opacity: 1; }
}

.reza-popup-top {
  padding: 30px 30px 10px;
}

.reza-popup-kicker {
  color: #9a641b;
  letter-spacing: .22em;
  text-transform: uppercase;
  font-size: .75rem;
  font-weight: 1000;
  margin-bottom: 12px;
}

.reza-popup h2 {
  font-family: var(--head);
  font-size: clamp(2.2rem, 7vw, 3.8rem);
  line-height: .94;
  margin: 0;
  color: #21140f;
}

.reza-popup p {
  color: #624b3a;
  line-height: 1.65;
  font-weight: 650;
  margin: 18px 0 0;
}

.reza-popup-actions {
  padding: 24px 30px 30px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.reza-popup-close {
  position: absolute;
  top: 18px;
  right: 18px;
  width: 38px;
  height: 38px;
  border-radius: 999px;
  border: 0;
  background: rgba(255,255,255,.62);
  color: #21140f;
  font-weight: 1000;
  cursor: pointer;
}

.reza-popup-note {
  margin-top: 16px;
  padding: 14px 16px;
  border-radius: 20px;
  background: rgba(255,255,255,.56);
  color: #775634;
  font-weight: 850;
  line-height: 1.45;
}

@media(max-width:650px) {
  .hero-grid {
    grid-template-columns: 1fr !important;
  }

  .hero {
    min-height: 82vh;
  }
}

CSS

# 2. Add popup JS and remove hero image card logic visually
cat >> frontend/js/app.js <<'JS'

// ================================
// REZA V11.2 — SPECIAL ANNOUNCEMENT POPUP
// ================================
(function(){
  const POPUP_ENABLED = true;

  // Change this text whenever you have a special.
  const special = {
    title: "Welcome to Reza",
    message: "Premium health, beauty and wellness products with a soft champagne luxury experience.",
    note: "Special announcements, promos and product drops can appear here.",
    buttonText: "Shop Products",
    buttonLink: "shop.html"
  };

  function shouldShowPopup(){
    if(!POPUP_ENABLED) return false;

    // Shows once per browser session.
    // To show every time, change sessionStorage to localStorage or remove this check.
    return !sessionStorage.getItem("reza_v11_popup_seen");
  }

  function showPopup(){
    if(!shouldShowPopup()) return;

    const el = document.createElement("div");
    el.className = "reza-popup-backdrop";
    el.innerHTML = `
      <div class="reza-popup">
        <button class="reza-popup-close" aria-label="Close popup">×</button>
        <div class="reza-popup-top">
          <div class="reza-popup-kicker">Reza Announcement</div>
          <h2>${special.title}</h2>
          <p>${special.message}</p>
          <div class="reza-popup-note">${special.note}</div>
        </div>
        <div class="reza-popup-actions">
          <a class="btn primary" href="${special.buttonLink}">${special.buttonText}</a>
          <button class="btn ghost" data-popup-later>Maybe Later</button>
        </div>
      </div>
    `;

    document.body.appendChild(el);

    setTimeout(() => el.classList.add("show"), 650);

    function close(){
      sessionStorage.setItem("reza_v11_popup_seen", "yes");
      el.classList.remove("show");
      setTimeout(() => el.remove(), 220);
    }

    el.querySelector(".reza-popup-close").addEventListener("click", close);
    el.querySelector("[data-popup-later]").addEventListener("click", close);
    el.addEventListener("click", (event) => {
      if(event.target === el) close();
    });
  }

  document.addEventListener("DOMContentLoaded", showPopup);
})();

JS

echo "✅ V11.2 applied: richer champagne, hero card removed, announcement popup added."
