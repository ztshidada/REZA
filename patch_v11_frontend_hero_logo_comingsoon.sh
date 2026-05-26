#!/bin/bash
set -e

echo "✨ Fixing hero image, logo frontend save, and clean Coming Soon section..."

mkdir -p frontend/assets/images

# 1) Extract hero/logo from backend media.json if they were saved as base64
python3 - <<'PY'
from pathlib import Path
import json, base64, re

media_path = Path("backend/data/media.json")
assets = Path("frontend/assets/images")
assets.mkdir(parents=True, exist_ok=True)

hero_out = assets / "reza-hero.png"
logo_out = assets / "reza-logo.png"

def save_data_image(data_url, out_path):
    if not data_url or not data_url.startswith("data:image"):
        return False
    m = re.match(r"data:image/[^;]+;base64,(.*)", data_url)
    if not m:
        return False
    out_path.write_bytes(base64.b64decode(m.group(1)))
    return True

media = {}
if media_path.exists():
    try:
        media = json.loads(media_path.read_text())
    except Exception:
        media = {}

hero_saved = save_data_image(media.get("heroImage", ""), hero_out)
logo_saved = save_data_image(media.get("logoImage", ""), logo_out)

if hero_saved:
    print("✅ Extracted hero image to frontend/assets/images/reza-hero.png")
else:
    print("ℹ️ No base64 hero found locally. Existing reza-hero.png will be used if present.")

if logo_saved:
    print("✅ Extracted logo to frontend/assets/images/reza-logo.png")
else:
    print("ℹ️ No base64 logo found locally. Existing reza-logo.png will be used if present.")

# Update media defaults to fast frontend paths
media["heroImage"] = "assets/images/reza-hero.png"
if logo_out.exists():
    media["logoImage"] = "assets/images/reza-logo.png"
media["updatedAt"] = media.get("updatedAt") or ""

media_path.parent.mkdir(parents=True, exist_ok=True)
media_path.write_text(json.dumps(media, indent=2))
PY

# 2) If hero/logo still do not exist, create clean fallbacks
if [ ! -f frontend/assets/images/reza-hero.png ]; then
cat > frontend/assets/images/reza-hero.svg <<'SVG'
<svg width="1800" height="950" viewBox="0 0 1800 950" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1800" height="950" fill="#F8EEDC"/>
<radialGradient id="a" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(1400 250) rotate(120) scale(720 480)">
<stop stop-color="#E7C06F"/><stop offset="1" stop-color="#E7C06F" stop-opacity="0"/>
</radialGradient>
<radialGradient id="b" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(460 420) rotate(90) scale(520)">
<stop stop-color="#F3C6B6"/><stop offset="1" stop-color="#F3C6B6" stop-opacity="0"/>
</radialGradient>
<rect width="1800" height="950" fill="url(#a)"/>
<rect width="1800" height="950" fill="url(#b)"/>
<g opacity=".45">
<rect x="1050" y="270" width="170" height="430" rx="80" fill="#C9973D"/>
<rect x="1085" y="210" width="100" height="100" rx="34" fill="#FFF7EA"/>
<rect x="980" y="420" width="310" height="130" rx="35" fill="#FFF7EA" fill-opacity=".82"/>
<text x="1135" y="500" font-family="Georgia" font-size="70" font-weight="700" text-anchor="middle" fill="#2A201B">Reza</text>
</g>
<text x="180" y="280" font-family="Georgia" font-size="118" font-weight="700" fill="#2A201B">Glow. Repair.</text>
<text x="180" y="410" font-family="Georgia" font-size="118" font-weight="700" fill="#2A201B">Restore.</text>
</svg>
SVG
fi

# 3) Replace homepage with clean version including Coming Soon
cat > frontend/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Reza Holdings | Champagne Luxury</title>
  <link rel="preload" as="image" href="assets/images/reza-hero.png">
  <link rel="stylesheet" href="reza-style.css">
</head>

