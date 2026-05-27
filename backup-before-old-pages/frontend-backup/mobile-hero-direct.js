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
