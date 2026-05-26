#!/bin/bash
set -e

echo "Removing mirror-gold patch and restoring mobile layout..."

# 1. Remove the mirror-gold CSS link from all frontend HTML pages
python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")
    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/mirror-gold-patch\.css">\s*', '\n', text)
    text = re.sub(r'\s*<link rel="stylesheet" href="css/mirror-gold-patch\.css">\s*', '\n', text)
    p.write_text(text, encoding="utf-8")
    print("Cleaned:", p)
PY

# 2. Keep the file but disable it in case it is cached somewhere
mkdir -p frontend/assets/css
cat > frontend/assets/css/mirror-gold-patch.css <<'CSS'
/* Disabled. Keeping file only to avoid old browser/cache errors. */
CSS

# 3. Add strong mobile repair CSS
cat >> frontend/css/app.css <<'CSS'

/* V11 MOBILE RESTORE — phone-friendly layout */
html, body {
  max-width: 100%;
  overflow-x: hidden !important;
}

img {
  max-width: 100%;
  height: auto;
}

.header,
.site-header,
.navbar,
.main-header {
  width: 100%;
}

.hero,
.home-hero,
.hero-section,
.page-hero {
  min-height: auto !important;
  padding: 90px 18px 70px !important;
  overflow: hidden !important;
}

.hero .container,
.home-hero .container,
.hero-section .container,
.page-hero .container,
.container {
  width: min(100% - 32px, 1180px) !important;
  margin-inline: auto !important;
}

.hero-grid,
.home-grid,
.hero-content,
.hero-inner {
  display: grid !important;
  grid-template-columns: 1fr !important;
  gap: 24px !important;
  width: 100% !important;
}

.hero h1,
.home-hero h1,
.hero-section h1,
.page-hero h1,
.hero-title,
.hero-copy h1 {
  font-size: clamp(3rem, 15vw, 5.2rem) !important;
  line-height: .9 !important;
  letter-spacing: -0.05em !important;
  max-width: 100% !important;
  word-break: normal !important;
  overflow-wrap: normal !important;
}

.hero p,
.home-hero p,
.hero-section p,
.page-hero p,
.hero-copy p {
  font-size: 1rem !important;
  line-height: 1.55 !important;
  max-width: 100% !important;
}

.hero-actions,
.actions,
.cta-row {
  display: flex !important;
  flex-wrap: wrap !important;
  gap: 10px !important;
}

.hero-actions .btn,
.actions .btn,
.cta-row .btn,
button,
.btn {
  max-width: 100%;
}

/* Products/cart grids must stack nicely on phones */
.products-grid,
.product-grid,
#productsGrid,
#productGrid,
#featuredProducts,
.featured-products {
  display: grid !important;
  grid-template-columns: 1fr !important;
  gap: 18px !important;
}

.product-card {
  width: 100% !important;
  max-width: 100% !important;
}

.product-img img,
.product-card img {
  height: auto !important;
  max-height: 320px !important;
  object-fit: cover !important;
}

/* Cart / checkout */
.cart-layout,
.checkout-layout,
.cart-grid,
.checkout-grid {
  display: grid !important;
  grid-template-columns: 1fr !important;
  gap: 18px !important;
}

.cart-item {
  display: grid !important;
  grid-template-columns: 90px 1fr !important;
  gap: 12px !important;
  align-items: center !important;
}

.cart-item img {
  width: 90px !important;
  height: 90px !important;
  object-fit: cover !important;
  border-radius: 16px !important;
}

/* Nav phone repair */
@media (max-width: 760px) {
  .top-bar,
  .top-strip,
  .announcement-bar {
    font-size: .72rem !important;
    letter-spacing: .18em !important;
    text-align: center !important;
    padding: 8px 12px !important;
  }

  header,
  .site-header,
  .navbar,
  .main-header {
    padding: 12px 14px !important;
  }

  .brand,
  .logo-wrap,
  .site-brand {
    transform: scale(.9);
    transform-origin: left center;
  }

  nav,
  .nav-links,
  .nav-menu,
  .nav-center {
    display: flex !important;
    overflow-x: auto !important;
    white-space: nowrap !important;
    gap: 8px !important;
    max-width: 100% !important;
    padding: 8px !important;
    border-radius: 999px !important;
  }

  nav a,
  .nav-links a,
  .nav-menu a {
    flex: 0 0 auto !important;
    padding: 10px 14px !important;
    font-size: .9rem !important;
  }

  .hero,
  .home-hero,
  .hero-section,
  .page-hero {
    padding-top: 70px !important;
    background-position: center !important;
  }

  .hero h1,
  .home-hero h1,
  .hero-section h1,
  .page-hero h1,
  .hero-title,
  .hero-copy h1 {
    font-size: clamp(2.8rem, 17vw, 4.4rem) !important;
  }

  .hero-visual,
  .hero-media,
  .hero-card,
  .hero-image-wrap {
    width: 100% !important;
    max-width: 100% !important;
  }

  .page-section,
  section {
    padding-left: 18px !important;
    padding-right: 18px !important;
  }
}

@media (max-width: 430px) {
  .hero h1,
  .home-hero h1,
  .hero-section h1,
  .page-hero h1,
  .hero-title,
  .hero-copy h1 {
    font-size: clamp(2.4rem, 16vw, 3.7rem) !important;
  }

  .hero-actions .btn,
  .actions .btn,
  .cta-row .btn {
    width: 100% !important;
    text-align: center !important;
    justify-content: center !important;
  }

  .cart-item {
    grid-template-columns: 72px 1fr !important;
  }

  .cart-item img {
    width: 72px !important;
    height: 72px !important;
  }
}
CSS

git add .
git commit -m "Restore phone-friendly layout and remove mirror gold patch"
git push

echo "Done. Redeploy frontend on Render."
