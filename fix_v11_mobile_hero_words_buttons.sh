#!/bin/bash
set -e

echo "Fixing mobile hero words and buttons properly..."

cat >> frontend/reza-style.css <<'CSS'

/* =========================================================
   FINAL MOBILE HERO FIX
   Keeps gold mirror headings.
   Fixes long words + long buttons on phone.
========================================================= */

@media (max-width: 768px) {

  html,
  body {
    max-width: 100% !important;
    overflow-x: hidden !important;
  }

  /* Hide the extra floating/animated words on phone */
  .floating-words,
  .alive-words,
  .word-cloud,
  .hero-floating-words,
  .floating-words span,
  .alive-words span,
  .word-cloud span {
    display: none !important;
  }

  /* Hero must fit phone screen */
  .hero-shopify,
  .hero,
  .home-hero,
  .page-hero,
  .hero-section {
    min-height: 560px !important;
    height: auto !important;
    padding: 80px 18px 70px !important;
    overflow: hidden !important;
    background-position: center center !important;
  }

  .hero-shopify .hero-content,
  .hero-shopify .container,
  .hero .container,
  .page-hero .container,
  .container {
    width: 100% !important;
    max-width: 100% !important;
    margin: 0 auto !important;
  }

  /* Big heading must wrap nicely */
  .hero-shopify h1,
  .hero h1,
  .home-hero h1,
  .page-hero h1,
  .hero-section h1,
  main h1 {
    width: 100% !important;
    max-width: 100% !important;
    font-size: clamp(3rem, 13vw, 4.2rem) !important;
    line-height: .9 !important;
    letter-spacing: -0.05em !important;
    white-space: normal !important;
    word-break: normal !important;
    overflow-wrap: normal !important;
    text-align: left !important;
    transform: none !important;
  }

  .hero-shopify p,
  .hero p,
  .page-hero p {
    width: 100% !important;
    max-width: 100% !important;
    font-size: 1rem !important;
    line-height: 1.45 !important;
    text-align: left !important;
  }

  /* Buttons must not stretch too long */
  .hero-actions,
  .hero-buttons,
  .cta-row,
  .actions {
    display: flex !important;
    flex-direction: row !important;
    flex-wrap: wrap !important;
    justify-content: flex-start !important;
    align-items: center !important;
    gap: 10px !important;
    width: 100% !important;
  }

  .hero-actions a,
  .hero-actions .btn,
  .hero-buttons a,
  .hero-buttons .btn,
  .cta-row a,
  .cta-row .btn,
  .actions a,
  .actions .btn,
  .hero-shopify .btn,
  .hero .btn,
  a.btn,
  button.btn,
  .btn {
    width: auto !important;
    max-width: fit-content !important;
    min-width: unset !important;
    flex: 0 0 auto !important;
    padding: 12px 18px !important;
    font-size: .9rem !important;
    line-height: 1 !important;
    white-space: nowrap !important;
    border-radius: 999px !important;
  }
}

/* Extra small phone */
@media (max-width: 430px) {
  .hero-shopify,
  .hero,
  .page-hero {
    min-height: 540px !important;
    padding-left: 16px !important;
    padding-right: 16px !important;
  }

  .hero-shopify h1,
  .hero h1,
  .page-hero h1,
  main h1 {
    font-size: clamp(2.65rem, 12vw, 3.7rem) !important;
  }

  .hero-actions a,
  .hero-actions .btn,
  .hero-buttons a,
  .hero-buttons .btn,
  .cta-row a,
  .cta-row .btn,
  .actions a,
  .actions .btn,
  .hero-shopify .btn,
  .hero .btn,
  a.btn,
  button.btn,
  .btn {
    padding: 11px 14px !important;
    font-size: .84rem !important;
  }
}
CSS

# Make sure the fix is loaded after everything else
python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    text = re.sub(r'\s*<link rel="stylesheet" href="mobile-hero-fix\.css[^"]*">\s*', '\n', text)

    if "mobile-hero-fix.css" not in text:
        text = text.replace("</head>", '  <link rel="stylesheet" href="mobile-hero-fix.css?v=3">\n</head>')

    p.write_text(text, encoding="utf-8")
    print("Checked:", p)
PY

cat > frontend/mobile-hero-fix.css <<'CSS'
@media (max-width: 768px) {
  .floating-words,
  .alive-words,
  .word-cloud,
  .hero-floating-words {
    display: none !important;
  }

  .hero-shopify h1,
  .hero h1,
  .page-hero h1,
  main h1 {
    white-space: normal !important;
    max-width: 100% !important;
    font-size: clamp(2.65rem, 12vw, 4rem) !important;
    line-height: .9 !important;
    transform: none !important;
  }

  .hero-actions,
  .hero-buttons,
  .cta-row,
  .actions {
    display: flex !important;
    flex-wrap: wrap !important;
    gap: 9px !important;
  }

  .hero-actions .btn,
  .hero-buttons .btn,
  .cta-row .btn,
  .actions .btn,
  .btn {
    width: auto !important;
    max-width: fit-content !important;
    padding: 11px 15px !important;
    font-size: .86rem !important;
    white-space: nowrap !important;
  }
}
CSS

git add .
git commit -m "Fix mobile hero words and compact buttons"
git push

echo "Done. Redeploy reza-frontend only."
