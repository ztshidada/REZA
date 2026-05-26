#!/bin/bash
set -e

echo "✨ Cleaning Reza homepage into Shopify-style mobile luxury layout..."

cat > frontend/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Reza Holdings | Champagne Luxury</title>
  <link rel="stylesheet" href="reza-style.css">
</head>

<body>
  <div class="announcement">WELCOME TO OUR STORE</div>

  <header class="site-header">
    <a class="brand" href="index.html">
      <span class="logo">R</span>
      <span>
        <b>Reza Holdings</b>
        <small>Champagne Luxury</small>
      </span>
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
        <p>
          Premium skincare made for soft, healthy-looking, glowing skin.
        </p>

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

    <section class="promo-section">
      <div class="promo-card">
        <p class="eyebrow">WHY REZA HOLDINGS?</p>
        <h2>Luxury care for real skin confidence.</h2>
        <p>
          Our products are created for customers who want a premium, beautiful and simple skincare experience.
          Shop with confidence and give your skin the care it deserves.
        </p>
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
        const res = await fetch(API + "/api/media?t=" + Date.now());
        const data = await res.json();

        if(data.success && data.media){
          if(data.media.logoImage){
            document.querySelectorAll(".logo").forEach(el => {
              el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
            });
          }

          const hero = document.getElementById("hero");
          if(data.media.heroImage && !data.media.heroImage.startsWith("data:image")){
            hero.style.backgroundImage = `url("${img(data.media.heroImage)}")`;
          }
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

        const products = (data.products || [])
          .filter(p => p.showOnline !== false)
          .slice(0, 4);

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

cat > frontend/reza-style.css <<'CSS'
* {
  box-sizing: border-box;
}

:root {
  --cream: #f8f1e8;
  --cream2: #fffaf4;
  --text: #2a201b;
  --muted: #6f6259;
  --gold: #c89a3f;
  --gold2: #e8c77a;
  --line: rgba(43, 32, 27, .10);
  --shadow: 0 20px 60px rgba(60, 42, 25, .10);
}

body {
  margin: 0;
  font-family: Arial, sans-serif;
  color: var(--text);
  background: var(--cream);
}

a {
  color: inherit;
  text-decoration: none;
}

.announcement {
  text-align: center;
  padding: 10px 16px;
  background: #f1d9ae;
  font-size: .78rem;
  letter-spacing: .2em;
  font-weight: 900;
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 50;
  min-height: 78px;
  padding: 16px 9%;
  background: rgba(255, 250, 244, .96);
  backdrop-filter: blur(18px);
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  border-bottom: 1px solid var(--line);
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 13px;
  font-weight: 900;
}

.brand small {
  display: block;
  margin-top: 3px;
  color: #9a6d27;
  text-transform: uppercase;
  letter-spacing: .22em;
  font-size: .68rem;
}

.logo {
  width: 54px;
  height: 54px;
  border-radius: 18px;
  background: #fff1c9;
  display: grid;
  place-items: center;
  font-weight: 900;
  font-family: Georgia, serif;
  font-size: 1.3rem;
  overflow: hidden;
}

.logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.nav-links {
  display: flex;
  gap: 8px;
  padding: 8px;
  background: #fff;
  border-radius: 999px;
  box-shadow: 0 10px 35px rgba(50, 35, 20, .06);
}

.nav-links a {
  padding: 12px 22px;
  border-radius: 999px;
  font-weight: 800;
}

.nav-links a.active {
  background: var(--text);
  color: #fff;
}

.cart-btn {
  justify-self: end;
  display: inline-flex;
  gap: 8px;
  align-items: center;
  padding: 14px 24px;
  border-radius: 999px;
  background: var(--gold2);
  font-weight: 900;
}

.menu-btn {
  display: none;
  border: 0;
  background: #fff;
  width: 48px;
  height: 48px;
  border-radius: 16px;
  font-size: 1.3rem;
}

.hero-shopify {
  position: relative;
  min-height: 680px;
  display: grid;
  place-items: center;
  text-align: center;
  padding: 90px 9%;
  background-image: url("assets/images/reza-hero.png");
  background-size: cover;
  background-position: center;
  isolation: isolate;
}

.hero-shade {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    rgba(35, 28, 25, .22),
    rgba(35, 28, 25, .30)
  );
  z-index: -1;
}

.hero-content {
  max-width: 850px;
  color: #fff;
  text-shadow: 0 10px 25px rgba(0,0,0,.25);
}

