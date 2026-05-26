#!/bin/bash
set -e

echo "🖼️ Forcing saved admin hero image onto homepage..."

mkdir -p frontend/js

cat > frontend/js/reza-hero-background-final.js <<'JS'
(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function imageUrl(src) {
    if (!src) return null;
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function findHeroSections() {
    const selectors = [
      ".hero",
      ".home-hero",
      ".page-hero",
      ".landing-hero",
      ".hero-section",
      "section:first-of-type",
      "main section:first-of-type"
    ];

    const found = [];

    selectors.forEach(selector => {
      document.querySelectorAll(selector).forEach(el => {
        if (!found.includes(el)) found.push(el);
      });
    });

    return found;
  }

  async function applyHeroBackground() {
    try {
      const res = await fetch(API_BASE + "/api/media?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !data.media || !data.media.heroImage) {
        console.warn("No hero image found in media API.");
        return;
      }

      const img = imageUrl(data.media.heroImage);
      if (!img) return;

      const sections = findHeroSections();

      sections.forEach(section => {
        section.style.backgroundImage =
          `linear-gradient(90deg, rgba(255,248,238,.90), rgba(255,239,220,.62), rgba(255,220,205,.24)), url("${img}")`;

        section.style.backgroundSize = "cover";
        section.style.backgroundPosition = "center";
        section.style.backgroundRepeat = "no-repeat";
      });

      document.documentElement.style.setProperty("--reza-admin-hero", `url("${img}")`);

      console.log("✅ Reza hero background applied:", sections.length);
    } catch (error) {
      console.error("Hero background failed:", error);
    }
  }

  document.addEventListener("DOMContentLoaded", applyHeroBackground);
  window.addEventListener("load", applyHeroBackground);

  setTimeout(applyHeroBackground, 800);
})();
JS

cat >> frontend/css/app.css <<'CSS'

/* FINAL — Admin saved hero background support */
:root {
  --reza-admin-hero: none;
}

.hero,
.home-hero,
.page-hero,
.landing-hero,
.hero-section {
  background-image:
    linear-gradient(90deg, rgba(255,248,238,.90), rgba(255,239,220,.62), rgba(255,220,205,.24)),
    var(--reza-admin-hero) !important;
  background-size: cover !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
}

CSS

python3 - <<'PY'
from pathlib import Path

for p in Path("frontend").glob("*.html"):
    text = p.read_text()

    # Put this script right before </body> so it runs after everything else
    if "js/reza-hero-background-final.js" not in text:
        text = text.replace("</body>", '  <script src="js/reza-hero-background-final.js"></script>\n</body>')
        p.write_text(text)
        print("Injected hero background script into", p)
PY

git add .
git commit -m "Force saved admin hero background onto frontend"
git push

echo "✅ Done. Redeploy reza-frontend only."
