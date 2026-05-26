#!/bin/bash
set -e

echo "✨ Adding champagne-gold animated hero words..."

mkdir -p frontend/js

cat > frontend/js/alive-words.js <<'JS'
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
JS

cat >> frontend/css/app.css <<'CSS'

/* ===== Champagne Gold Hero Word Effects ===== */
.hero h1,
.hero-title,
h1 {
  line-height: .95;
}

.hero-line {
  display: block;
  font-weight: 800;
  letter-spacing: -0.03em;
  position: relative;
  animation: heroShimmer 4s ease-in-out infinite;
  background-size: 200% 200%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.gold-a {
  background-image: linear-gradient(90deg, #7a4f11 0%, #d4af37 35%, #f6e2a3 60%, #b8860b 100%);
  text-shadow: 0 0 18px rgba(212, 175, 55, 0.14);
}

.gold-b {
  background-image: linear-gradient(90deg, #8a5a1f 0%, #e2be72 35%, #fff1c7 60%, #b8893d 100%);
  text-shadow: 0 0 18px rgba(226, 190, 114, 0.15);
}

.gold-c {
  background-image: linear-gradient(90deg, #6f4316 0%, #c9963d 35%, #f0d79a 60%, #9f6d22 100%);
  text-shadow: 0 0 18px rgba(201, 150, 61, 0.14);
}

.gold-d {
  background-image: linear-gradient(90deg, #5c3813 0%, #d8b46b 40%, #f8e8be 65%, #aa7a30 100%);
  text-shadow: 0 0 18px rgba(248, 232, 190, 0.14);
}

.word-pop {
  animation: rezaWordPop .7s cubic-bezier(.18,.89,.32,1.28);
}

@keyframes rezaWordPop {
  0% {
    opacity: 0;
    transform: translateY(20px) scale(.96);
    filter: blur(8px);
  }
  100% {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

@keyframes heroShimmer {
  0% {
    background-position: 0% 50%;
    transform: translateY(0px);
  }
  50% {
    background-position: 100% 50%;
    transform: translateY(-2px);
  }
  100% {
    background-position: 0% 50%;
    transform: translateY(0px);
  }
}

/* optional: make action buttons feel more premium */
.hero .btn,
.hero button,
.hero a.btn,
.hero .shop-btn {
  transition: transform .25s ease, box-shadow .25s ease, filter .25s ease;
}

.hero .btn:hover,
.hero button:hover,
.hero a.btn:hover,
.hero .shop-btn:hover {
  transform: translateY(-4px) scale(1.03);
  box-shadow: 0 16px 36px rgba(201, 150, 61, 0.22);
  filter: brightness(1.03);
}

.hero .btn.primary,
.hero .shop-btn.primary,
.hero .cta-primary {
  animation: softGoldBounce 2.8s ease-in-out infinite;
}

@keyframes softGoldBounce {
  0%, 100% {
    transform: translateY(0);
    box-shadow: 0 10px 24px rgba(212, 175, 55, .18);
  }
  50% {
    transform: translateY(-5px);
    box-shadow: 0 20px 40px rgba(212, 175, 55, .28);
  }
}
CSS

git add .
git commit -m "Add champagne-gold animated hero word colors"
git push

echo "✅ Gold word animation added."
