#!/bin/bash
set -e

echo "Repairing Reza connections only. No products will be reset."
mkdir -p frontend/js frontend/assets/css

# -------------------------------------------------------
# 1. Backend: make product create preserve admin fields + add orders API
# -------------------------------------------------------
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

old = '''    badge: incoming.badge || "",
    image: incoming.image || incoming.productImage || "assets/images/reza-card-bg.svg",
    description: incoming.description || "",
    benefits: incoming.benefits || [],
    howToUse: incoming.howToUse || "",
    showOnline: incoming.showOnline !== false
  };'''

new = '''    badge: incoming.badge || "",
    image: incoming.image || incoming.productImage || "assets/images/reza-card-bg.svg",
    description: incoming.description || "",
    benefits: incoming.benefits || [],
    howToUse: incoming.howToUse || "",
    productType: incoming.productType || "Single",
    status: incoming.status || (incoming.category === "Coming Soon" ? "comingSoon" : "sale"),
    showOnline: incoming.showOnline !== false,
    showFeatured: incoming.showFeatured === true,
    showInPopup: incoming.showInPopup === true,
    updatedAt: new Date().toISOString()
  };'''

if old in text:
    text = text.replace(old, new, 1)

orders = r'''

// ======================================================
// REZA ORDERS API - ADDED BY CONNECTION REPAIR
// ======================================================
const REZA_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaEnsureOrdersFile(){
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if(!fs.existsSync(REZA_ORDERS_FILE)){
    fs.writeFileSync(REZA_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaReadOrders(){
  try{
    rezaEnsureOrdersFile();
    return JSON.parse(fs.readFileSync(REZA_ORDERS_FILE, "utf8"));
  }catch(e){
    return [];
  }
}

function rezaWriteOrders(orders){
  rezaEnsureOrdersFile();
  fs.writeFileSync(REZA_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

app.get("/api/orders", (req,res)=>{
  res.json({ success:true, orders: rezaReadOrders() });
});

app.post("/api/orders", (req,res)=>{
  const body = req.body || {};
  const items = Array.isArray(body.items) ? body.items : [];

  if(!items.length){
    return res.status(400).json({ success:false, message:"Cart is empty" });
  }

  const orders = rezaReadOrders();
  const total = items.reduce((sum,item)=>{
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  const orderNumber =
    "REZA-" +
    new Date().toISOString().slice(0,10).replace(/-/g,"") +
    "-" +
    String(orders.length + 1).padStart(4,"0");

  const order = {
    id: orderNumber.toLowerCase(),
    orderNumber,
    customer: body.customer || {},
    items,
    subtotal: total,
    total,
    delivery: "Calculated after order",
    status: "New Order",
    paymentStatus: "Pending",
    createdAt: new Date().toISOString()
  };

  orders.unshift(order);
  rezaWriteOrders(orders);

  res.json({ success:true, message:"Order created", order });
});
// ======================================================
// END REZA ORDERS API
// ======================================================
'''

if "REZA ORDERS API - ADDED BY CONNECTION REPAIR" not in text:
    text = text.replace("app.use((req, res) => {", orders + "\napp.use((req, res) => {", 1)

p.write_text(text)
print("Backend patched.")
PY

