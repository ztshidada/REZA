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
