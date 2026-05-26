(function () {
  const heroWords = [
    "Elevate.",
    "Bloom.",
    "Glow.",
    "Repair.",
    "Restore.",
    "Become.",
    "Shine."
  ];

  const subtitles = [
    "Premium health, beauty and wellness products with a soft luxury experience.",
    "Beautiful products. Smooth shopping. Trusted service.",
    "Glow with confidence. Shop Reza luxury.",
    "Health, beauty and wellness made simple."
  ];

  function findHeroTitle() {
    return document.querySelector(".hero h1") ||
           document.querySelector(".hero-title") ||
           document.querySelector("h1");
  }

  function findHeroLead() {
    return document.querySelector(".hero p") ||
           document.querySelector(".lead");
  }

  function animateText() {
    const title = findHeroTitle();
    const lead = findHeroLead();

    if (!title) return;

    let index = 0;

    setInterval(() => {
      index = (index + 1) % heroWords.length;

      title.classList.remove("word-pop");
      void title.offsetWidth;

      if (index % 3 === 0) {
        title.innerHTML = `Glow.<br>Repair.<br>Rise.`;
      } else if (index % 3 === 1) {
        title.innerHTML = `Elevate.<br>Bloom.<br>Become.`;
      } else {
        title.innerHTML = `${heroWords[index]}<br>${heroWords[(index + 1) % heroWords.length]}<br>${heroWords[(index + 2) % heroWords.length]}`;
      }

      title.classList.add("word-pop");

      if (lead) {
        lead.textContent = subtitles[index % subtitles.length];
      }
    }, 3200);
  }

  function addFloatingWords() {
    const hero = document.querySelector(".hero");
    if (!hero || document.querySelector(".floating-words")) return;

    const wrap = document.createElement("div");
    wrap.className = "floating-words";
    wrap.innerHTML = `
      <span>Luxury Beauty</span>
      <span>Soft Wellness</span>
      <span>Premium Care</span>
      <span>Fast Checkout</span>
    `;

    hero.appendChild(wrap);
  }

  document.addEventListener("DOMContentLoaded", () => {
    animateText();
    addFloatingWords();
  });
})();
