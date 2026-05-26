#!/bin/bash
set -e

echo "✨ Making Reza frontend Shopify-style, faster and mobile friendly..."

mkdir -p frontend/assets/images

# Try to use the admin hero image if it exists, otherwise keep current fallback.
# If you have your exact hero image file, put it manually here:
# frontend/assets/images/reza-hero.jpg
if [ -f "frontend/assets/images/reza-live-hero.png" ]; then
  cp frontend/assets/images/reza-live-hero.png frontend/assets/images/reza-hero.png
elif [ -f "admin/assets/images/background.png" ]; then
  cp admin/assets/images/background.png frontend/assets/images/reza-hero.png
fi

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
    <section id="hero" class="hero-clean">
      <div class="hero-overlay"></div>
      <div class="hero-inner">
        <p class="eyebrow">PREMIUM SKINCARE & WELLNESS</p>
        <h1>Glow. Repair. Restore.</h1>
        <p class="hero-text">
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

    <section class="coming-section">
      <div class="section-title light">
        <p class="eyebrow">COMING SOON</p>
        <h2>New Reza products are coming soon</h2>
        <p>Get ready for more premium wellness and skincare products from Reza Holdings.</p>
      </div>

      <div class="coming-grid">
        <article>
          <img src="assets/images/reza-card-bg.svg" alt="Coming soon product" loading="lazy">
          <span>COMING SOON</span>
          <h3>Reza Sea Moss</h3>
          <p>Wildcrafted Irish sea moss for wellness and daily support.</p>
        </article>

        <article>
          <img src="assets/images/reza-card-bg.svg" alt="Coming soon product" loading="lazy">
          <span>COMING SOON</span>
          <h3>Reza Acne Care Collection</h3>
          <p>A luxury soap collection made for clearer, healthier-looking skin.</p>
        </article>

        <article>
          <img src="assets/images/reza-card-bg.svg" alt="Coming soon product" loading="lazy">
          <span>COMING SOON</span>
          <h3>Luxury Reza Marine Collagen</h3>
          <p>Premium beauty-from-within support for glow, repair and nourish.</p>
        </article>
      </div>
    </section>

    <section class="why-section">
      <div class="why-card">
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
    <p>© 2026 Reza Holdings. Powered by Reza.</p>
    <a href="policies.html">Terms and Policies</a>
  </footer>

  <script src="reza-live.js"></script>
  <script>
    const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

    function toggleMenu(){
      document.getElementById("mainNav").classList.toggle("open");
    }

    function money(v){
      return "R " + Number(v || 0).toLocaleString("en-ZA", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
    }

    function img(src){
      if(!src) return "assets/images/reza-card-bg.svg";
      if(src.startsWith("data:image")) return src;
      if(src.startsWith("http")) return src;
      if(src.startsWith("/")) return API + src;
      return src;
    }

    function updateCartCount(){
      const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
      const count = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);
      const badge = document.getElementById("cartCount");
      if(badge) badge.textContent = count;
    }

    function addToCart(product){
      const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
      const found = cart.find(item => item.id === product.id);
      if(found) found.qty += 1;
      else cart.push({...product, qty:1});
      localStorage.setItem("reza_cart", JSON.stringify(cart));
      updateCartCount();
      alert("Added to cart");
    }

    async function loadMedia(){
      try{
        const res = await fetch(API + "/api/media?t=" + Date.now());
        const data = await res.json();

        if(data.success && data.media){
          if(data.media.logoImage){
            document.querySelectorAll(".logo").forEach(el => {
              el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
            });
          }

          /* Fast local hero image first. Backend hero only if available and not too huge. */
          const hero = document.getElementById("hero");
          if(data.media.heroImage && !data.media.heroImage.startsWith("data:image")){
            hero.style.backgroundImage = `url("${img(data.media.heroImage)}")`;
          }
        }
      }catch(e){
        console.warn("Media failed", e);
      }
    }

    async function loadProducts(){
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
    loadMedia();
    loadProducts();
  </script>
</body>
</html>
HTML

cat > frontend/shop.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Catalog | Reza Holdings</title>
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
      <a href="index.html">Home</a>
      <a class="active" href="shop.html">Catalog</a>
      <a href="about.html">About</a>
      <a href="contact.html">Contact</a>
      <a href="policies.html">Policies</a>
    </nav>

    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section class="catalog-hero">
      <p class="eyebrow">CATALOG</p>
      <h1>Featured Products</h1>
      <p>Search, choose and add your favourite Reza products to cart.</p>
    </section>

    <section class="catalog-tools">
      <input id="search" placeholder="Search products...">
      <select id="category">
        <option value="">All products</option>
      </select>
    </section>

    <section id="productsGrid" class="product-grid catalog-grid">
      <div class="loading-card">Loading products...</div>
    </section>
  </main>

  <footer class="footer">
    <p>© 2026 Reza Holdings.</p>
    <a href="policies.html">Terms and Policies</a>
  </footer>

  <script src="reza-live.js"></script>
  <script>
    const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
    let allProducts = [];

    function toggleMenu(){
      document.getElementById("mainNav").classList.toggle("open");
    }

    function money(v){
      return "R " + Number(v || 0).toLocaleString("en-ZA", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
    }

    function img(src){
      if(!src) return "assets/images/reza-card-bg.svg";
      if(src.startsWith("data:image")) return src;
      if(src.startsWith("http")) return src;
      if(src.startsWith("/")) return API + src;
      return src;
    }

    function updateCartCount(){
      const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
      const count = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);
      const badge = document.getElementById("cartCount");
      if(badge) badge.textContent = count;
    }

    function addToCart(product){
      const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
      const found = cart.find(item => item.id === product.id);
      if(found) found.qty += 1;
      else cart.push({...product, qty:1});
      localStorage.setItem("reza_cart", JSON.stringify(cart));
      updateCartCount();
      alert("Added to cart");
    }

    function render(){
      const q = document.getElementById("search").value.toLowerCase();
      const c = document.getElementById("category").value;
      const grid = document.getElementById("productsGrid");

      const products = allProducts.filter(p =>
        p.showOnline !== false &&
        (!q || String(p.name).toLowerCase().includes(q) || String(p.description || "").toLowerCase().includes(q)) &&
        (!c || p.category === c)
      );

      if(!products.length){
        grid.innerHTML = `<div class="loading-card">No products found.</div>`;
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
            <p class="description">${p.description || ""}</p>
            <button onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>
          </div>
        </article>
      `).join("");
    }

    async function loadProducts(){
      const res = await fetch(API + "/api/products?t=" + Date.now());
      const data = await res.json();

      allProducts = data.products || [];

      const cats = [...new Set(allProducts.map(p => p.category).filter(Boolean))];
      document.getElementById("category").innerHTML =
        `<option value="">All products</option>` + cats.map(c => `<option>${c}</option>`).join("");

      render();
    }

    document.getElementById("search").addEventListener("input", render);
    document.getElementById("category").addEventListener("change", render);

    updateCartCount();
    loadProducts();
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
  font-weight: 800;
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 50;
  min-height: 78px;
  padding: 16px 9%;
  background: rgba(255, 250, 244, .94);
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

.hero-clean {
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

.hero-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    90deg,
    rgba(35, 28, 25, .18),
    rgba(35, 28, 25, .24)
  );
  z-index: -1;
}

.hero-inner {
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

.hero-clean .eyebrow {
  color: #f6ddb2;
}

.hero-clean h1 {
  font-family: Georgia, serif;
  font-size: clamp(3.6rem, 9vw, 7rem);
  line-height: .9;
  margin: 18px 0;
}

.hero-text {
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

.description {
  color: var(--muted);
  line-height: 1.55;
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

.coming-section {
  background: #322c29;
  padding: 75px 9%;
  color: #fff;
}

.section-title.light h2,
.section-title.light p {
  color: #fff;
}

.coming-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 26px;
}

.coming-grid article {
  background: rgba(255,255,255,.09);
  border: 1px solid rgba(255,255,255,.16);
  border-radius: 26px;
  overflow: hidden;
}

.coming-grid img {
  width: 100%;
  height: 270px;
  object-fit: cover;
  display: block;
}

.coming-grid span {
  display: inline-block;
  margin: 18px 22px 8px;
  background: var(--gold);
  color: var(--text);
  padding: 9px 16px;
  border-radius: 999px;
  font-weight: 900;
  letter-spacing: .12em;
  font-size: .72rem;
}

.coming-grid h3,
.coming-grid p {
  padding: 0 22px;
}

.coming-grid p {
  padding-bottom: 22px;
  color: rgba(255,255,255,.78);
  line-height: 1.55;
}

.why-section {
  padding: 85px 9%;
  background: var(--cream);
}

.why-card {
  max-width: 1050px;
  margin: auto;
  padding: 55px;
  background: rgba(255,255,255,.62);
  border: 1px solid var(--line);
  border-radius: 34px;
  text-align: center;
  box-shadow: var(--shadow);
}

.why-card h2 {
  font-family: Georgia, serif;
  font-size: clamp(2.4rem, 6vw, 4.4rem);
  line-height: 1;
  margin: 10px 0;
}

.why-card p {
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

.catalog-hero {
  padding: 70px 9% 35px;
  text-align: center;
}

.catalog-hero h1 {
  font-family: Georgia, serif;
  font-size: clamp(3.6rem, 8vw, 6.5rem);
  margin: 10px 0;
}

.catalog-tools {
  padding: 10px 9% 35px;
  display: grid;
  grid-template-columns: 1fr 280px;
  gap: 18px;
}

.catalog-tools input,
.catalog-tools select {
  padding: 17px 18px;
  border-radius: 16px;
  border: 1px solid var(--line);
  background: #fff;
  font-size: 1rem;
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
  .product-grid,
  .coming-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .hero-clean {
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

  .hero-clean {
    min-height: 560px;
    padding: 60px 18px;
    text-align: left;
    place-items: end start;
    background-position: center;
  }

  .hero-overlay {
    background: linear-gradient(
      0deg,
      rgba(35, 28, 25, .55),
      rgba(35, 28, 25, .10)
    );
  }

  .hero-inner {
    text-align: left;
    max-width: 100%;
  }

  .hero-clean h1 {
    font-size: clamp(3.3rem, 16vw, 5.2rem);
  }

  .hero-text {
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
  .coming-section,
  .why-section,
  .email-section,
  .catalog-hero,
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
  .catalog-hero h1 {
    font-size: 3rem;
  }

  .product-grid,
  .coming-grid {
    grid-template-columns: 1fr;
  }

  .product-image,
  .coming-grid img {
    height: 300px;
  }

  .catalog-tools {
    grid-template-columns: 1fr;
  }

  .why-card {
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
git commit -m "Make Reza frontend Shopify style fast and mobile friendly"
git push

echo "✅ Done. Redeploy reza-frontend only."
