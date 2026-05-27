(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const KEY = "reza_popup_seen_current_browser_session";

  function isHome() {
    const p = location.pathname.toLowerCase();
    return p === "/" || p.endsWith("/index.html") || p.endsWith("/index");
  }

  async function run() {
    if (!isHome()) return;
    if (sessionStorage.getItem(KEY) === "yes") return;

    try {
      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !data.popup || !data.popup.enabled) return;

      sessionStorage.setItem(KEY, "yes");

      const p = data.popup;
      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" class="reza-popup-img" alt="Special">` : ""}
          <p class="reza-popup-kicker">${p.category || "Specials"}</p>
          <h2>${p.title || "Special"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;
      document.body.appendChild(overlay);

      overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
      overlay.onclick = e => {
        if (e.target === overlay) overlay.remove();
      };
    } catch (error) {
      console.warn("Popup failed", error);
    }
  }

  document.addEventListener("DOMContentLoaded", () => setTimeout(run, 700));
})();
