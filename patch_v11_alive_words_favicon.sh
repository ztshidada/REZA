#!/bin/bash
set -e

echo "✨ Adding animated words, bouncing buttons and favicon..."

mkdir -p frontend/assets/images admin/assets/images frontend/js

# 1) Create favicon logo
cat > frontend/assets/images/favicon.svg <<'SVG'
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <rect width="128" height="128" rx="32" fill="#1f1510"/>
  <circle cx="64" cy="64" r="48" fill="#fff4d8" opacity="0.08"/>
  <text x="64" y="78" text-anchor="middle" font-family="Georgia, serif" font-size="62" font-weight="700" fill="#d6a84f">R</text>
</svg>
SVG

cp frontend/assets/images/favicon.svg admin/assets/images/favicon.svg

# 2) Add favicon to all frontend/admin pages
python3 - <<'PY'
from pathlib import Path

for folder in ["frontend", "admin"]:
    for p in Path(folder).glob("*.html"):
        text = p.read_text()
        if "favicon.svg" not in text:
            text = text.replace(
                "</head>",
                '  <link rel="icon" type="image/svg+xml" href="assets/images/favicon.svg">\n</head>'
            )
            p.write_text(text)
            print("Added favicon to", p)
PY

# 3) Add alive animated words script
cat > frontend/js/alive-words.js <<'JS'
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
JS

# 4) Inject alive words script
python3 - <<'PY'
from pathlib import Path

for p in Path("frontend").glob("*.html"):
    text = p.read_text()
    if "js/alive-words.js" not in text:
        text = text.replace("</body>", '  <script src="js/alive-words.js"></script>\n</body>')
        p.write_text(text)
        print("Injected alive words into", p)
PY

# 5) Add CSS animations
cat >> frontend/css/app.css <<'CSS'

/* V11 Alive Words + Button Motion */
.word-pop {
  animation: rezaWordPop .75s cubic-bezier(.18,.89,.32,1.28);
}

@keyframes rezaWordPop {
  0% {
    opacity: 0;
    transform: translateY(22px) scale(.96);
    filter: blur(8px);
  }
  100% {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: blur(0);
  }
}

.btn,
button,
.nav a,
.cart-btn,
.shop-btn {
  transition: transform .25s ease, box-shadow .25s ease, filter .25s ease;
}

.btn:hover,
button:hover,
.nav a:hover,
.cart-btn:hover,
.shop-btn:hover {
  transform: translateY(-4px) scale(1.035);
  filter: brightness(1.04);
}

.btn.primary,
button.primary,
.shop-btn,
.cart-btn {
  animation: rezaSoftBounce 2.7s ease-in-out infinite;
}

@keyframes rezaSoftBounce {
  0%, 100% {
    transform: translateY(0);
    box-shadow: 0 14px 32px rgba(201,148,61,.20);
  }
  50% {
    transform: translateY(-5px);
    box-shadow: 0 22px 48px rgba(201,148,61,.30);
  }
}

.floating-words {
  position: absolute;
  inset: auto 8% 8% auto;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  max-width: 420px;
  pointer-events: none;
  z-index: 5;
}

.floating-words span {
  padding: 12px 18px;
  border-radius: 999px;
  background: rgba(255,255,255,.68);
  border: 1px solid rgba(201,148,61,.22);
  box-shadow: 0 16px 40px rgba(95,64,30,.10);
  font-weight: 900;
  color: #5b3b1d;
  animation: rezaFloatChip 4s ease-in-out infinite;
}

.floating-words span:nth-child(2) { animation-delay: .6s; }
.floating-words span:nth-child(3) { animation-delay: 1.2s; }
.floating-words span:nth-child(4) { animation-delay: 1.8s; }

@keyframes rezaFloatChip {
  0%, 100% {
    transform: translateY(0) rotate(0deg);
    opacity: .82;
  }
  50% {
    transform: translateY(-12px) rotate(-1deg);
    opacity: 1;
  }
}

.hero {
  position: relative;
  overflow: hidden;
}

.hero::before {
  content: "";
  position: absolute;
  width: 320px;
  height: 320px;
  right: 10%;
  top: 16%;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(214,168,79,.22), transparent 65%);
  filter: blur(10px);
  animation: rezaGlowMove 7s ease-in-out infinite;
  pointer-events: none;
}

@keyframes rezaGlowMove {
  0%, 100% {
    transform: translate(0,0) scale(1);
  }
  50% {
    transform: translate(-28px, 24px) scale(1.15);
  }
}

@media (max-width: 850px) {
  .floating-words {
    position: static;
    margin-top: 24px;
    max-width: 100%;
  }
}

CSS

git add .
git commit -m "Add alive changing words, bouncing buttons and favicon"
git push

echo "✅ Done. Redeploy reza-frontend and admin_frontend."
