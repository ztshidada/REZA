(function () {
  const heroSets = [
    ["Elevate.", "Bloom.", "Become."],
    ["Glow.", "Repair.", "Restore."],
    ["Shine.", "Glow.", "Rise."],
    ["Soft.", "Luxury.", "Beauty."],
    ["Wellness.", "Glow.", "Confidence."]
  ];

  const subtitles = [
    "A soft luxury health, beauty and wellness store with a champagne glow.",
    "Elegant products, premium care and a smooth shopping experience.",
    "Glow with confidence through beauty, wellness and luxury care.",
    "Premium products designed to feel clean, rich and beautiful.",
    "Soft luxury shopping with a warm, modern Reza experience."
  ];

  const colorSets = [
    ["gold-a", "gold-b", "gold-c"],
    ["gold-b", "gold-c", "gold-d"],
    ["gold-c", "gold-a", "gold-d"],
    ["gold-d", "gold-b", "gold-a"],
    ["gold-a", "gold-d", "gold-c"]
  ];

  function getTitle() {
    return document.querySelector(".hero h1") ||
           document.querySelector(".hero-title") ||
           document.querySelector("h1");
  }

  function getLead() {
    return document.querySelector(".hero p") ||
           document.querySelector(".hero-copy") ||
           document.querySelector(".lead");
  }

  function renderWords(words, colors) {
    return words.map((word, i) => {
      return `<span class="hero-line ${colors[i]}">${word}</span>`;
    }).join("");
  }

  function startAnimation() {
    const title = getTitle();
    const lead = getLead();
    if (!title) return;

    let i = 0;

    function update() {
      const words = heroSets[i % heroSets.length];
      const colors = colorSets[i % colorSets.length];

      title.classList.remove("word-pop");
      void title.offsetWidth;

      title.innerHTML = renderWords(words, colors);
      title.classList.add("word-pop");

      if (lead) {
        lead.textContent = subtitles[i % subtitles.length];
      }

      i++;
    }

    update();
    setInterval(update, 3200);
  }

  document.addEventListener("DOMContentLoaded", startAnimation);
})();