.eyebrow {
  color: var(--gold);
  font-weight: 900;
  letter-spacing: .28em;
  font-size: .78rem;
  text-transform: uppercase;
}

.hero-shopify .eyebrow {
  color: #f6ddb2;
}

.hero-shopify h1 {
  font-family: Georgia, serif;
  font-size: clamp(3.6rem, 9vw, 7rem);
  line-height: .9;
  margin: 18px 0;
}

.hero-shopify p {
  font-size: 1.25rem;
  line-height: 1.7;
  max-width: 760px;
  margin: 0 auto 28px;
}

.hero-actions {
  display: flex;
  justify-content: center;
  gap: 14px;
  flex-wrap: wrap;
}

.btn {
  border: 0;
  border-radius: 999px;
  padding: 15px 28px;
  font-weight: 900;
  cursor: pointer;
  display: inline-flex;
  justify-content: center;
}

.primary {
  background: linear-gradient(135deg, var(--gold2), var(--gold));
  color: var(--text);
}

.glass {
  color: #fff;
  border: 1px solid rgba(255,255,255,.55);
  background: rgba(255,255,255,.08);
}

.featured-section {
  padding: 75px 9%;
  background: var(--cream2);
}

.section-title {
  text-align: center;
  margin-bottom: 40px;
}

.section-title h2 {
  font-family: Georgia, serif;
  font-size: clamp(3rem, 7vw, 5rem);
  margin: 12px 0 0;
}

.product-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 28px;
}

.product-card {
  background: #fff;
  border-radius: 28px;
  overflow: hidden;
  box-shadow: var(--shadow);
  border: 1px solid var(--line);
  transition: transform .3s ease, box-shadow .3s ease;
  animation: floatCard 4.8s ease-in-out infinite;
}

.product-card:nth-child(2) {
  animation-delay: .25s;
}

.product-card:nth-child(3) {
  animation-delay: .5s;
}

.product-card:nth-child(4) {
  animation-delay: .75s;
}

@keyframes floatCard {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-7px); }
}

.product-card:hover {
  transform: translateY(-14px) scale(1.02);
  box-shadow: 0 30px 80px rgba(60, 42, 25, .18);
}

.product-image {
  position: relative;
  height: 270px;
  background: #f4e7d3;
  overflow: hidden;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform .45s ease;
}

.product-card:hover .product-image img {
  transform: scale(1.06);
}

.product-badge {
  position: absolute;
  left: 15px;
  top: 15px;
  z-index: 2;
  background: var(--gold);
  color: var(--text);
  padding: 9px 14px;
  border-radius: 999px;
  font-size: .78rem;
  font-weight: 900;
}

.product-body {
  padding: 22px;
}

.product-body h3 {
  margin: 0 0 12px;
  font-size: 1.3rem;
  line-height: 1.25;
}

.price {
  color: #9b6b25;
  font-weight: 900;
  font-size: 1.1rem;
}

.category {
  text-transform: uppercase;
  color: #a36d20;
  letter-spacing: .12em;
  font-size: .72rem;
  font-weight: 900;
}

.product-body button {
  width: 100%;
  border: 0;
  border-radius: 999px;
  padding: 14px 18px;
  background: var(--text);
  color: #fff;
  font-weight: 900;
  cursor: pointer;
}

.promo-section {
  padding: 85px 9%;
  background: var(--cream);
}

.promo-card {
  max-width: 1050px;
  margin: auto;
  padding: 55px;
  background: rgba(255,255,255,.68);
  border: 1px solid var(--line);
  border-radius: 34px;
  text-align: center;
  box-shadow: var(--shadow);
}

.promo-card h2 {
  font-family: Georgia, serif;
  font-size: clamp(2.4rem, 6vw, 4.4rem);
  line-height: 1;
  margin: 10px 0;
}

.promo-card p {
  color: var(--muted);
  font-size: 1.1rem;
  line-height: 1.7;
}

.email-section {
  display: grid;
  grid-template-columns: 1fr 1.2fr;
  gap: 24px;
  align-items: center;
  padding: 45px 9%;
  background: #fff;
}

.email-section h2 {
  margin: 0;
}

.email-section p {
  color: var(--muted);
}

.email-section form {
  display: flex;
  border: 1px solid var(--line);
  border-radius: 999px;
  overflow: hidden;
  background: #fff;
}

.email-section input {
  flex: 1;
  border: 0;
  padding: 18px 22px;
  font-size: 1rem;
}

