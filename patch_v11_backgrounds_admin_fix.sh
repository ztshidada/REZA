#!/bin/bash
set -e

echo "✨ Fixing V11 backgrounds and admin homepage..."

mkdir -p frontend/assets/images admin/assets/images

cat > frontend/assets/images/reza-soft-beauty-bg.svg <<'SVG'
<svg width="1800" height="1100" viewBox="0 0 1800 1100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="1800" height="1100" fill="#FFF6E8"/>
  <defs>
    <radialGradient id="rose" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(1320 360) rotate(128) scale(760 520)">
      <stop stop-color="#F4C7B8" stop-opacity=".75"/>
      <stop offset="1" stop-color="#F4C7B8" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="gold" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(980 760) rotate(90) scale(680 900)">
      <stop stop-color="#E8C98D" stop-opacity=".62"/>
      <stop offset="1" stop-color="#E8C98D" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="cream" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(280 180) rotate(45) scale(680 460)">
      <stop stop-color="#FFFFFF" stop-opacity=".95"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="metal" x1="0" x2="1" y1="0" y2="1">
      <stop stop-color="#FFF8EA"/>
      <stop offset=".45" stop-color="#D8A64C"/>
      <stop offset="1" stop-color="#9F6A2C"/>
    </linearGradient>
  </defs>

  <rect width="1800" height="1100" fill="url(#rose)"/>
  <rect width="1800" height="1100" fill="url(#gold)"/>
  <rect width="1800" height="1100" fill="url(#cream)"/>

  <g opacity=".35">
    <circle cx="1430" cy="330" r="190" fill="#FFFDF8"/>
    <circle cx="1430" cy="330" r="118" fill="#E9C27C"/>
    <circle cx="1430" cy="330" r="58" fill="#F2C8B7"/>
  </g>

  <g opacity=".55" transform="translate(1120 380) rotate(-16)">
    <rect x="0" y="0" width="92" height="520" rx="44" fill="url(#metal)"/>
    <rect x="18" y="-65" width="56" height="92" rx="22" fill="#FFF8EA"/>
    <rect x="-12" y="155" width="116" height="128" rx="30" fill="#FFF7E8" fill-opacity=".76"/>
    <text x="46" y="223" text-anchor="middle" font-family="Georgia" font-size="30" font-weight="700" fill="#4D321B">Reza</text>
  </g>

  <g opacity=".48" transform="translate(1280 210) rotate(28)">
    <rect x="0" y="0" width="42" height="500" rx="21" fill="#F0AFA0"/>
    <circle cx="21" cy="-25" r="58" fill="#FFEBD8"/>
  </g>

  <g opacity=".36" transform="translate(1480 470) rotate(18)">
    <rect x="0" y="0" width="70" height="390" rx="35" fill="#E9B09F"/>
    <rect x="19" y="-55" width="32" height="75" rx="16" fill="#3D2A24"/>
  </g>

  <g opacity=".25">
    <path d="M-60 820C230 700 410 900 700 730C980 566 1180 500 1450 620C1620 696 1730 620 1870 520" stroke="#C9943D" stroke-width="35" stroke-linecap="round"/>
    <path d="M-90 920C240 760 490 980 790 820C1060 676 1240 645 1510 725C1680 775 1800 700 1910 630" stroke="#FFFFFF" stroke-width="18" stroke-linecap="round"/>
  </g>
</svg>
SVG

cat > frontend/assets/images/reza-card-bg.svg <<'SVG'
<svg width="1000" height="700" viewBox="0 0 1000 700" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="1000" height="700" rx="50" fill="#FFF4E3"/>
  <circle cx="760" cy="120" r="190" fill="#F3C8B8" fill-opacity=".45"/>
  <circle cx="280" cy="260" r="210" fill="#E8C98D" fill-opacity=".35"/>
  <ellipse cx="500" cy="580" rx="310" ry="55" fill="#7E5740" fill-opacity=".12"/>
  <rect x="430" y="160" width="125" height="310" rx="55" fill="#D9A756"/>
  <rect x="455" y="110" width="75" height="75" rx="24" fill="#FFF8EA"/>
  <rect x="385" y="265" width="215" height="112" rx="28" fill="#FFF9EF" fill-opacity=".86"/>
  <text x="492" y="328" text-anchor="middle" font-family="Georgia" font-size="44" font-weight="700" fill="#4D321B">Reza</text>
</svg>
SVG

cp frontend/assets/images/reza-soft-beauty-bg.svg admin/assets/images/reza-soft-beauty-bg.svg
cp frontend/assets/images/reza-card-bg.svg admin/assets/images/reza-card-bg.svg

# Admin root fix
cat > admin/index.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=login.html">
  <title>Reza Admin</title>
</head>
<body>
  <script>location.href = "login.html";</script>
  <p>Redirecting to admin login...</p>
</body>
</html>
HTML

cat >> frontend/css/app.css <<'CSS'

/* V11.3 — Premium Reza background images */
.hero {
  background:
    linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)),
    url("../assets/images/reza-soft-beauty-bg.svg") !important;
  background-size: cover !important;
  background-position: center !important;
}

.page-hero {
  background:
    linear-gradient(135deg, rgba(255,250,242,.78), rgba(243,223,206,.56)),
    url("../assets/images/reza-soft-beauty-bg.svg") !important;
  background-size: cover !important;
  background-position: center !important;
}

.product-img,
.hero-card-inner {
  background:
    radial-gradient(circle at center, rgba(255,255,255,.45), transparent 42%),
    url("../assets/images/reza-card-bg.svg") !important;
  background-size: cover !important;
  background-position: center !important;
}

.hero::after {
  content: "";
  position: absolute;
  right: -120px;
  bottom: -180px;
  width: 520px;
  height: 520px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(232,201,141,.38), transparent 68%);
  filter: blur(12px);
  pointer-events: none;
}

CSS

cat >> admin/css/admin.css <<'CSS'

/* V11.3 — Admin background image upgrade */
body {
  background:
    radial-gradient(circle at 15% 0%, rgba(232,201,141,.30), transparent 28%),
    url("../assets/images/reza-soft-beauty-bg.svg"),
    linear-gradient(135deg,#fffaf2,#f3dfce) !important;
  background-size: cover !important;
  background-position: center !important;
}

.card {
  background: rgba(255,255,255,.82) !important;
  backdrop-filter: blur(18px);
}

CSS

git add .
git commit -m "Add premium Reza background images and admin redirect"
git push
