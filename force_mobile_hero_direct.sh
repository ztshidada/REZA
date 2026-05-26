#!/bin/bash
set -e

echo "Forcing mobile hero directly inside pages..."

cat > frontend/mobile-hero-direct.js <<'JS'
(function () {
  const phrases = [
    "Glow. Repair. Restore.",
    "Soft. Luxury. Beauty.",
    "Elevate. Bloom. Become.",
    "Premium Care. Daily Confidence."
  ];

  function isMobile() {
    return window.innerWidth <= 768;
  }

  function fixHero() {
    if (!isMobile()) return;

    const hero =
      document.querySelector(".hero-shopify") ||
      document.querySelector(".hero") ||
      document.querySelector(".home-hero") ||
      document.querySelector(".page-hero");

    if (!hero) return;

    const h1 = hero.querySelector("h1");
    if (!h1) return;

    // Stop long text from breaking phone view
    h1.dataset.originalText = h1.dataset.originalText || h1.textContent.trim();
    h1.textContent = phrases[0];

    let index = 0;
    if (!window.__rezaHeroPhraseTimer) {
      window.__rezaHeroPhraseTimer = setInterval(() => {
        if (!isMobile()) return;
        index = (index + 1) % phrases.length;
        h1.textContent = phrases[index];
      }, 3200);
    }

    // Remove floating word chips on phone
    document.querySelectorAll(".floating-words,.alive-words,.word-cloud,.hero-floating-words")
      .forEach(el => el.remove());

    // Compact hero buttons
    document.querySelectorAll(".hero-actions .btn,.hero-buttons .btn,.cta-row .btn,.actions .btn,.hero .btn,.hero-shopify .btn")
      .forEach(btn => {
        btn.style.width = "auto";
        btn.style.maxWidth = "max-content";
        btn.style.padding = "11px 15px";
        btn.style.fontSize = "14px";
        btn.style.whiteSpace = "nowrap";
      });
  }

  document.addEventListener("DOMContentLoaded", fixHero);
  window.addEventListener("load", fixHero);
  window.addEventListener("resize", fixHero);
  setTimeout(fixHero, 500);
  setTimeout(fixHero, 1500);
})();
JS

cat > frontend/mobile-hero-direct.css <<'CSS'
/* Direct phone fix loaded last */
@media (max-width: 768px) {
  html, body {
    overflow-x: hidden !important;
    max-width: 100% !important;
  }

  .floating-words,
  .alive-words,
  .word-cloud,
  .hero-floating-words {
    display: none !important;
  }

  .hero-shopify,
  .hero,
  .home-hero,
  .page-hero {
    overflow: hidden !important;
    min-height: 560px !important;
  }

  .hero-shopify h1,
  .hero h1,
  .home-hero h1,
  .page-hero h1,
  main h1 {
    max-width: 100% !important;
    font-size: clamp(2.6rem, 12vw, 3.8rem) !important;
    line-height: .9 !important;
    white-space: normal !important;
    word-break: normal !important;
    overflow-wrap: normal !important;
  }

  .hero-actions,
  .hero-buttons,
  .cta-row,
  .actions {
    display: flex !important;
    flex-wrap: wrap !important;
    gap: 8px !important;
  }

  .hero-actions .btn,
  .hero-buttons .btn,
  .cta-row .btn,
  .actions .btn,
  .hero .btn,
  .hero-shopify .btn,
  .btn {
    width: auto !important;
    max-width: max-content !important;
    min-width: unset !important;
    flex: 0 0 auto !important;
    padding: 11px 15px !important;
    font-size: 14px !important;
    white-space: nowrap !important;
  }
}
CSS

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    text = re.sub(r'\s*<link rel="stylesheet" href="mobile-hero-direct\.css[^"]*">\s*', '\n', text)
    text = re.sub(r'\s*<script src="mobile-hero-direct\.js[^"]*"></script>\s*', '\n', text)

    text = text.replace("</head>", '  <link rel="stylesheet" href="mobile-hero-direct.css?v=force4">\n</head>')
    text = text.replace("</body>", '  <script src="mobile-hero-direct.js?v=force4"></script>\n</body>')

    p.write_text(text, encoding="utf-8")
    print("Forced:", p)
PY

git add .
git commit -m "Force mobile hero phrase rotation and compact buttons"
git push

echo "Done. Redeploy reza-frontend only."