.email-section button {
  width: 70px;
  border: 0;
  background: transparent;
  font-size: 1.6rem;
  cursor: pointer;
}

.page-hero {
  padding: 90px 9% 60px;
  text-align: center;
  background: radial-gradient(circle at 80% 20%, rgba(244,199,184,.30), transparent 28%), var(--cream2);
}

.page-hero h1 {
  font-family: Georgia, serif;
  font-size: clamp(3.4rem, 8vw, 6.6rem);
  line-height: .95;
  margin: 12px 0;
}

.page-hero p {
  max-width: 850px;
  margin: auto;
  color: var(--muted);
  font-size: 1.18rem;
  line-height: 1.7;
}

.section {
  padding: 75px 9%;
  background: var(--cream2);
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit,minmax(280px,1fr));
  gap: 28px;
}

.card {
  background: #fff;
  border-radius: 28px;
  padding: 30px;
  box-shadow: var(--shadow);
  border: 1px solid var(--line);
}

.card p,
.card li {
  color: var(--muted);
  line-height: 1.7;
}

.catalog-tools {
  padding: 10px 9% 35px;
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 18px;
}

.catalog-tools input,
.catalog-tools select,
.input,
textarea {
  padding: 17px 18px;
  border-radius: 16px;
  border: 1px solid var(--line);
  background: #fff;
  font-size: 1rem;
  width: 100%;
}

textarea {
  min-height: 150px;
}

.catalog-grid {
  padding: 0 9% 80px;
}

.loading-card {
  grid-column: 1 / -1;
  padding: 30px;
  background: #fff;
  border-radius: 22px;
  text-align: center;
  font-weight: 900;
}

.footer {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  padding: 35px 9%;
  background: var(--cream2);
  color: var(--muted);
  border-top: 1px solid var(--line);
}

@media (max-width: 1050px) {
  .product-grid {
    grid-template-columns: repeat(2, minmax(0,1fr));
  }

  .hero-shopify {
    min-height: 600px;
  }
}

@media (max-width: 720px) {
  .announcement {
    font-size: .68rem;
    letter-spacing: .16em;
  }

  .site-header {
    grid-template-columns: 1fr auto auto;
    padding: 12px 16px;
    min-height: 70px;
  }

  .brand b {
    font-size: .95rem;
  }

  .brand small {
    font-size: .55rem;
    letter-spacing: .16em;
  }

  .logo {
    width: 46px;
    height: 46px;
    border-radius: 15px;
  }

  .menu-btn {
    display: block;
    justify-self: end;
  }

  .nav-links {
    position: fixed;
    top: 74px;
    left: 12px;
    right: 12px;
    display: none;
    flex-direction: column;
    border-radius: 22px;
    box-shadow: 0 25px 65px rgba(0,0,0,.18);
  }

  .nav-links.open {
    display: flex;
  }

  .cart-btn {
    padding: 12px 14px;
    font-size: .9rem;
  }

  .hero-shopify {
    min-height: 560px;
    padding: 60px 18px;
    text-align: left;
    place-items: end start;
    background-position: center;
  }

  .hero-shade {
    background: linear-gradient(
      0deg,
      rgba(35, 28, 25, .58),
      rgba(35, 28, 25, .10)
    );
  }

  .hero-content {
    text-align: left;
    max-width: 100%;
  }

  .hero-shopify h1 {
    font-size: clamp(3.3rem, 16vw, 5.2rem);
  }

  .hero-shopify p {
    font-size: 1rem;
    line-height: 1.55;
  }

  .hero-actions {
    justify-content: flex-start;
  }

  .btn,
  .hero-actions a {
    width: 100%;
    text-align: center;
  }

  .featured-section,
  .promo-section,
  .email-section,
  .page-hero,
  .section,
  .catalog-tools,
  .catalog-grid,
  .footer {
    padding-left: 16px;
    padding-right: 16px;
  }

  .section-title {
    text-align: left;
  }

  .section-title h2,
  .page-hero h1 {
    font-size: 3rem;
  }

  .product-grid {
    grid-template-columns: 1fr;
  }

  .product-image {
    height: 300px;
  }

  .promo-card {
    padding: 28px 20px;
    text-align: left;
  }

  .email-section {
    grid-template-columns: 1fr;
  }

  .email-section form {
    border-radius: 18px;
  }

  .footer {
    flex-direction: column;
  }
}
CSS

git add .
git commit -m "Clean homepage layout and fix mobile Shopify style"
git push

echo "✅ Done. Redeploy reza-frontend only."
