#!/bin/bash
set -e

echo "Fixing all customer pages with Shopify-style design..."

mkdir -p frontend/assets/images

cat > frontend/reza-style.css <<'CSS'
*{box-sizing:border-box}
:root{--cream:#f8f1e8;--cream2:#fffaf4;--text:#2a201b;--muted:#6f6259;--gold:#c89a3f;--gold2:#e8c77a;--line:rgba(43,32,27,.10);--shadow:0 20px 60px rgba(60,42,25,.10)}
body{margin:0;font-family:Arial,sans-serif;color:var(--text);background:var(--cream)}
a{text-decoration:none;color:inherit}
.announcement{text-align:center;padding:10px 16px;background:#f1d9ae;font-size:.78rem;letter-spacing:.2em;font-weight:900}
.site-header{position:sticky;top:0;z-index:50;min-height:78px;padding:16px 9%;background:rgba(255,250,244,.94);backdrop-filter:blur(18px);display:grid;grid-template-columns:1fr auto 1fr;align-items:center;border-bottom:1px solid var(--line)}
.brand{display:inline-flex;align-items:center;gap:13px;font-weight:900}
.brand small{display:block;margin-top:3px;color:#9a6d27;text-transform:uppercase;letter-spacing:.22em;font-size:.68rem}
.logo{width:54px;height:54px;border-radius:18px;background:#fff1c9;display:grid;place-items:center;font-weight:900;font-family:Georgia,serif;font-size:1.3rem;overflow:hidden}
.logo img{width:100%;height:100%;object-fit:cover}
.nav-links{display:flex;gap:8px;padding:8px;background:#fff;border-radius:999px;box-shadow:0 10px 35px rgba(50,35,20,.06)}
.nav-links a{padding:12px 22px;border-radius:999px;font-weight:800}
.nav-links a.active{background:var(--text);color:#fff}
.cart-btn{justify-self:end;display:inline-flex;gap:8px;align-items:center;padding:14px 24px;border-radius:999px;background:var(--gold2);font-weight:900}
.menu-btn{display:none;border:0;background:#fff;width:48px;height:48px;border-radius:16px;font-size:1.3rem}
.hero-clean{position:relative;min-height:680px;display:grid;place-items:center;text-align:center;padding:90px 9%;background-image:url("assets/images/reza-hero.png");background-size:cover;background-position:center;isolation:isolate}
.hero-overlay{position:absolute;inset:0;background:linear-gradient(90deg,rgba(35,28,25,.18),rgba(35,28,25,.24));z-index:-1}
.hero-inner{max-width:850px;color:#fff;text-shadow:0 10px 25px rgba(0,0,0,.25)}
.eyebrow{color:var(--gold);font-weight:900;letter-spacing:.28em;font-size:.78rem;text-transform:uppercase}
.hero-clean .eyebrow{color:#f6ddb2}
.hero-clean h1{font-family:Georgia,serif;font-size:clamp(3.6rem,9vw,7rem);line-height:.9;margin:18px 0}
.hero-text{font-size:1.25rem;line-height:1.7;max-width:760px;margin:0 auto 28px}
.hero-actions{display:flex;justify-content:center;gap:14px;flex-wrap:wrap}
.btn{border:0;border-radius:999px;padding:15px 28px;font-weight:900;cursor:pointer;display:inline-flex;justify-content:center}
.primary{background:linear-gradient(135deg,var(--gold2),var(--gold));color:var(--text)}
.glass{color:#fff;border:1px solid rgba(255,255,255,.55);background:rgba(255,255,255,.08)}
.page-hero{padding:90px 9% 60px;text-align:center;background:radial-gradient(circle at 80% 20%,rgba(244,199,184,.30),transparent 28%),var(--cream2)}
.page-hero h1{font-family:Georgia,serif;font-size:clamp(3.4rem,8vw,6.6rem);line-height:.95;margin:12px 0}
.page-hero p{max-width:850px;margin:auto;color:var(--muted);font-size:1.18rem;line-height:1.7}
.section{padding:75px 9%;background:var(--cream2)}
.section.alt{background:var(--cream)}
.section-title{text-align:center;margin-bottom:40px}
.section-title h2{font-family:Georgia,serif;font-size:clamp(3rem,7vw,5rem);margin:12px 0 0}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:28px}
.card{background:#fff;border-radius:28px;padding:30px;box-shadow:var(--shadow);border:1px solid var(--line)}
.card h2,.card h3{margin-top:0}
.card p,.card li{color:var(--muted);line-height:1.7}
.product-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:28px}
.product-card{background:#fff;border-radius:28px;overflow:hidden;box-shadow:var(--shadow);border:1px solid var(--line);transition:transform .3s ease,box-shadow .3s ease;animation:floatCard 4.8s ease-in-out infinite}
.product-card:nth-child(2){animation-delay:.25s}.product-card:nth-child(3){animation-delay:.5s}.product-card:nth-child(4){animation-delay:.75s}
@keyframes floatCard{0%,100%{transform:translateY(0)}50%{transform:translateY(-7px)}}
.product-card:hover{transform:translateY(-14px) scale(1.02);box-shadow:0 30px 80px rgba(60,42,25,.18)}
.product-image{position:relative;height:270px;background:#f4e7d3;overflow:hidden}
.product-image img{width:100%;height:100%;object-fit:cover;transition:transform .45s ease}
.product-card:hover .product-image img{transform:scale(1.06)}
.product-badge{position:absolute;left:15px;top:15px;z-index:2;background:var(--gold);color:var(--text);padding:9px 14px;border-radius:999px;font-size:.78rem;font-weight:900}
.product-body{padding:22px}.product-body h3{margin:0 0 12px;font-size:1.3rem;line-height:1.25}
.price{color:#9b6b25;font-weight:900;font-size:1.1rem}.category{text-transform:uppercase;color:#a36d20;letter-spacing:.12em;font-size:.72rem;font-weight:900}.description{color:var(--muted);line-height:1.55}
.product-body button{width:100%;border:0;border-radius:999px;padding:14px 18px;background:var(--text);color:#fff;font-weight:900;cursor:pointer}
.catalog-tools{padding:10px 9% 35px;display:grid;grid-template-columns:1fr 280px;gap:18px}
.catalog-tools input,.catalog-tools select,.input,textarea{padding:17px 18px;border-radius:16px;border:1px solid var(--line);background:#fff;font-size:1rem;width:100%}
textarea{min-height:150px}
.catalog-grid{padding:0 9% 80px}
.loading-card{grid-column:1/-1;padding:30px;background:#fff;border-radius:22px;text-align:center;font-weight:900}
.email-section{display:grid;grid-template-columns:1fr 1.2fr;gap:24px;align-items:center;padding:45px 9%;background:#fff}
.email-section form{display:flex;border:1px solid var(--line);border-radius:999px;overflow:hidden;background:#fff}
.email-section input{flex:1;border:0;padding:18px 22px;font-size:1rem}.email-section button{width:70px;border:0;background:transparent;font-size:1.6rem;cursor:pointer}
.footer{display:flex;justify-content:space-between;gap:20px;padding:35px 9%;background:var(--cream2);color:var(--muted);border-top:1px solid var(--line)}
@media(max-width:1050px){.product-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.hero-clean{min-height:600px}}
@media(max-width:720px){
.announcement{font-size:.68rem;letter-spacing:.16em}.site-header{grid-template-columns:1fr auto auto;padding:12px 16px;min-height:70px}.brand b{font-size:.95rem}.brand small{font-size:.55rem;letter-spacing:.16em}.logo{width:46px;height:46px;border-radius:15px}.menu-btn{display:block;justify-self:end}.nav-links{position:fixed;top:74px;left:12px;right:12px;display:none;flex-direction:column;border-radius:22px;box-shadow:0 25px 65px rgba(0,0,0,.18)}.nav-links.open{display:flex}.cart-btn{padding:12px 14px;font-size:.9rem}.hero-clean{min-height:560px;padding:60px 18px;text-align:left;place-items:end start;background-position:center}.hero-overlay{background:linear-gradient(0deg,rgba(35,28,25,.55),rgba(35,28,25,.10))}.hero-inner{text-align:left}.hero-clean h1{font-size:clamp(3.3rem,16vw,5.2rem)}.hero-text{font-size:1rem;line-height:1.55}.hero-actions{justify-content:flex-start}.btn,.hero-actions a{width:100%;text-align:center}.section,.page-hero,.catalog-tools,.catalog-grid,.footer,.email-section{padding-left:16px;padding-right:16px}.section-title{text-align:left}.section-title h2,.page-hero h1{font-size:3rem}.product-grid{grid-template-columns:1fr}.product-image{height:300px}.catalog-tools{grid-template-columns:1fr}.email-section{grid-template-columns:1fr}.email-section form{border-radius:18px}.footer{flex-direction:column}
}
CSS

cat > frontend/site.js <<'JS'
const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

function toggleMenu(){
  const nav = document.getElementById("mainNav");
  if(nav) nav.classList.toggle("open");
}

function img(src){
  if(!src) return "assets/images/reza-card-bg.svg";
  if(src.startsWith("data:image")) return src;
  if(src.startsWith("http")) return src;
  if(src.startsWith("/")) return API + src;
  return src;
}

function money(v){
  return "R " + Number(v || 0).toLocaleString("en-ZA",{minimumFractionDigits:2,maximumFractionDigits:2});
}

function updateCartCount(){
  const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
  const count = cart.reduce((sum,item)=>sum+Number(item.qty||1),0);
  document.querySelectorAll("#cartCount").forEach(el=>el.textContent=count);
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

async function loadBranding(){
  try{
    const res = await fetch(API + "/api/media?t=" + Date.now());
    const data = await res.json();
    if(!data.success || !data.media) return;
    if(data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el=>{
        el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }
  }catch(e){}
}

document.addEventListener("DOMContentLoaded",()=>{
  updateCartCount();
  loadBranding();
});
JS

make_header() {
cat <<'HTML'
<div class="announcement">WELCOME TO OUR STORE</div>
<header class="site-header">
  <a class="brand" href="index.html">
    <span class="logo">R</span>
    <span><b>Reza Holdings</b><small>Champagne Luxury</small></span>
  </a>
  <button class="menu-btn" onclick="toggleMenu()">☰</button>
  <nav id="mainNav" class="nav-links">
HTML
}

make_header_end() {
cat <<'HTML'
  </nav>
  <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
</header>
HTML
}

# Rebuild policies page properly
cat > frontend/policies.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Policies | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
<div class="announcement">WELCOME TO OUR STORE</div>
<header class="site-header">
  <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
  <button class="menu-btn" onclick="toggleMenu()">☰</button>
  <nav id="mainNav" class="nav-links">
    <a href="index.html">Home</a><a href="shop.html">Catalog</a><a href="about.html">About</a><a href="contact.html">Contact</a><a class="active" href="policies.html">Policies</a>
  </nav>
  <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
</header>

<section class="page-hero">
  <p class="eyebrow">STORE POLICIES</p>
  <h1>Shipping, returns and support.</h1>
  <p>Please read our store policies before placing an order. These policies help us serve customers clearly and professionally.</p>
</section>

<section class="section">
  <div class="grid">
    <article class="card">
      <h2>Shipping Policy</h2>
      <ul>
        <li>Orders are processed after payment confirmation.</li>
        <li>Delivery time depends on your location and courier availability.</li>
        <li>Customers must provide the correct delivery address and contact number.</li>
        <li>Reza Holdings is not responsible for delays caused by incorrect customer details or courier issues outside our control.</li>
        <li>Local collection or special delivery arrangements may be confirmed through WhatsApp where available.</li>
      </ul>
    </article>

    <article class="card">
      <h2>Returns Policy</h2>
      <ul>
        <li>Due to hygiene and personal care standards, opened or used products cannot be returned.</li>
        <li>Returns may be accepted only for damaged, incorrect or defective items reported within 48 hours of receiving the order.</li>
        <li>Customers must provide clear photos/videos of the issue before a return or replacement can be approved.</li>
        <li>Approved replacements or refunds are handled after inspection and confirmation.</li>
      </ul>
    </article>

    <article class="card">
      <h2>Payment Policy</h2>
      <ul>
        <li>Orders are confirmed only after successful payment.</li>
        <li>Unpaid orders may be cancelled if payment is not completed.</li>
        <li>Customers should contact us if they need help completing payment.</li>
      </ul>
    </article>

    <article class="card">
      <h2>Product Disclaimer</h2>
      <ul>
        <li>Results may differ from person to person depending on usage, consistency and lifestyle.</li>
        <li>Product information is for general wellness and beauty support and should not replace medical advice.</li>
        <li>Customers with health concerns should consult a qualified health professional before using any wellness product.</li>
      </ul>
    </article>
  </div>
</section>

<footer class="footer">
  <p>© 2026 Reza Holdings.</p>
  <a href="policies.html">Terms and Policies</a>
</footer>
<script src="site.js"></script>
</body>
</html>
HTML

cat > frontend/about.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>About | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
<div class="announcement">WELCOME TO OUR STORE</div>
<header class="site-header">
  <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
  <button class="menu-btn" onclick="toggleMenu()">☰</button>
  <nav id="mainNav" class="nav-links">
    <a href="index.html">Home</a><a href="shop.html">Catalog</a><a class="active" href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
  </nav>
  <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
</header>

<section class="page-hero">
  <p class="eyebrow">ABOUT REZA HOLDINGS</p>
  <h1>Luxury care for everyday confidence.</h1>
  <p>Reza Holdings is a premium health, beauty and wellness store created for customers who want beautiful products, trusted service and a clean shopping experience.</p>
</section>

<section class="section">
  <div class="grid">
    <article class="card">
      <h2>Our Story</h2>
      <p>We believe beauty and wellness should feel simple, premium and trustworthy. Reza Holdings brings together carefully selected products that support glowing skin, self-care and confidence.</p>
    </article>
    <article class="card">
      <h2>Our Promise</h2>
      <p>We focus on quality presentation, clear communication, reliable ordering and customer support. Every product is displayed with care so customers can shop with confidence.</p>
    </article>
    <article class="card">
      <h2>Our Standard</h2>
      <p>We aim to give customers a luxury shopping feel while keeping the buying process fast, easy and mobile-friendly.</p>
    </article>
  </div>
</section>

<footer class="footer"><p>© 2026 Reza Holdings.</p><a href="policies.html">Terms and Policies</a></footer>
<script src="site.js"></script>
</body>
</html>
HTML

cat > frontend/contact.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Contact | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
<div class="announcement">WELCOME TO OUR STORE</div>
<header class="site-header">
  <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
  <button class="menu-btn" onclick="toggleMenu()">☰</button>
  <nav id="mainNav" class="nav-links">
    <a href="index.html">Home</a><a href="shop.html">Catalog</a><a href="about.html">About</a><a class="active" href="contact.html">Contact</a><a href="policies.html">Policies</a>
  </nav>
  <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
</header>

<section class="page-hero">
  <p class="eyebrow">CONTACT US</p>
  <h1>Talk to Reza.</h1>
  <p>Need help with products, orders, delivery or wholesale? Send us a message and we will assist you.</p>
</section>

<section class="section">
  <div class="grid">
    <form class="card" onsubmit="sendContact(event)">
      <h2>Send a message</h2>
      <input class="input" id="name" placeholder="Your name" required><br><br>
      <input class="input" id="phone" placeholder="Phone number" required><br><br>
      <textarea id="message" placeholder="How can we help?" required></textarea><br><br>
      <button class="btn primary" type="submit">Send on WhatsApp</button>
    </form>
    <article class="card">
      <h2>Contact Details</h2>
      <p><b>WhatsApp:</b> 064 761 0299</p>
      <p><b>Email:</b> ztshidada@icloud.com</p>
      <p><b>Business:</b> Reza Holdings</p>
    </article>
  </div>
</section>

<footer class="footer"><p>© 2026 Reza Holdings.</p><a href="policies.html">Terms and Policies</a></footer>
<script src="site.js"></script>
<script>
function sendContact(e){
  e.preventDefault();
  const name=document.getElementById("name").value;
  const phone=document.getElementById("phone").value;
  const message=document.getElementById("message").value;
  const text=encodeURIComponent(`Hello Reza Holdings, my name is ${name}. My number is ${phone}. ${message}`);
  window.open(`https://wa.me/27647610299?text=${text}`,"_blank");
}
</script>
</body>
</html>
HTML

git add .
git commit -m "Fix customer pages styling and mobile layout"
git push

echo "Done. Redeploy reza-frontend only."