<body>
  <div class="announcement">WELCOME TO OUR STORE</div>

  <header class="site-header">
    <a class="brand" href="index.html">
      <span class="logo">R</span>
      <span><b>Reza Holdings</b><small>Champagne Luxury</small></span>
    </a>

    <button class="menu-btn" onclick="toggleMenu()">☰</button>

    <nav id="mainNav" class="nav-links">
      <a class="active" href="index.html">Home</a>
      <a href="shop.html">Catalog</a>
      <a href="about.html">About</a>
      <a href="contact.html">Contact</a>
      <a href="policies.html">Policies</a>
    </nav>

    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section id="hero" class="hero-shopify">
      <div class="hero-shade"></div>
      <div class="hero-content">
        <p class="eyebrow">PREMIUM SKINCARE & WELLNESS</p>
        <h1>Glow. Repair. Restore.</h1>
        <p>Premium skincare made for soft, healthy-looking, glowing skin.</p>
        <div class="hero-actions">
          <a class="btn primary" href="shop.html">Shop Products</a>
          <a class="btn glass" href="contact.html">Contact Us</a>
        </div>
      </div>
    </section>

    <section class="featured-section">
      <div class="section-title">
        <p class="eyebrow">REZA HOLDINGS</p>
        <h2>Featured Products</h2>
      </div>
      <div id="featuredGrid" class="product-grid">
        <div class="loading-card">Loading products...</div>
      </div>
    </section>

    <section class="coming-section">
      <div class="section-title light">
        <p class="eyebrow">COMING SOON</p>
        <h2>New Reza products are coming soon</h2>
        <p>Get ready for more premium wellness and skincare products from Reza Holdings.</p>
      </div>

      <div class="coming-grid">
        <article class="coming-card">
          <img src="assets/images/reza-card-bg.svg" alt="Reza Sea Moss" loading="lazy">
          <span>COMING SOON</span>
          <h3>Reza Sea Moss</h3>
          <p>Wildcrafted Irish sea moss for wellness and daily support.</p>
        </article>

        <article class="coming-card">
          <img src="assets/images/reza-card-bg.svg" alt="Reza Acne Care Collection" loading="lazy">
          <span>COMING SOON</span>
          <h3>Reza Acne Care Collection</h3>
          <p>A luxury soap collection made for clearer, healthier-looking skin.</p>
        </article>

        <article class="coming-card">
          <img src="assets/images/reza-card-bg.svg" alt="Luxury Reza Marine Collagen" loading="lazy">
          <span>COMING SOON</span>
          <h3>Luxury Reza Marine Collagen</h3>
          <p>Premium beauty-from-within support for glow, repair and nourish.</p>
        </article>
      </div>
    </section>

    <section class="promo-section">
      <div class="promo-card">
        <p class="eyebrow">WHY REZA HOLDINGS?</p>
        <h2>Luxury care for real skin confidence.</h2>
        <p>Our products are created for customers who want a premium, beautiful and simple skincare experience.</p>
      </div>
    </section>

    <section class="email-section">
      <div>
        <h2>Join our email list</h2>
        <p>Get exclusive deals and early access to new products.</p>
      </div>
      <form onsubmit="event.preventDefault(); alert('Thank you for joining Reza updates.');">
        <input type="email" required placeholder="Email address">
        <button>→</button>
      </form>
    </section>
  </main>

  <footer class="footer">
    <p>© 2026 Reza Holdings.</p>
    <a href="policies.html">Terms and Policies</a>
  </footer>

  <script src="site.js"></script>
  <script>
    async function loadHomeMedia(){
      try{
        const hero = document.getElementById("hero");

        // Fast frontend image first
        hero.style.backgroundImage = `url("assets/images/reza-hero.png"), url("assets/images/reza-hero.svg")`;

        const logoFile = "assets/images/reza-logo.png";
        fetch(logoFile, { method: "HEAD" }).then(res => {
          if(res.ok){
            document.querySelectorAll(".logo").forEach(el => {
              el.innerHTML = `<img src="${logoFile}" alt="Reza Logo">`;
            });
          }
        }).catch(()=>{});

        // Backend can still override logo only; avoid heavy base64 hero
        const res = await fetch(API + "/api/media?t=" + Date.now());
        const data = await res.json();

        if(data.success && data.media && data.media.logoImage){
          document.querySelectorAll(".logo").forEach(el => {
            el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
          });
        }
      }catch(e){
        console.warn("Media not loaded", e);
      }
    }

    async function loadFeaturedProducts(){
      const grid = document.getElementById("featuredGrid");
      try{
        const res = await fetch(API + "/api/products?t=" + Date.now());
        const data = await res.json();
        const products = (data.products || []).filter(p => p.showOnline !== false).slice(0, 4);

        if(!products.length){
          grid.innerHTML = `<div class="loading-card">No products yet. Add products from admin.</div>`;
          return;
        }

        grid.innerHTML = products.map(p => `
          <article class="product-card">
            <div class="product-image">
              ${p.badge ? `<span class="product-badge">${p.badge}</span>` : ""}
              <img src="${img(p.image)}" alt="${p.name}" loading="lazy">
            </div>
            <div class="product-body">
              <p class="category">${p.category || "Reza Holdings"}</p>
              <h3>${p.name}</h3>
              <p class="price">${money(p.price)}</p>
              <button onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>
            </div>
          </article>
        `).join("");
      }catch(e){
        grid.innerHTML = `<div class="loading-card">Could not load products.</div>`;
      }
    }

    updateCartCount();
    loadHomeMedia();
    loadFeaturedProducts();
  </script>
</body>
</html>
HTML

# 4) Add/replace coming soon CSS and fix local hero
cat >> frontend/reza-style.css <<'CSS'

/* V11 final hero/logo frontend assets */
.hero-shopify {
  background-image: url("assets/images/reza-hero.png"), url("assets/images/reza-hero.svg") !important;
}

.coming-section {
  background: #332c28;
  padding: 75px 9%;
  color: #fff;
}

.section-title.light h2,
.section-title.light p {
  color: #fff;
}

.coming-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0,1fr));
  gap: 26px;
}

.coming-card {
  background: rgba(255,255,255,.09);
  border: 1px solid rgba(255,255,255,.15);
  border-radius: 28px;
  overflow: hidden;
  box-shadow: 0 24px 70px rgba(0,0,0,.18);
}

.coming-card img {
  width: 100%;
  height: 270px;
  object-fit: cover;
  display: block;
}

.coming-card span {
  display: inline-block;
  margin: 18px 22px 8px;
  padding: 9px 15px;
  border-radius: 999px;
  background: var(--gold);
  color: var(--text);
  font-size: .72rem;
  font-weight: 1000;
  letter-spacing: .15em;
}

.coming-card h3 {
  padding: 0 22px;
  margin: 8px 0;
  color: #fff;
}

.coming-card p {
  padding: 0 22px 24px;
  color: rgba(255,255,255,.78);
  line-height: 1.6;
}

@media(max-width: 900px) {
  .coming-grid {
    grid-template-columns: 1fr;
  }

  .coming-card img {
    height: 260px;
  }
}
CSS

git add .
git commit -m "Add coming soon and save hero logo as frontend assets"
git push

echo "✅ Done. Redeploy reza-frontend and reza-backend."
