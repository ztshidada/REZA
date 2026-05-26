#!/bin/bash
set -e

echo "Applying mirror-gold luxury patch..."

mkdir -p frontend/assets/css

cat > frontend/assets/css/mirror-gold-patch.css <<'CSS'
:root{
  --bg-ivory:#f8f1e8;
  --bg-soft:#f3e7d7;
  --text-dark:#2a1711;
  --text-soft:#6f5446;
  --gold-1:#fff2c9;
  --gold-2:#f6d98b;
  --gold-3:#d6a84d;
  --gold-4:#b98122;
  --gold-5:#fff8e8;
  --white-glass:rgba(255,255,255,0.72);
  --shadow-soft:0 12px 40px rgba(102,72,33,0.12);
}

/* overall */
body{
  background:
    radial-gradient(circle at top right, rgba(245,206,151,0.18), transparent 28%),
    radial-gradient(circle at bottom left, rgba(255,239,210,0.35), transparent 26%),
    linear-gradient(180deg, #fbf6ef 0%, #f7efe6 100%);
  color:var(--text-dark);
}

/* top strip / navbar */
.top-bar,
.top-strip,
.announcement-bar{
  background:linear-gradient(90deg,#ecd4ae,#f7ead7,#ecd4ae) !important;
  color:#5d3d1c !important;
  border-bottom:1px solid rgba(185,129,34,.18);
}

header,
.site-header,
.navbar,
.main-header{
  background:rgba(255,250,244,0.84) !important;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow:0 6px 24px rgba(77,49,21,0.06);
}

.nav-links,
.nav-menu,
.nav-pill,
.nav-center{
  background:rgba(255,255,255,0.72) !important;
  border:1px solid rgba(214,168,77,0.14);
  box-shadow:0 8px 28px rgba(109,80,39,0.07);
}

.nav-links a,
.nav-menu a,
nav a{
  color:#3e281d !important;
  font-weight:700;
}

.nav-links a.active,
.nav-menu a.active,
nav a.active,
nav a[aria-current="page"]{
  background:linear-gradient(135deg,#2f2019,#4e3326) !important;
  color:#fff7eb !important;
  border-radius:18px;
  box-shadow:0 8px 22px rgba(64,38,19,0.22);
}

/* hero area */
.hero,
.home-hero,
.hero-section,
.banner,
.page-hero{
  position:relative;
  overflow:hidden;
  isolation:isolate;
}

.hero::before,
.home-hero::before,
.hero-section::before,
.banner::before,
.page-hero::before{
  content:"";
  position:absolute;
  inset:0;
  background:
    linear-gradient(90deg, rgba(255,249,241,0.88) 0%, rgba(255,248,239,0.70) 38%, rgba(255,248,239,0.18) 100%);
  z-index:0;
}

.hero > *,
.home-hero > *,
.hero-section > *,
.banner > *,
.page-hero > *{
  position:relative;
  z-index:1;
}

/* gold mirror heading */
.hero h1,
.home-hero h1,
.hero-section h1,
.page-hero h1,
.hero-title,
.hero-copy h1{
  font-size:clamp(3.2rem, 7vw, 7rem) !important;
  line-height:0.92 !important;
  letter-spacing:-0.045em !important;
  max-width:10ch;
  margin-bottom:18px;
  background:
    linear-gradient(
      180deg,
      var(--gold-5) 0%,
      var(--gold-1) 10%,
      var(--gold-2) 24%,
      var(--gold-3) 46%,
      #8a5a12 58%,
      var(--gold-2) 72%,
      #fff3cf 84%,
      #a86f1d 100%
    ) !important;
  -webkit-background-clip:text !important;
  background-clip:text !important;
  color:transparent !important;
  text-shadow:
    0 1px 0 rgba(255,247,225,0.7),
    0 8px 22px rgba(145,102,34,0.16);
  filter: drop-shadow(0 4px 14px rgba(145,102,34,.12));
}

/* paragraph under hero */
.hero p,
.home-hero p,
.hero-section p,
.page-hero p,
.hero-copy p{
  color:#5f4a3b !important;
  font-size:clamp(1rem,1.8vw,1.35rem);
  line-height:1.65;
  max-width:700px;
  font-weight:600;
}

/* section titles */
.section-title,
section h2{
  color:#2e1c14;
  text-shadow:0 1px 0 rgba(255,255,255,.5);
}

/* chips */
.hero .chip,
.hero .tag,
.badge-chip,
.pill{
  background:rgba(255,255,255,.72) !important;
  border:1px solid rgba(214,168,77,0.16);
  color:#6a4a28 !important;
  box-shadow:0 8px 20px rgba(109,80,39,0.08);
}

/* buttons */
.btn-primary,
.primary-btn,
button.primary,
a.primary,
.cta-primary{
  background:linear-gradient(135deg,#f2d180,#d9a641) !important;
  color:#2d190e !important;
  border:none !important;
  box-shadow:0 10px 26px rgba(185,129,34,0.20);
}

.btn-primary:hover,
.primary-btn:hover,
button.primary:hover,
a.primary:hover,
.cta-primary:hover{
  transform:translateY(-1px);
  filter:brightness(1.03);
}

.btn-secondary,
.secondary-btn,
button.secondary,
a.secondary,
.cta-secondary{
  background:rgba(255,255,255,0.68) !important;
  color:#41291d !important;
  border:1px solid rgba(185,129,34,0.16) !important;
  box-shadow:0 8px 24px rgba(99,71,33,0.08);
}

/* cards */
.product-card,
.collection-card,
.info-card,
.feature-card{
  background:rgba(255,255,255,0.78) !important;
  border:1px solid rgba(214,168,77,0.12);
  box-shadow:var(--shadow-soft);
  border-radius:26px !important;
}

.product-card .price,
.price{
  color:#8d5c16 !important;
  font-weight:800;
}

.badge,
.product-badge{
  background:linear-gradient(135deg,#f0cf78,#d49f37) !important;
  color:#29180f !important;
  border:none !important;
}

/* cart bubble */
.cart-count,
.cart-badge{
  background:linear-gradient(135deg,#f4d68f,#d9a443) !important;
  color:#2f1d12 !important;
  box-shadow:0 6px 18px rgba(185,129,34,0.20);
}

/* if there is an image panel on right, keep it elegant */
.hero-visual,
.hero-media,
.hero-image-wrap{
  border-radius:28px;
  overflow:hidden;
  box-shadow:0 16px 46px rgba(100,71,35,0.13);
}

/* mobile */
@media (max-width: 900px){
  .hero h1,
  .home-hero h1,
  .hero-section h1,
  .page-hero h1,
  .hero-title,
  .hero-copy h1{
    max-width:100%;
    font-size:clamp(2.5rem, 12vw, 4.4rem) !important;
  }

  .hero p,
  .home-hero p,
  .hero-section p,
  .page-hero p,
  .hero-copy p{
    max-width:100%;
  }
}
CSS

python3 - <<'PY'
from pathlib import Path

targets = list(Path("frontend").glob("*.html")) + list(Path("frontend").glob("**/*.html"))

for p in targets:
    text = p.read_text(encoding="utf-8")
    if "mirror-gold-patch.css" not in text:
        text = text.replace(
            "</head>",
            '  <link rel="stylesheet" href="assets/css/mirror-gold-patch.css">\n</head>'
        )
        p.write_text(text, encoding="utf-8")
        print("Patched:", p)
PY

echo "Done."
