#!/bin/bash
set -e

echo "Fixing phone layout after gold headings..."

cat >> frontend/reza-style.css <<'CSS'

/* FINAL PHONE FIX AFTER GOLD HEADINGS
   Keep mirror-gold headings, fix words/buttons only.
*/

/* Stop animated/floating word chips from breaking phone view */
@media (max-width: 760px) {
  .floating-words,
  .alive-words,
  .word-cloud,
  .hero-floating-words {
    display: none !important;
  }

  /* Keep hero clean and readable */
  .hero-shopify,
  .hero,
  .home-hero,
  .page-hero {
    overflow: hidden !important;
  }

  .hero-shopify h1,
  .hero h1,
  .home-hero h1,
  .page-hero h1,
  main h1 {
    max-width: 100% !important;
    word-break: normal !important;
    overflow-wrap: normal !important;
  }

  /* Fix long buttons on phone */
  .hero-actions,
  .actions,
  .cta-row,
  .hero-buttons {
    display: flex !important;
    flex-wrap: wrap !important;
    gap: 10px !important;
    align-items: center !important;
  }

  .hero-actions .btn,
  .actions .btn,
  .cta-row .btn,
  .hero-buttons .btn,
  .hero-shopify .btn,
  .hero .btn,
  .page-hero .btn,
  a.btn,
  button.btn {
    width: auto !important;
    min-width: 0 !important;
    max-width: 100% !important;
    display: inline-flex !important;
    justify-content: center !important;
    align-items: center !important;
    padding: 12px 18px !important;
    font-size: .92rem !important;
    line-height: 1.1 !important;
    white-space: nowrap !important;
  }

  /* If there are two hero buttons, keep them neat */
  .hero-actions .btn,
  .hero-buttons .btn,
  .cta-row .btn {
    flex: 0 0 auto !important;
  }
}

/* Extra small phones */
@media (max-width: 430px) {
  .hero-actions,
  .actions,
  .cta-row,
  .hero-buttons {
    gap: 8px !important;
  }

  .hero-actions .btn,
  .actions .btn,
  .cta-row .btn,
  .hero-buttons .btn,
  .hero-shopify .btn,
  .hero .btn,
  .page-hero .btn,
  a.btn,
  button.btn {
    padding: 11px 14px !important;
    font-size: .86rem !important;
    border-radius: 999px !important;
  }
}

/* Keep desktop alive effect unchanged */
@media (min-width: 761px) {
  .floating-words {
    display: flex;
  }
}

CSS

git add .
git commit -m "Fix mobile layout after mirror gold headings"
git push

echo "Done. Redeploy reza-frontend only."
