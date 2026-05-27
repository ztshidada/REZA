(function(){
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const SESSION_KEY = "reza_popup_seen_this_visit";

  function isHomePage() {
    const path = location.pathname.toLowerCase();
    return path === "/" || path.endsWith("/index.html") || path === "";
  }

  async function loadPopup(){
    try {
      if (!isHomePage()) return;
      if (sessionStorage.getItem(SESSION_KEY) === "yes") return;

      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !data.popup || !data.popup.enabled) return;

      const p = data.popup;
      sessionStorage.setItem(SESSION_KEY, "yes");

      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" alt="Special" class="reza-popup-img">` : ""}
          <p class="reza-popup-kicker">${p.category || "Specials"}</p>
          <h2>${p.title || "Special Announcement"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;

      document.body.appendChild(overlay);

      overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
      overlay.addEventListener("click", e => {
        if (e.target === overlay) overlay.remove();
      });
    } catch (err) {
      console.warn("Popup not loaded", err);
    }
  }

  document.addEventListener("DOMContentLoaded", () => setTimeout(loadPopup, 800));
})();
