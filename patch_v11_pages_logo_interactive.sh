#!/bin/bash
set -e

echo "✨ Adding About page, Contact page, Policies page, logo admin upload and product animations..."

# 1) Backend already accepts any media fields, but ensure media default includes logoImage
python3 - <<'PY'
from pathlib import Path
import json

p = Path("backend/data/media.json")
p.parent.mkdir(parents=True, exist_ok=True)

data = {}
if p.exists():
    try:
        data = json.loads(p.read_text())
    except Exception:
        data = {}

data.setdefault("heroImage", "assets/images/reza-soft-beauty-bg.svg")
data.setdefault("heroTitle", "Champagne Luxury")
data.setdefault("logoImage", "")
data["updatedAt"] = data.get("updatedAt") or ""

p.write_text(json.dumps(data, indent=2))
print("✅ Media defaults checked.")
PY

# 2) Shared frontend style
cat > frontend/reza-style.css <<'CSS'
*{box-sizing:border-box}
body{
  margin:0;
  font-family:Inter,Arial,sans-serif;
  color:#241812;
  background:radial-gradient(circle at 80% 10%,rgba(244,199,184,.25),transparent 28%),#fff8ed;
}
a{text-decoration:none;color:inherit}
.top{background:#f2d7a5;text-align:center;padding:10px;font-weight:900;letter-spacing:.28em;font-size:.78rem}
.nav{
  position:sticky;top:0;z-index:50;
  background:rgba(255,250,242,.92);
  backdrop-filter:blur(18px);
  display:flex;align-items:center;justify-content:space-between;
  padding:18px 9%;
  box-shadow:0 10px 35px rgba(70,45,25,.08);
}
.brand{display:flex;align-items:center;gap:14px;font-weight:1000}
.logo{
  width:56px;height:56px;border-radius:18px;
  background:#fff0c8;
  display:grid;place-items:center;
  font-family:Georgia,serif;
  font-size:1.5rem;
  overflow:hidden;
}
.logo img{width:100%;height:100%;object-fit:cover}
.brand small{display:block;letter-spacing:.25em;color:#8a5b19;font-size:.7rem}
.links{display:flex;gap:10px;background:#fff;padding:8px;border-radius:999px}
.links a{padding:12px 22px;border-radius:999px;font-weight:900}
.links a.active{background:#241812;color:#fff}
.shopbtn{background:#d7a447;padding:15px 28px;border-radius:999px;font-weight:1000}
.hero{
  min-height:70vh;
  display:grid;
  align-items:center;
  padding:90px 9%;
  background-size:cover;
  background-position:center;
  position:relative;
}
.hero::before{
  content:"";
  position:absolute;
  inset:0;
  background:linear-gradient(90deg,rgba(255,248,238,.94),rgba(255,240,220,.66),rgba(255,220,205,.18));
}
.hero-content{position:relative;max-width:760px}
.kicker{letter-spacing:.45em;color:#a36d20;font-weight:1000;font-size:.78rem}
h1{
  font-family:Georgia,serif;
  font-size:clamp(4rem,10vw,8.8rem);
  line-height:.86;
  margin:20px 0;
  color:#271915;
}
h2{
  font-family:Georgia,serif;
  font-size:clamp(3rem,7vw,5.8rem);
  line-height:.9;
  margin:0 0 22px;
}
.lead{font-size:1.25rem;line-height:1.8;font-weight:750;color:#5e5047;max-width:760px}
.chips{display:flex;gap:12px;flex-wrap:wrap;margin:28px 0}
.chip{background:rgba(255,255,255,.75);padding:12px 18px;border-radius:999px;font-weight:900}
.actions{display:flex;gap:14px;flex-wrap:wrap}
.btn{
  border:0;border-radius:999px;
  padding:16px 28px;
  font-weight:1000;
  cursor:pointer;
  font-size:1rem;
  display:inline-block;
}
.primary{background:linear-gradient(135deg,#f0c96f,#c9943d);color:#241812}
.ghost{background:rgba(255,255,255,.72);border:1px solid rgba(0,0,0,.1)}
.section{padding:80px 9%}
.card{
  background:rgba(255,255,255,.84);
  border-radius:34px;
  padding:32px;
  box-shadow:0 25px 80px rgba(90,55,25,.13);
  border:1px solid rgba(120,80,40,.1);
}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:28px}
.product-card{
  background:rgba(255,255,255,.86);
  border-radius:34px;
  overflow:hidden;
  box-shadow:0 25px 80px rgba(90,55,25,.14);
  border:1px solid rgba(120,80,40,.1);
  transition:transform .35s ease, box-shadow .35s ease;
  animation: productFloat 4.5s ease-in-out infinite;
}
.product-card:nth-child(2){animation-delay:.35s}
.product-card:nth-child(3){animation-delay:.7s}
.product-card:nth-child(4){animation-delay:1s}
.product-card:hover{
  transform:translateY(-16px) scale(1.025);
  box-shadow:0 35px 100px rgba(90,55,25,.22);
}
@keyframes productFloat{
  0%,100%{transform:translateY(0)}
  50%{transform:translateY(-8px)}
}
.pic{height:320px;position:relative;background:#f5dfc3;overflow:hidden}
.pic img{width:100%;height:100%;object-fit:cover;transition:transform .5s ease}
.product-card:hover .pic img{transform:scale(1.08) rotate(.8deg)}
.badge{position:absolute;top:16px;left:16px;background:#d7a447;padding:10px 16px;border-radius:999px;font-weight:1000;z-index:2}
.info{padding:24px}
.cat{color:#9b6b25;text-transform:uppercase;letter-spacing:.15em;font-weight:1000;font-size:.75rem}
.info h3{font-size:1.55rem;margin:10px 0}
.price{font-size:1.35rem;font-weight:1000;color:#8a5b19}
.desc{color:#5e5047;line-height:1.65}
.input, textarea, select{
  width:100%;
  padding:17px 18px;
  border-radius:18px;
  border:1px solid rgba(0,0,0,.12);
  background:rgba(255,255,255,.82);
  font-size:1rem;
}
textarea{min-height:140px;resize:vertical}
.policy-list li{margin:12px 0;line-height:1.7;color:#5e5047}
.footer{padding:40px 9%;background:#241812;color:#fff8ed}
@media(max-width:800px){
  .links{display:none}
  .nav,.hero,.section,.footer{padding-left:5%;padding-right:5%}
}
CSS

# 3) Small shared JS for logo + hero media
cat > frontend/reza-live.js <<'JS'
const REZA_API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

function rezaImage(src){
  if(!src) return "";
  if(src.startsWith("data:image")) return src;
  if(src.startsWith("http")) return src;
  if(src.startsWith("/")) return REZA_API + src;
  return src;
}

async function loadRezaBranding(){
  try{
    const res = await fetch(REZA_API + "/api/media?t=" + Date.now());
    const data = await res.json();
    if(!data.success || !data.media) return;

    if(data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el=>{
        el.innerHTML = `<img src="${rezaImage(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }

    if(data.media.heroImage){
      document.querySelectorAll(".hero").forEach(el=>{
        el.style.backgroundImage = `url("${rezaImage(data.media.heroImage)}")`;
      });
    }
  }catch(e){ console.warn("Branding failed", e); }
}

document.addEventListener("DOMContentLoaded", loadRezaBranding);
JS

# 4) About page
cat > frontend/about.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>About | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <div class="top">SOFT LUXURY • HEALTH • BEAUTY • WELLNESS</div>
  <nav class="nav">
    <a class="brand" href="index.html"><span class="logo">R</span><span>Reza Holdings <small>CHAMPAGNE LUXURY</small></span></a>
    <div class="links">
      <a href="index.html">Home</a><a href="shop.html">Shop</a><a class="active" href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </div>
    <a class="shopbtn" href="shop.html">Shop</a>
  </nav>

  <section class="hero">
    <div class="hero-content">
      <div class="kicker">ABOUT REZA</div>
      <h1>Luxury care for everyday confidence.</h1>
      <p class="lead">Reza Holdings is a soft luxury health, beauty and wellness store created for customers who want premium products, elegant presentation and a smooth shopping experience.</p>
    </div>
  </section>

  <section class="section">
    <div class="grid">
      <div class="card">
        <h2>Our Story</h2>
        <p class="lead">We believe beauty and wellness should feel simple, premium and trustworthy. Reza Holdings brings together carefully selected products that support glowing skin, self-care and confidence.</p>
      </div>
      <div class="card">
        <h2>Our Promise</h2>
        <p class="lead">We focus on quality presentation, clear communication, reliable ordering and customer support. Every product is displayed with care so customers can shop with confidence.</p>
      </div>
    </div>
  </section>

  <footer class="footer">© Reza Holdings. Premium health, beauty and wellness products.</footer>
  <script src="reza-live.js"></script>
</body>
</html>
HTML

# 5) Contact page
cat > frontend/contact.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Contact | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <div class="top">SOFT LUXURY • HEALTH • BEAUTY • WELLNESS</div>
  <nav class="nav">
    <a class="brand" href="index.html"><span class="logo">R</span><span>Reza Holdings <small>CHAMPAGNE LUXURY</small></span></a>
    <div class="links">
      <a href="index.html">Home</a><a href="shop.html">Shop</a><a href="about.html">About</a><a class="active" href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </div>
    <a class="shopbtn" href="shop.html">Shop</a>
  </nav>

  <section class="hero">
    <div class="hero-content">
      <div class="kicker">CONTACT US</div>
      <h1>Talk to Reza.</h1>
      <p class="lead">Need help with products, orders, delivery or wholesale? Send us a message and we will assist you.</p>
      <div class="actions">
        <a class="btn primary" href="https://wa.me/27647610299" target="_blank">WhatsApp Us</a>
        <a class="btn ghost" href="mailto:ztshidada@icloud.com">Email Us</a>
      </div>
    </div>
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
      <div class="card">
        <h2>Details</h2>
        <p class="lead"><b>WhatsApp:</b> 064 761 0299</p>
        <p class="lead"><b>Email:</b> ztshidada@icloud.com</p>
        <p class="lead"><b>Business:</b> Reza Holdings</p>
      </div>
    </div>
  </section>

  <footer class="footer">© Reza Holdings.</footer>

  <script src="reza-live.js"></script>
  <script>
    function sendContact(e){
      e.preventDefault();
      const name = document.getElementById("name").value;
      const phone = document.getElementById("phone").value;
      const message = document.getElementById("message").value;
      const text = encodeURIComponent(`Hello Reza Holdings, my name is ${name}. My number is ${phone}. ${message}`);
      window.open(`https://wa.me/27647610299?text=${text}`, "_blank");
    }
  </script>
</body>
</html>
HTML

# 6) Policies page
cat > frontend/policies.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Policies | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <div class="top">SOFT LUXURY • HEALTH • BEAUTY • WELLNESS</div>
  <nav class="nav">
    <a class="brand" href="index.html"><span class="logo">R</span><span>Reza Holdings <small>CHAMPAGNE LUXURY</small></span></a>
    <div class="links">
      <a href="index.html">Home</a><a href="shop.html">Shop</a><a href="about.html">About</a><a href="contact.html">Contact</a><a class="active" href="policies.html">Policies</a>
    </div>
    <a class="shopbtn" href="shop.html">Shop</a>
  </nav>

  <section class="hero">
    <div class="hero-content">
      <div class="kicker">STORE POLICIES</div>
      <h1>Shipping, returns and support.</h1>
      <p class="lead">Please read our store policies before placing an order. These policies help us serve customers clearly and professionally.</p>
    </div>
  </section>

  <section class="section">
    <div class="grid">
      <div class="card">
        <h2>Shipping Policy</h2>
        <ul class="policy-list">
          <li>Orders are processed after payment confirmation.</li>
          <li>Delivery time depends on your location and courier availability.</li>
          <li>Customers must provide the correct delivery address and contact number.</li>
          <li>Reza Holdings is not responsible for delays caused by incorrect customer details or courier issues outside our control.</li>
          <li>Local collection or special delivery arrangements may be confirmed through WhatsApp where available.</li>
        </ul>
      </div>

      <div class="card">
        <h2>Returns Policy</h2>
        <ul class="policy-list">
          <li>Due to hygiene and personal care standards, opened or used products cannot be returned.</li>
          <li>Returns may be accepted only for damaged, incorrect or defective items reported within 48 hours of receiving the order.</li>
          <li>Customers must provide clear photos/videos of the issue before a return or replacement can be approved.</li>
          <li>Approved replacements or refunds are handled after inspection and confirmation.</li>
        </ul>
      </div>

      <div class="card">
        <h2>Payment Policy</h2>
        <ul class="policy-list">
          <li>Orders are confirmed only after successful payment.</li>
          <li>Unpaid orders may be cancelled if payment is not completed.</li>
          <li>Customers should contact us if they need help completing payment.</li>
        </ul>
      </div>

      <div class="card">
        <h2>Product Disclaimer</h2>
        <ul class="policy-list">
          <li>Results may differ from person to person depending on usage, consistency and lifestyle.</li>
          <li>Product information is for general wellness and beauty support and should not replace medical advice.</li>
          <li>Customers with health concerns should consult a qualified health professional before using any wellness product.</li>
        </ul>
      </div>
    </div>
  </section>

  <footer class="footer">© Reza Holdings. Policies may be updated when required.</footer>
  <script src="reza-live.js"></script>
</body>
</html>
HTML

# 7) Update index/shop links to real pages
python3 - <<'PY'
from pathlib import Path

for name in ["frontend/index.html", "frontend/shop.html"]:
    p = Path(name)
    text = p.read_text()
    text = text.replace('href="#about"', 'href="about.html"')
    text = text.replace('href="#contact"', 'href="contact.html"')
    text = text.replace('href="#policies"', 'href="policies.html"')
    text = text.replace('href="index.html#about"', 'href="about.html"')
    text = text.replace('href="index.html#contact"', 'href="contact.html"')
    text = text.replace('href="index.html#policies"', 'href="policies.html"')
    if 'reza-live.js' not in text:
        text = text.replace("</body>", '<script src="reza-live.js"></script>\n</body>')
    p.write_text(text)
PY

# 8) Replace admin media page with logo + hero uploader
cat > admin/media.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Media | Reza Admin</title>
  <style>
    *{box-sizing:border-box}
    body{margin:0;font-family:Arial,sans-serif;color:#241812;background:linear-gradient(135deg,#fffaf2,#f3dfce);min-height:100vh}
    .layout{display:grid;grid-template-columns:280px 1fr;min-height:100vh}
    .side{padding:34px 28px;background:rgba(255,255,255,.52);border-right:1px solid rgba(0,0,0,.08)}
    .side h1{font-family:Georgia,serif;font-size:2.5rem;margin:0}.side span{color:#b8872f}
    .side a{display:block;padding:15px 18px;margin:8px 0;border-radius:18px;color:#241812;text-decoration:none;font-weight:900}
    .side a.active,.side a:hover{background:#241812;color:#fffaf2}
    .main{padding:44px}
    .head{display:flex;align-items:center;justify-content:space-between;gap:20px;margin-bottom:28px}
    .head h1{font-family:Georgia,serif;font-size:clamp(3rem,7vw,5.6rem);margin:0}
    .card{background:rgba(255,255,255,.78);border-radius:32px;padding:28px;box-shadow:0 28px 80px rgba(70,45,25,.13);margin-bottom:24px}
    .preview{width:100%;height:320px;object-fit:cover;border-radius:26px;background:#f4e4cf;display:block;margin:18px 0}
    .logoPreview{width:120px;height:120px;object-fit:cover;border-radius:28px;background:#fff0c8;display:block;margin:18px 0}
    .input{width:100%;padding:17px;border-radius:18px;border:1px solid rgba(0,0,0,.12);background:white}
    .btn{border:0;border-radius:999px;padding:16px 28px;font-weight:1000;cursor:pointer}
    .primary{background:linear-gradient(135deg,#e7c06f,#c9943d);color:#241812}
    .status{padding:16px;border-radius:18px;background:rgba(201,148,61,.13);font-weight:900;color:#6d4917}
    @media(max-width:850px){.layout{grid-template-columns:1fr}.main{padding:24px}}
  </style>
</head>
<body>
  <div class="layout">
    <aside class="side">
      <h1>Reza <span>Admin</span></h1>
      <p>Champagne Luxury V11</p>
      <a href="dashboard.html">Dashboard</a>
      <a href="products.html">Products</a>
      <a class="active" href="media.html">Media</a>
      <a href="orders.html">Orders</a>
      <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
      <a href="login.html">Logout</a>
    </aside>

    <main class="main">
      <div class="head">
        <h1>Media</h1>
        <button id="saveBtn" class="btn primary">Save</button>
      </div>

      <section class="card">
        <h2>Website Logo</h2>
        <p>Upload the logo that replaces the R icon in the top navigation.</p>
        <img id="logoPreview" class="logoPreview" alt="Logo preview">
        <input id="logoFile" class="input" type="file" accept="image/*">
      </section>

      <section class="card">
        <h2>Homepage Hero Background</h2>
        <p>Upload the background image for the homepage hero.</p>
        <img id="heroPreview" class="preview" alt="Hero preview">
        <input id="heroFile" class="input" type="file" accept="image/*">
        <br><br>
        <input id="heroTitle" class="input" type="text" value="Champagne Luxury">
      </section>

      <div id="status" class="status">Ready.</div>
    </main>
  </div>

  <script>
    const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

    const logoFile = document.getElementById("logoFile");
    const heroFile = document.getElementById("heroFile");
    const logoPreview = document.getElementById("logoPreview");
    const heroPreview = document.getElementById("heroPreview");
    const heroTitle = document.getElementById("heroTitle");
    const saveBtn = document.getElementById("saveBtn");
    const statusBox = document.getElementById("status");

    let logoImage = "";
    let heroImage = "";

    function status(msg){ statusBox.textContent = msg; }

    function fileToDataURL(file){
      return new Promise((resolve,reject)=>{
        const r = new FileReader();
        r.onload = () => resolve(r.result);
        r.onerror = reject;
        r.readAsDataURL(file);
      });
    }

    logoFile.addEventListener("change", async ()=>{
      if(!logoFile.files[0]) return;
      logoImage = await fileToDataURL(logoFile.files[0]);
      logoPreview.src = logoImage;
      status("Logo ready. Click Save.");
    });

    heroFile.addEventListener("change", async ()=>{
      if(!heroFile.files[0]) return;
      heroImage = await fileToDataURL(heroFile.files[0]);
      heroPreview.src = heroImage;
      status("Hero image ready. Click Save.");
    });

    async function loadMedia(){
      try{
        const res = await fetch(API + "/api/media?t=" + Date.now());
        const data = await res.json();
        if(data.success && data.media){
          if(data.media.logoImage) logoPreview.src = data.media.logoImage;
          if(data.media.heroImage) heroPreview.src = data.media.heroImage;
          if(data.media.heroTitle) heroTitle.value = data.media.heroTitle;
        }
      }catch(e){ status("Could not load media."); }
    }

    saveBtn.addEventListener("click", async ()=>{
      try{
        saveBtn.textContent = "Saving...";
        saveBtn.disabled = true;

        const payload = { heroTitle: heroTitle.value || "Champagne Luxury" };
        if(logoImage) payload.logoImage = logoImage;
        if(heroImage) payload.heroImage = heroImage;

        const res = await fetch(API + "/api/media", {
          method:"POST",
          headers:{"Content-Type":"application/json"},
          body:JSON.stringify(payload)
        });

        const data = await res.json();
        if(!data.success) throw new Error(data.message || "Save failed");

        alert("Saved successfully. Hard refresh the customer website.");
        status("Saved successfully.");
      }catch(e){
        alert(e.message || "Save failed");
        status("Save failed.");
      }finally{
        saveBtn.textContent = "Save";
        saveBtn.disabled = false;
      }
    });

    loadMedia();
  </script>
</body>
</html>
HTML

git add .
git commit -m "Add pages logo admin media and interactive product animations"
git push

echo "✅ Done. Redeploy backend, admin and frontend."
