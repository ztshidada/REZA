#!/bin/bash
set -e

echo "🖼️ Saving live admin hero/logo as real frontend files..."

mkdir -p frontend/assets/images

node <<'NODE'
const fs = require("fs");
const path = require("path");
const https = require("https");

const API = "https://api.rezaholdings.co.za/api/media?t=" + Date.now();

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, res => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => resolve(data));
    }).on("error", reject);
  });
}

function saveDataUrl(dataUrl, outFile) {
  if (!dataUrl || !dataUrl.startsWith("data:image")) return false;

  const match = dataUrl.match(/^data:image\/([a-zA-Z0-9+.-]+);base64,(.+)$/);
  if (!match) return false;

  const buffer = Buffer.from(match[2], "base64");
  fs.writeFileSync(outFile, buffer);
  return true;
}

(async () => {
  const raw = await get(API);
  const json = JSON.parse(raw);
  const media = json.media || {};

  const heroOut = path.join("frontend", "assets", "images", "reza-hero.png");
  const logoOut = path.join("frontend", "assets", "images", "reza-logo.png");

  const heroSaved = saveDataUrl(media.heroImage, heroOut);
  const logoSaved = saveDataUrl(media.logoImage, logoOut);

  console.log(heroSaved ? "✅ Hero saved as frontend/assets/images/reza-hero.png" : "⚠️ Hero was not base64 in API.");
  console.log(logoSaved ? "✅ Logo saved as frontend/assets/images/reza-logo.png" : "⚠️ Logo was not base64 in API.");

  if (!heroSaved && media.heroImage && !media.heroImage.startsWith("data:image")) {
    console.log("Hero in API is:", media.heroImage);
  }
})();
NODE

echo "🎨 Fixing CSS so it uses only the real hero image..."

cat >> frontend/reza-style.css <<'CSS'

/* FINAL HERO FIX — use real frontend hero image only */
.hero-shopify {
  background-image: url("assets/images/reza-hero.png") !important;
  background-size: cover !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
}

.hero-shopify .hero-shade {
  background: linear-gradient(
    90deg,
    rgba(35, 28, 25, .20),
    rgba(35, 28, 25, .28)
  ) !important;
}

/* Stop fallback SVG from causing double text */
.hero-shopify::before,
.hero-shopify::after {
  display: none !important;
}

@media(max-width: 720px) {
  .hero-shopify {
    min-height: 560px !important;
    background-position: center center !important;
  }

  .hero-shopify .hero-shade {
    background: linear-gradient(
      0deg,
      rgba(35, 28, 25, .58),
      rgba(35, 28, 25, .10)
    ) !important;
  }
}
CSS

echo "🧼 Removing old fallback hero svg if it is causing the duplicated text..."
rm -f frontend/assets/images/reza-hero.svg

git add .
git commit -m "Save real hero and logo as frontend assets"
git push

echo "✅ Done. Now redeploy reza-frontend only."