# -------------------------------------------------------
# 2. One frontend connection script
# -------------------------------------------------------
cat > frontend/js/reza-connection-fix.js <<'JS'
(function(){
  const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
  const KEYS = ["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"];

  function safeJson(v, fallback){
    try { return JSON.parse(v || ""); } catch(e){ return fallback; }
  }

  function readCart(){
    let best = [];
    for(const k of KEYS){
      const arr = safeJson(localStorage.getItem(k), []);
      if(Array.isArray(arr) && arr.length > best.length) best = arr;
    }
    return best;
  }

  function writeCart(cart){
    KEYS.forEach(k => localStorage.setItem(k, JSON.stringify(cart)));
    updateCount();
  }

  function countCart(cart = readCart()){
    return cart.reduce((s,i)=> s + Number(i.qty || i.quantity || 1), 0);
  }

  function updateCount(){
    const count = countCart();
    document.querySelectorAll("#cartCount,[data-count],[data-cart-count],.cart-count,.cart-badge,.bag-count").forEach(el => {
      el.textContent = count;
    });
    document.body.setAttribute("data-cart-count", count);
  }

  function money(v){
    const n = Number(v || 0);
    if(!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", { maximumFractionDigits:0 });
  }

  function image(src){
    if(!src) return "assets/images/reza-card-bg.svg";
    if(src.startsWith("data:image") || src.startsWith("http")) return src;
    if(src.startsWith("/")) return API + src;
    return src;
  }

  function toast(msg){
    let t = document.querySelector(".reza-connection-toast");
    if(!t){
      t = document.createElement("div");
      t.className = "reza-connection-toast";
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.classList.add("show");
    setTimeout(()=>t.classList.remove("show"), 1700);
  }

  window.addToCart = function(product){
    if(!product) return;

    const id = product.id || product.name || ("product-" + Date.now());
    const cart = readCart();
    const found = cart.find(i => String(i.id || i.name) === String(id));

    if(found){
      found.qty = Number(found.qty || found.quantity || 1) + 1;
      found.quantity = found.qty;
    } else {
      cart.push({
        id,
        name: product.name || "Reza Product",
        price: Number(product.price || 0),
        image: product.image || "",
        category: product.category || "",
        productType: product.productType || "",
        qty: 1,
        quantity: 1
      });
    }

    writeCart(cart);
    toast("Added to bag");
  };

  window.rezaFixQty = function(index, change){
    const cart = readCart();
    if(!cart[index]) return;
    cart[index].qty = Math.max(1, Number(cart[index].qty || cart[index].quantity || 1) + change);
    cart[index].quantity = cart[index].qty;
    writeCart(cart);
    renderCart();
  };

  window.rezaFixRemove = function(index){
    const cart = readCart();
    cart.splice(index, 1);
    writeCart(cart);
    renderCart();
  };

  function isComing(p){
    return p.status === "comingSoon" ||
      p.status === "coming-soon" ||
      p.category === "Coming Soon" ||
      p.productType === "Coming Soon" ||
      p.comingSoon === true;
  }

  function isSale(p){
    return p.showOnline !== false && !isComing(p);
  }

  async function getProducts(){
    const res = await fetch(API + "/api/products?t=" + Date.now(), { cache:"no-store" });
    const data = await res.json();
    return Array.isArray(data.products) ? data.products : [];
  }

  function card(p, coming){
    const payload = JSON.stringify(p).replace(/'/g, "&apos;");
    return `
      <article class="product-card reza-fixed-card">
        <div class="product-image reza-fixed-image">
          <span class="product-badge">${coming ? "Coming Soon" : (p.badge || p.productType || p.category || "Product")}</span>
          <img src="${image(p.image)}" alt="${p.name || "Product"}" loading="lazy">
        </div>
        <div class="product-body">
          <p class="category">${p.category || "Reza Holdings"}</p>
          <h3>${p.name || "Reza Product"}</h3>
          <p class="price">${coming ? "Coming Soon" : money(p.price)}</p>
          <p class="description">${p.description || ""}</p>
          ${
            coming
              ? `<button type="button" disabled>Coming Soon</button>`
              : `<button type="button" onclick='addToCart(${payload})'>Add to Bag</button>`
          }
        </div>
      </article>`;
  }

  async function renderFeatured(){
    const grid =
      document.getElementById("featuredGrid") ||
      document.querySelector("[data-featured-products], #featuredProducts, .featured-products");

    if(!grid) return;

    const products = await getProducts();
    const sale = products.filter(isSale);
    const selected = sale.filter(p => p.showFeatured === true).slice(0, 3);
    const list = selected.length ? selected : sale.slice(0, 3);

    grid.innerHTML = list.length
      ? list.map(p => card(p, false)).join("")
      : `<div class="loading-card">No featured products selected.</div>`;
  }

  async function renderComing(){
    const grid =
      document.getElementById("comingSoonGrid") ||
      document.querySelector("[data-coming-soon-products], #comingSoonProducts, .coming-soon-grid");

    if(!grid) return;

    const products = await getProducts();
    const list = products.filter(isComing);

    grid.innerHTML = list.length
      ? list.map(p => card(p, true)).join("")
      : `<p>No coming soon products yet.</p>`;
  }

  function renderCart(){
    const onCart = /cart\.html/i.test(location.pathname) || document.querySelector("[data-cart-page]");
    if(!onCart){
      updateCount();
      return;
    }

    const list = document.querySelector("[data-cart-list], .cart-list, #cartItems, #cartList, .cart-items");
    const subtotalEl = document.querySelector("[data-subtotal]");
    const totalEl = document.querySelector("[data-total]");

    if(!list) return;

    const cart = readCart();
    const total = cart.reduce((s,i)=> s + Number(i.price || 0) * Number(i.qty || i.quantity || 1), 0);

    if(!cart.length){
      list.innerHTML = `
        <div class="glass empty">
          <h2>Your cart is empty</h2>
          <p>Add products before checkout.</p>
          <a class="btn primary" href="shop.html">Shop Products</a>
        </div>`;
    } else {
      list.innerHTML = cart.map((i,index)=>{
        const qty = Number(i.qty || i.quantity || 1);
        return `
          <div class="cart-item glass">
            <img src="${image(i.image)}">
            <div>
              <h3>${i.name}</h3>
              <div class="price">${money(i.price)}</div>
            </div>
            <div class="qty">
              <button onclick="rezaFixQty(${index},-1)">−</button>
              <b>${qty}</b>
              <button onclick="rezaFixQty(${index},1)">+</button>
            </div>
            <b class="line">${money(Number(i.price || 0) * qty)}</b>
            <button class="remove" onclick="rezaFixRemove(${index})">Remove</button>
          </div>`;
      }).join("");
    }

    if(subtotalEl) subtotalEl.textContent = money(total);
    if(totalEl) totalEl.textContent = money(total);
    updateCount();
  }

  function renderCheckout(){
    const host = document.querySelector("[data-v11-checkout]");
    if(!host) return;

    const cart = readCart();
    const total = cart.reduce((s,i)=> s + Number(i.price || 0) * Number(i.qty || i.quantity || 1), 0);

    host.innerHTML = `
      <section class="page-hero">
        <div class="container">
          <div class="kicker">Secure Checkout</div>
          <h1>Checkout</h1>
          <p class="lead">Enter your details and submit your order.</p>
        </div>
      </section>

      <section class="section">
        <div class="container checkout-shell">
          <form class="checkout-card" id="rezaCheckoutForm">
            <h2>Customer Information</h2>
            <input class="input" name="name" placeholder="Full name" required>
            <input class="input" name="phone" placeholder="Phone / WhatsApp" required>
            <input class="input" type="email" name="email" placeholder="Email address">

            <h2>Delivery Details</h2>
            <input class="input" name="address" placeholder="Address / collection details">
            <textarea class="input" name="notes" placeholder="Order notes"></textarea>

            <button class="btn primary full" type="submit">Place Order</button>
          </form>

          <aside class="summary glass">
            <h2>Summary</h2>
            ${
              cart.map(i=>`
                <div class="row">
                  <span>${Number(i.qty || i.quantity || 1)} × ${i.name}</span>
                  <strong>${money(Number(i.price || 0) * Number(i.qty || i.quantity || 1))}</strong>
                </div>`).join("") || "<p>No cart items.</p>"
            }
            <div class="row total">
              <span>Total</span>
              <strong>${money(total)}</strong>
            </div>
          </aside>
        </div>
      </section>`;

    document.getElementById("rezaCheckoutForm").addEventListener("submit", async function(e){
      e.preventDefault();

      const items = readCart();
      if(!items.length){
        toast("Cart is empty");
        return;
      }

      try{
        const res = await fetch(API + "/api/orders", {
          method:"POST",
          headers:{ "Content-Type":"application/json" },
          body: JSON.stringify({
            customer:Object.fromEntries(new FormData(this).entries()),
            items
          })
        });

        const data = await res.json();
        if(!res.ok || !data.success) throw new Error(data.message || "Order failed");

        KEYS.forEach(k => localStorage.removeItem(k));
        updateCount();

        alert("Order created: " + data.order.orderNumber);
        location.href = "index.html";
      }catch(err){
        alert("Order failed: " + err.message);
      }
    });
  }

  async function popupOnce(){
    const path = location.pathname.toLowerCase();
    const home = path === "/" || path.endsWith("/index.html") || path.endsWith("/index");

    if(!home || sessionStorage.getItem("reza_popup_seen_this_visit") === "yes") return;

    try{
      const res = await fetch(API + "/api/popup?t=" + Date.now(), { cache:"no-store" });
      const data = await res.json();
      const p = data.popup || {};

      if(!p.enabled) return;

      sessionStorage.setItem("reza_popup_seen_this_visit","yes");

      const el = document.createElement("div");
      el.className = "reza-popup-overlay show";
      el.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img class="reza-popup-img" src="${image(p.image)}" alt="Special">` : ""}
          <p class="reza-popup-kicker">${p.category || "Specials"}</p>
          <h2>${p.title || "Special"}</h2>
          <p>${p.message || ""}</p>
          <a class="btn primary" href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>`;

      document.body.appendChild(el);
      el.querySelector(".reza-popup-close").onclick = () => el.remove();
      el.addEventListener("click", ev => {
        if(ev.target === el) el.remove();
      });
    }catch(e){}
  }

  function boot(){
    updateCount();
    renderCart();
    renderCheckout();
    renderFeatured().catch(console.warn);
    renderComing().catch(console.warn);
    setTimeout(popupOnce, 600);
  }

  document.addEventListener("DOMContentLoaded", boot);
  window.addEventListener("load", boot);
})();
JS

# -------------------------------------------------------
# 3. Small CSS only for toast, popup and product images
# -------------------------------------------------------
cat > frontend/assets/css/reza-connection-fix.css <<'CSS'
.reza-connection-toast{
  position:fixed;
  right:18px;
  bottom:18px;
  z-index:999999;
  background:#241812;
  color:#fff8ed;
  padding:14px 20px;
  border-radius:999px;
  font-weight:900;
  box-shadow:0 18px 50px rgba(0,0,0,.25);
  opacity:0;
  transform:translateY(10px);
  transition:.25s ease;
}
.reza-connection-toast.show{
  opacity:1;
  transform:translateY(0);
}

#cartCount,[data-count],[data-cart-count],.cart-count,.cart-badge,.bag-count{
  display:inline-flex!important;
  align-items:center!important;
  justify-content:center!important;
  min-width:24px!important;
  height:24px!important;
  border-radius:999px!important;
  font-weight:1000!important;
}

.reza-fixed-image img,
.product-image img,
.soon-card img{
  width:100%!important;
  height:100%!important;
  object-fit:contain!important;
  object-position:center!important;
  background:#fff7ef!important;
}
.product-image,
.reza-fixed-image{
  min-height:280px!important;
}

.reza-popup-overlay{
  position:fixed;
  inset:0;
  background:rgba(0,0,0,.52);
  z-index:99999;
  display:grid;
  place-items:center;
  padding:22px;
}
.reza-popup-card{
  width:min(540px,100%);
  background:#fff8ee;
  border-radius:28px;
  padding:22px;
  position:relative;
  box-shadow:0 30px 80px rgba(0,0,0,.35);
}
.reza-popup-close{
  position:absolute;
  top:12px;
  right:12px;
  border:0;
  width:36px;
  height:36px;
  border-radius:50%;
  font-size:22px;
  cursor:pointer;
}
.reza-popup-img{
  width:100%;
  max-height:430px;
  object-fit:contain;
  border-radius:20px;
  background:white;
}
.reza-popup-kicker{
  color:#a87622;
  font-weight:1000;
  letter-spacing:.14em;
  text-transform:uppercase;
}
.reza-popup-card h2{
  font-family:Georgia,serif;
  font-size:2.4rem;
  margin:8px 0;
}
.reza-popup-card a{
  display:inline-flex;
  margin-top:14px;
  text-decoration:none;
}
CSS

# -------------------------------------------------------
# 4. Remove fighting scripts, inject one fix script last
# -------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import re

remove = [
  "js/app.js",
  "js/reza-products-live-final.js",
  "js/reza-products-master.js",
  "js/reza-cart-master.js",
  "js/reza-cart-system.js",
  "js/reza-popup-once.js",
  "js/reza-popup.js"
]

for p in Path("frontend").glob("*.html"):
    text = p.read_text()

    for s in remove:
        text = re.sub(rf'\s*<script src="{re.escape(s)}[^">]*"></script>\s*', '\n', text)

    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/reza-connection-fix\.css[^">]*">\s*', '\n', text)
    text = re.sub(r'\s*<script src="js/reza-connection-fix\.js[^">]*"></script>\s*', '\n', text)

    if "assets/css/reza-connection-fix.css" not in text:
        text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-connection-fix.css?v=fix1">\n</head>')

    text = text.replace("</body>", '  <script src="js/reza-connection-fix.js?v=fix1"></script>\n</body>')

    p.write_text(text)
    print("Patched:", p)
PY

git add .
git commit -m "Repair Reza cart checkout featured popup coming soon connections"
git push

echo "DONE. Redeploy backend, frontend and admin."
