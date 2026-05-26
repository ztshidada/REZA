#!/bin/bash
set -e

echo "Fixing mobile hero words into proper 2/3 lines..."

cat > frontend/mobile-hero-lines-v2.js <<'JS'
(function () {
  const phrases = [
    ["Glow.", "Repair.", "Restore."],
    ["Soft Luxury.", "Beauty."],
    ["Elevate.", "Bloom.", "Become."],
    ["Premium Care.", "Daily Confidence."]
  ];

  function isMobile() {
    return window.innerWidth <= 768;
  }

  function applyHeroLines() {
    if (!isMobile()) return;

    const hero =
      document.querySelector(".hero-shopify") ||
      document.querySelector(".hero") ||
      document.querySelector(".home-hero") ||
      document.querySelector(".page-hero");

    if (!hero) return;

    const h1 = hero.querySelector("h1");
    if (!h1) return;

    h1.classList.add("mobile-hero-lines");

    let index = Number(h1.dataset.rezaPhraseIndex || 0);

    function renderPhrase() {
      const lines = phrases[index];
      h1.innerHTML = lines.map(line => `<span>${line}</span>`).join("");
      h1.dataset.rezaPhraseIndex = String(index);
      index = (index + 1) % phrases.length;
    }

    renderPhrase();

    if (!window.__rezaMobileHeroLinesTimer) {
      window.__rezaMobileHeroLinesTimer = setInterval(() => {
        if (!isMobile()) return;
        renderPhrase();
      }, 3200);
    }

    document
      .querySelectorAll(".floating-words,.alive-words,.word-cloud,.hero-floating-words")
      .forEach(el => el.remove());
  }

  document.addEventListener("DOMContentLoaded", applyHeroLines);
  window.addEventListener("load", applyHeroLines);
  window.addEventListener("resize", applyHeroLines);

  setTimeout(applyHeroLines, 500);
  setTimeout(applyHeroLines, 1500);
  setTimeout(applyHeroLines, 3000);
})();
JS

cat > frontend/mobile-hero-lines-v2.css <<'CSS'
/* Mobile hero line fix — keeps gold mirror effect, fixes long words */

@media (max-width: 768px) {
  html,
  body {
    max-width: 100% !important;
    overflow-x: hidden !important;
  }

  .floating-words,
  .alive-words,
  .word-cloud,
  .hero-floating-words {
    display: none !important;
  }

  .mobile-hero-lines {
    display: block !important;
    width: 100% !important;
    max-width: 100% !important;
    white-space: normal !important;
    word-break: normal !important;
    overflow-wrap: normal !important;
    text-align: left !important;
    line-height: .88 !important;
    font-size: clamp(2.65rem, 13vw, 4rem) !important;
    letter-spacing: -0.055em !important;
  }

  .mobile-hero-lines span {
    display: block !important;
    width: 100% !important;
    max-width: 100% !important;
    white-space: normal !important;
  }

  .hero-shopify,
  .hero,
  .home-hero,
  .page-hero {
    overflow: hidden !important;
    min-height: 560px !important;
  }

  .hero-actions,
  .hero-buttons,
  .cta-row,
  .actions {
    display: flex !important;
    flex-wrap: wrap !important;
    gap: 9px !important;
    justify-content: flex-start !important;
  }

  .hero-actions .btn,
  .hero-buttons .btn,
  .cta-row .btn,
  .actions .btn,
  .hero-shopify .btn,
  .hero .btn,
  .btn {
    width: auto !important;
    min-width: unset !important;
    max-width: max-content !important;
    flex: 0 0 auto !important;
    padding: 11px 15px !important;
    font-size: .86rem !important;
    line-height: 1 !important;
    white-space: nowrap !important;
    border-radius: 999px !important;
  }
}

@media (max-width: 390px) {
  .mobile-hero-lines {
    font-size: clamp(2.35rem, 12.5vw, 3.45rem) !important;
  }

  .hero-actions .btn,
  .hero-buttons .btn,
  .cta-row .btn,
  .actions .btn,
  .btn {
    padding: 10px 12px !important;
    font-size: .8rem !important;
  }
}
CSS

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    # Remove older mobile hero fix files to avoid conflict
    text = re.sub(r'\s*<link rel="stylesheet" href="mobile-hero-[^"]*">\s*', '\n', text)
    text = re.sub(r'\s*<script src="mobile-hero-[^"]*"></script>\s*', '\n', text)

    # Add new files LAST
    text = text.replace(
        "</head>",
        '  <link rel="stylesheet" href="mobile-hero-lines-v2.css?v=lines2">\n</head>'
    )

    text = text.replace(
        "</body>",
        '  <script src="mobile-hero-lines-v2.js?v=lines2"></script>\n</body>'
    )

    p.write_text(text, encoding="utf-8")
    print("Updated:", p)
PY

git add .
git commit -m "Fix mobile hero rotating words into short lines"
git push

echo "Done. Redeploy reza-frontend only."
