#!/bin/bash
set -e

echo "Repairing Reza V11 core clean..."
echo "This will NOT reset products."

mkdir -p frontend/assets/css frontend/js

# ======================================================
# 1. BACKEND: add working orders route safely
# ======================================================
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

orders_block = r'''
// ======================================================
// REZA ORDERS API - CLEAN CHECKOUT SUPPORT
// ======================================================
const REZA_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaEnsureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_ORDERS_FILE)) {
    fs.writeFileSync(REZA_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaReadOrders() {
  try {
    rezaEnsureOrdersFile();
    return JSON.parse(fs.readFileSync(REZA_ORDERS_FILE, "utf8"));
  } catch {
    return [];
  }
}

function rezaWriteOrders(orders) {
  rezaEnsureOrdersFile();
  fs.writeFileSync(REZA_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

app.get("/api/orders", (req, res) => {
  res.json({ success: true, orders: rezaReadOrders() });
});

app.post("/api/orders", (req, res) => {
  const orders = rezaReadOrders();
  const body = req.body || {};
  const items = Array.isArray(body.items) ? body.items : [];

  if (!items.length) {
    return res.status(400).json({ success: false, message: "Cart is empty" });
  }

  const subtotal = items.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  const orderNumber = "REZA-" + new Date().toISOString().slice(0,10).replace(/-/g,"") + "-" + String(orders.length + 1).padStart(4, "0");

  const order = {
    id: orderNumber.toLowerCase(),
    orderNumber,
    customer: body.customer || {},
    items,
    subtotal,
    total: subtotal,
    delivery: "Calculated after order",
    status: "New",
    createdAt: new Date().toISOString()
  };

  orders.unshift(order);
  rezaWriteOrders(orders);

  res.json({ success: true, message: "Order created", order });
});
// ======================================================
// END REZA ORDERS API
// ======================================================
'''

if "REZA ORDERS API - CLEAN CHECKOUT SUPPORT" not in text:
    marker = "app.use((req, res) => {"
    if marker in text:
        text = text.replace(marker, orders_block + "\n\n" + marker)
    else:
        text += "\n\n" + orders_block

p.write_text(text)
print("Backend orders route checked.")
PY

# ======================================================
# 2. ONE CLEAN FRONTEND BRAIN
# ======================================================
cat > frontend/site.js <<'JS'
const API = location.hostname.includes("localhost")
  ? "http://localhost:10000"
  : "https://api.rezaholdings.co.za";

const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];

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

function money(value){
  const n = Number(value || 0);
  if(!n) return "Price coming soon";
  return "R " + n.toLocaleString("en-ZA", { maximumFractionDigits: 0 });
}

function readCart(){
  for(const key of CART_KEYS){
    try{
      const data = JSON.parse(localStorage.getItem(key) || "[]");
      if(Array.isArray(data) && data.length) return data;
    }catch(e){}
  }
  return [];
}

function saveCart(cart){
  CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));
  updateCartCount();
}

function updateCartCount(){
  const cart = readCart();
  const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);

  document.querySelectorAll("#cartCount,[data-count],[data-cart-count],.cart-count,.cart-badge,.bag-count").forEach(el => {
    el.textContent = count;
  });

  document.body.setAttribute("data-cart-count", count);
}

function toast(message){
  let el = document.querySelector(".reza-toast");
  if(!el){
    el = document.createElement("div");
    el.className = "reza-toast";
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.classList.add("show");
  setTimeout(() => el.classList.remove("show"), 1800);
}

async function apiGet(path){
  const res = await fetch(API + path, { cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API error");
  return data;
}

async function apiPost(path, body){
  const res = await fetch(API + path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const data = await res.json().catch(() => ({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API error");
  return data;
}

async function getProducts(){
  const data = await apiGet("/api/products?t=" + Date.now());
  return Array.isArray(data.products) ? data.products : [];
}

function isComingSoon(p){
  return p.status === "comingSoon" ||
         p.status === "coming-soon" ||
         p.category === "Coming Soon" ||
         p.productType === "Coming Soon" ||
         p.comingSoon === true;
}

function isSaleProduct(p){
  return p.showOnline !== false && !isComingSoon(p);
}

function productCard(p, mode="sale"){
  const coming = mode === "coming";
  const payload = JSON.stringify(p).replace(/'/g, "&apos;");

  return `
    <article class="reza-product-card">
      <div class="reza-product-image">
        <span>${coming ? "Coming Soon" : (p.badge || p.productType || "Product")}</span>
        <img src="${img(p.image)}" alt="${p.name || "Reza product"}" loading="lazy">
      </div>
      <div class="reza-product-body">
        <p class="reza-product-type">${p.category || "Reza Holdings"}</p>
        <h3>${p.name || "Reza Product"}</h3>
        <p class="reza-product-price">${coming ? "Coming Soon" : money(p.price)}</p>
        <p>${p.description || ""}</p>
        ${
          coming
            ? `<button type="button" class="muted">Coming Soon</button>`
            : `<button type="button" onclick='addToCart(${payload})'>Add to Bag</button>`
        }
      </div>
    </article>
  `;
}

function addToCart(product){
  const cart = readCart();
  const id = product.id || product.name;
  const found = cart.find(item => String(item.id || item.name) === String(id));

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

  saveCart(cart);
  toast("Added to bag");
}

window.addToCart = addToCart;
window.toggleMenu = toggleMenu;

async function renderShop(){
  const grid = document.querySelector("[data-products-grid]");
  if(!grid) return;

  const search = document.querySelector("[data-search]");
  const category = document.querySelector("[data-category]");
  const all = await getProducts();
  const sale = all.filter(isSaleProduct);

  if(category){
    const cats = ["All", ...new Set(sale.map(p => p.category).filter(Boolean))];
    category.innerHTML = cats.map(c => `<option>${c}</option>`).join("");
  }

  function draw(){
    const q = (search?.value || "").toLowerCase();
    const c = category?.value || "All";

    const list = sale.filter(p => {
      const text = `${p.name || ""} ${p.category || ""} ${p.description || ""}`.toLowerCase();
      return (c === "All" || p.category === c) && text.includes(q);
    });

    grid.innerHTML = list.length
      ? list.map(p => productCard(p, "sale")).join("")
      : `<div class="reza-empty">No products found.</div>`;
  }

  if(search) search.oninput = draw;
  if(category) category.onchange = draw;
  draw();
}

async function renderFeatured(){
  const grid = document.querySelector("[data-featured-products]");
  if(!grid) return;

  const all = await getProducts();
  const sale = all.filter(isSaleProduct);
  const selected = sale.filter(p => p.showFeatured === true).slice(0, 3);
  const finalList = selected.length ? selected : sale.slice(0, 3);

  grid.innerHTML = finalList.length
    ? finalList.map(p => productCard(p, "sale")).join("")
    : `<div class="reza-empty">No featured products selected yet.</div>`;
}

async function renderComingSoon(){
  const grid = document.querySelector("[data-coming-soon-products]");
  if(!grid) return;

  const all = await getProducts();
  const coming = all.filter(isComingSoon);

  grid.innerHTML = coming.length
    ? coming.map(p => productCard(p, "coming")).join("")
    : `<div class="reza-empty">No coming soon products yet.</div>`;
}

async function renderProductDetail(){
  const box = document.querySelector("[data-product-detail]");
  if(!box) return;

  const id = new URLSearchParams(location.search).get("id");
  const products = await getProducts();
  const p = products.find(x => String(x.id) === String(id));

  if(!p){
    box.innerHTML = `<div class="reza-empty">Product not found.</div>`;
    return;
  }

  box.innerHTML = `
    <section class="reza-detail">
      <div class="reza-detail-image">
        <img src="${img(p.image)}" alt="${p.name}">
      </div>
      <div class="reza-detail-info">
        <p class="eyebrow">${p.category || "Reza Holdings"}</p>
        <h1>${p.name}</h1>
        <p>${p.description || ""}</p>
        <h2>${money(p.price)}</h2>
        <button onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Bag</button>
      </div>
    </section>
  `;
}

function renderCart(){
  const box = document.querySelector("[data-cart-items]");
  const summary = document.querySelector("[data-cart-summary]");
  if(!box && !summary) return;

  const cart = readCart();
  const total = cart.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  if(box){
    box.innerHTML = cart.length ? cart.map((item, index) => {
      const qty = Number(item.qty || item.quantity || 1);
      return `
        <article class="reza-cart-item">
          <img src="${img(item.image)}" alt="${item.name}">
          <div>
            <h3>${item.name}</h3>
            <p>${money(item.price)}</p>
          </div>
          <div class="reza-qty">
            <button onclick="changeQty(${index}, -1)">−</button>
            <strong>${qty}</strong>
            <button onclick="changeQty(${index}, 1)">+</button>
          </div>
          <strong>${money(Number(item.price || 0) * qty)}</strong>
          <button class="remove" onclick="removeCartItem(${index})">Remove</button>
        </article>
      `;
    }).join("") : `
      <div class="reza-cart-empty">
        <h1>Your cart is empty</h1>
        <p>Add products before checkout.</p>
        <a href="shop.html">Shop Products</a>
      </div>
    `;
  }

  if(summary){
    summary.innerHTML = `
      <h2>Summary</h2>
      <div><span>Subtotal</span><strong>${money(total)}</strong></div>
      <div><span>Delivery</span><strong>Calculated after order</strong></div>
      <hr>
      <div class="total"><span>Total</span><strong>${money(total)}</strong></div>
      <a href="checkout.html">Checkout</a>
    `;
  }

  updateCartCount();
}

function changeQty(index, amount){
  const cart = readCart();
  if(!cart[index]) return;
  cart[index].qty = Math.max(1, Number(cart[index].qty || cart[index].quantity || 1) + amount);
  cart[index].quantity = cart[index].qty;
  saveCart(cart);
  renderCart();
}

function removeCartItem(index){
  const cart = readCart();
  cart.splice(index, 1);
  saveCart(cart);
  renderCart();
}

window.changeQty = changeQty;
window.removeCartItem = removeCartItem;

function renderCheckout(){
  const page = document.querySelector("[data-checkout-page]");
  if(!page) return;

  const cart = readCart();
  const total = cart.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  page.innerHTML = `
    <section class="page-hero">
      <div class="container">
        <p class="eyebrow">SECURE CHECKOUT</p>
        <h1>Checkout</h1>
        <p>Wix-style checkout. Delivery is calculated after order.</p>
      </div>
    </section>

    <section class="reza-checkout-wrap">
      <form class="reza-checkout-form" onsubmit="placeOrder(event)">
        <h2>Customer Information</h2>
        <input name="name" placeholder="Full name" required>
        <input name="phone" placeholder="Phone / WhatsApp" required>
        <input name="email" type="email" placeholder="Email address">

        <h2>Delivery Details</h2>
        <select name="country">
          <option>South Africa</option>
          <option>Botswana</option>
          <option>Zimbabwe</option>
          <option>Namibia</option>
          <option>Eswatini</option>
        </select>
        <input name="province" placeholder="Province / Region">
        <input name="city" placeholder="City">
        <input name="address" placeholder="Street address / collection details">
        <input name="paxiMall" placeholder="Paxi number / nearest mall">
        <textarea name="notes" placeholder="Order notes"></textarea>

        <button type="submit">Place Order</button>
      </form>

      <aside class="reza-checkout-summary">
        <h2>Order Summary</h2>
        ${
          cart.length ? cart.map(item => {
            const qty = Number(item.qty || item.quantity || 1);
            return `<div class="checkout-line"><span>${qty} × ${item.name}</span><strong>${money(Number(item.price || 0) * qty)}</strong></div>`;
          }).join("") : `<p>No cart items.</p>`
        }
        <hr>
        <div class="checkout-line total"><span>Total</span><strong>${money(total)}</strong></div>
      </aside>
    </section>
  `;
}

async function placeOrder(event){
  event.preventDefault();

  const cart = readCart();
  if(!cart.length){
    toast("Cart is empty");
    return;
  }

  const customer = Object.fromEntries(new FormData(event.target).entries());

  try{
    const data = await apiPost("/api/orders", { customer, items: cart });
    localStorage.removeItem("reza_cart");
    localStorage.removeItem("rezaCart");
    localStorage.removeItem("cart");
    localStorage.removeItem("reza_cart_items");
    localStorage.removeItem("reza_v11_cart");
    updateCartCount();
    alert("Order created: " + data.order.orderNumber);
    location.href = "index.html";
  }catch(error){
    alert("Order failed: " + error.message);
  }
}

window.placeOrder = placeOrder;

async function loadBranding(){
  try{
    const data = await apiGet("/api/media?t=" + Date.now());
    if(data.media && data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el => {
        el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }
    if(data.media && data.media.heroImage){
      const hero = document.querySelector(".hero-shopify");
      if(hero) hero.style.backgroundImage = `linear-gradient(90deg,rgba(255,248,238,.82),rgba(255,248,238,.22)), url("${img(data.media.heroImage)}")`;
    }
  }catch(e){}
}

async function popupOnce(){
  const path = location.pathname.toLowerCase();
  const isHome = path === "/" || path.endsWith("/index.html") || path.endsWith("/index");
  if(!isHome) return;

  const key = "reza_popup_seen_this_visit";
  if(sessionStorage.getItem(key) === "yes") return;

  try{
    const data = await apiGet("/api/popup?t=" + Date.now());
    const p = data.popup || {};
    if(!p.enabled) return;

    sessionStorage.setItem(key, "yes");

    const overlay = document.createElement("div");
    overlay.className = "reza-popup-overlay";
    overlay.innerHTML = `
      <div class="reza-popup-card">
        <button class="reza-popup-close" type="button">×</button>
        ${p.image ? `<img class="reza-popup-img" src="${img(p.image)}" alt="Special">` : ""}
        <p class="reza-popup-kicker">${p.category || "Specials"}</p>
        <h2>${p.title || "Special"}</h2>
        <p>${p.message || ""}</p>
        <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
      </div>
    `;
    document.body.appendChild(overlay);

    overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
    overlay.onclick = e => {
      if(e.target === overlay) overlay.remove();
    };
  }catch(e){}
}

document.addEventListener("DOMContentLoaded", () => {
  updateCartCount();
  loadBranding();
  renderShop().catch(console.warn);
  renderFeatured().catch(console.warn);
  renderComingSoon().catch(console.warn);
  renderProductDetail().catch(console.warn);
  renderCart();
  renderCheckout();
  setTimeout(popupOnce, 600);
});
JS

# ======================================================
# 3. CLEAN CSS FIX
# ======================================================
cat > frontend/assets/css/reza-core-fix.css <<'CSS'
.reza-toast{
  position:fixed;right:18px;bottom:18px;z-index:999999;
  background:#241812;color:#fff8ed;padding:14px 20px;border-radius:999px;
  font-weight:900;box-shadow:0 18px 50px rgba(0,0,0,.25);opacity:0;transform:translateY(10px);
  transition:.25s ease;
}
.reza-toast.show{opacity:1;transform:translateY(0)}

#cartCount,[data-count],[data-cart-count],.cart-count,.cart-badge,.bag-count{
  display:inline-flex!important;align-items:center!important;justify-content:center!important;
  min-width:24px!important;height:24px!important;border-radius:999px!important;
  font-weight:1000!important;
}

.reza-product-grid{
  width:min(1180px,calc(100% - 32px));
  margin:0 auto;
  display:grid;
  grid-template-columns:repeat(auto-fit,minmax(280px,1fr));
  gap:28px;
}

.reza-product-card{
  background:rgba(255,255,255,.96);
  border-radius:28px;
  overflow:hidden;
  box-shadow:0 20px 60px rgba(50,30,15,.12);
  display:flex;
  flex-direction:column;
}

.reza-product-image{
  position:relative;
  height:360px;
  background:#fff7ef;
  display:grid;
  place-items:center;
  overflow:hidden;
}

.reza-product-image img{
  width:100%;
  height:100%;
  object-fit:contain;
  object-position:center;
  display:block;
}

.reza-product-image span{
  position:absolute;
  top:15px;
  left:15px;
  z-index:2;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  padding:9px 15px;
  border-radius:999px;
  font-weight:1000;
  letter-spacing:.14em;
  text-transform:uppercase;
  font-size:.75rem;
}

.reza-product-body{
  padding:22px;
  display:flex;
  flex-direction:column;
  gap:10px;
  flex:1;
}

.reza-product-type{
  margin:0;
  color:#a87622;
  font-size:.78rem;
  font-weight:900;
  letter-spacing:.14em;
  text-transform:uppercase;
}

.reza-product-body h3{
  margin:0;
  color:#241812;
  font-size:1.25rem;
  line-height:1.12;
}

.reza-product-price{
  color:#9a6719;
  font-weight:1000;
  margin:0;
}

.reza-product-body button,
.reza-detail-info button{
  margin-top:auto;
  width:max-content;
  border:0;
  border-radius:999px;
  padding:13px 20px;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  font-weight:1000;
  cursor:pointer;
}

.reza-product-body button.muted{
  background:#2d2621;
  color:#fffaf2;
}

.reza-empty{
  grid-column:1/-1;
  padding:40px;
  text-align:center;
  font-weight:900;
  background:rgba(255,255,255,.78);
  border-radius:24px;
}

.shop-tools{
  width:min(1180px,calc(100% - 32px));
  margin:0 auto 28px;
  display:grid;
  grid-template-columns:1fr 260px;
  gap:16px;
}

.shop-tools input,.shop-tools select{
  width:100%;
  padding:16px 18px;
  border-radius:18px;
  border:1px solid rgba(0,0,0,.12);
}

.reza-cart-wrap{
  width:min(1200px,calc(100% - 32px));
  margin:50px auto;
  display:grid;
  grid-template-columns:1fr 380px;
  gap:26px;
}

.reza-cart-item{
  display:grid;
  grid-template-columns:90px 1fr auto auto auto;
  gap:16px;
  align-items:center;
  background:rgba(255,255,255,.92);
  border-radius:24px;
  padding:14px;
  margin-bottom:14px;
}

.reza-cart-item img{
  width:90px;height:90px;object-fit:cover;border-radius:18px;background:#fff7ef;
}

.reza-qty{
  display:flex;gap:8px;align-items:center;
}

.reza-qty button,.reza-cart-item .remove{
  border:0;border-radius:999px;padding:9px 13px;font-weight:900;cursor:pointer;
}

.reza-cart-item .remove{background:#241812;color:white}

.reza-cart-summary{
  background:rgba(255,255,255,.92);
  border-radius:28px;
  padding:24px;
  height:max-content;
}

.reza-cart-summary h2{
  font-family:Georgia,serif;
  font-size:2.5rem;
  margin:0 0 16px;
}

.reza-cart-summary div{
  display:flex;
  justify-content:space-between;
  gap:12px;
  margin:12px 0;
}

.reza-cart-summary .total{font-size:1.25rem}

.reza-cart-summary a,
.reza-cart-empty a{
  display:flex;
  justify-content:center;
  margin-top:18px;
  border-radius:999px;
  padding:14px 22px;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  font-weight:1000;
  text-decoration:none;
}

.reza-cart-empty{
  background:rgba(255,255,255,.8);
  border-radius:30px;
  padding:55px 22px;
  text-align:center;
}

.reza-cart-empty h1{
  font-family:Georgia,serif;
  font-size:clamp(3rem,8vw,5rem);
  margin:0;
}

.reza-checkout-wrap{
  width:min(1200px,calc(100% - 32px));
  margin:50px auto;
  display:grid;
  grid-template-columns:1fr 380px;
  gap:28px;
}

.reza-checkout-form,.reza-checkout-summary{
  background:rgba(255,255,255,.92);
  border-radius:28px;
  padding:24px;
  box-shadow:0 20px 60px rgba(50,30,15,.1);
}

.reza-checkout-form{
  display:grid;
  gap:14px;
}

.reza-checkout-form input,
.reza-checkout-form select,
.reza-checkout-form textarea{
  width:100%;
  padding:15px;
  border-radius:16px;
  border:1px solid rgba(0,0,0,.12);
}

.reza-checkout-form button{
  border:0;
  border-radius:999px;
  padding:15px 22px;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  font-weight:1000;
  cursor:pointer;
}

.checkout-line{
  display:flex;
  justify-content:space-between;
  gap:14px;
  margin:12px 0;
}

.checkout-line.total{font-size:1.25rem}

.reza-detail{
  width:min(1180px,calc(100% - 32px));
  margin:60px auto;
  display:grid;
  grid-template-columns:1fr 1fr;
  gap:34px;
  align-items:center;
}

.reza-detail-image{
  background:#fff7ef;
  border-radius:30px;
  padding:20px;
}

.reza-detail-image img{
  width:100%;
  max-height:560px;
  object-fit:contain;
}

.reza-popup-overlay{
  position:fixed;
  inset:0;
  background:rgba(0,0,0,.5);
  z-index:99999;
  display:grid;
  place-items:center;
  padding:22px;
}

.reza-popup-card{
  width:min(520px,100%);
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
  max-height:420px;
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
  border-radius:999px;
  padding:13px 20px;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  font-weight:1000;
  text-decoration:none;
}

@media(max-width:800px){
  .shop-tools,.reza-cart-wrap,.reza-checkout-wrap,.reza-detail{
    grid-template-columns:1fr;
  }

  .reza-product-image{height:310px}

  .reza-cart-item{
    grid-template-columns:76px 1fr;
  }

  .reza-cart-item img{
    width:76px;height:76px;
  }

  .reza-qty,.reza-cart-item > strong,.reza-cart-item .remove{
    grid-column:2;
  }
}
CSS

# ======================================================
# 4. CLEAN KEY PAGES
# ======================================================
cat > frontend/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Reza Holdings | Champagne Luxury</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a class="active" href="index.html">Home</a><a href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section class="hero-shopify">
      <div class="hero-content">
        <p class="eyebrow">PREMIUM SKINCARE & WELLNESS</p>
        <h1 class="mirror-gold-heading">Elevate. Bloom. Become.</h1>
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
      <div class="reza-product-grid" data-featured-products></div>
    </section>
  </main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p><a href="policies.html">Terms and Policies</a></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

cat > frontend/shop.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Catalog | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a href="index.html">Home</a><a class="active" href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section class="page-hero"><div class="container"><p class="eyebrow">SHOP</p><h1 class="mirror-gold-heading">All Products</h1><p>Search, choose and add your favourite Reza products to cart.</p></div></section>
    <div class="shop-tools"><input data-search placeholder="Search products..."><select data-category><option>All</option></select></div>
    <section class="reza-product-grid" data-products-grid></section>
  </main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

cat > frontend/coming-soon.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Coming Soon | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a href="index.html">Home</a><a href="shop.html">Catalog</a><a class="active" href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section class="page-hero"><div class="container"><p class="eyebrow">REZA HOLDINGS</p><h1 class="mirror-gold-heading">Coming Soon</h1><p>These products are being prepared for launch.</p></div></section>
    <section class="reza-product-grid" data-coming-soon-products></section>
  </main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

cat > frontend/cart.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Cart | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a href="index.html">Home</a><a href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main>
    <section class="page-hero"><div class="container"><p class="eyebrow">CART</p><h1 class="mirror-gold-heading">Your Cart</h1></div></section>
    <section class="reza-cart-wrap">
      <div data-cart-items></div>
      <aside class="reza-cart-summary" data-cart-summary></aside>
    </section>
  </main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

cat > frontend/checkout.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Checkout | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a href="index.html">Home</a><a href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main data-checkout-page></main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

cat > frontend/product.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Product | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">
  <link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">
</head>
<body>
  <div class="announcement">WELCOME TO OUR STORE</div>
  <header class="site-header">
    <a class="brand" href="index.html"><span class="logo">R</span><span><b>Reza Holdings</b><small>Champagne Luxury</small></span></a>
    <button class="menu-btn" onclick="toggleMenu()">☰</button>
    <nav id="mainNav" class="nav-links">
      <a href="index.html">Home</a><a href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a><a href="about.html">About</a><a href="contact.html">Contact</a><a href="policies.html">Policies</a>
    </nav>
    <a class="cart-btn" href="cart.html">🛍️ <span id="cartCount">0</span></a>
  </header>

  <main data-product-detail></main>

  <footer class="footer"><p>© 2026 Reza Holdings.</p></footer>
  <script src="site.js?v=clean1"></script>
</body>
</html>
HTML

# ======================================================
# 5. Clean old script/css tags from remaining simple pages
# ======================================================
python3 - <<'PY'
from pathlib import Path
import re

for p in [Path("frontend/about.html"), Path("frontend/contact.html"), Path("frontend/policies.html")]:
    if not p.exists():
        continue

    text = p.read_text()

    # remove old problematic scripts/css
    text = re.sub(r'\s*<script src="js/reza-[^"]+"></script>\s*', '\n', text)
    text = re.sub(r'\s*<script src="mobile-[^"]+"></script>\s*', '\n', text)
    text = re.sub(r'\s*<script src="reza-live.js"></script>\s*', '\n', text)
    text = re.sub(r'\s*<script src="site.js[^"]*"></script>\s*', '\n', text)
    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/reza-[^"]+">\s*', '\n', text)

    if "assets/css/reza-core-fix.css" not in text:
        text = text.replace("</head>", '<link rel="stylesheet" href="assets/css/reza-core-fix.css?v=clean1">\n</head>')

    text = text.replace("</body>", '<script src="site.js?v=clean1"></script>\n</body>')

    p.write_text(text)

print("Remaining pages cleaned.")
PY

# ======================================================
# 6. Commit and push
# ======================================================
git add .
git commit -m "Clean Reza V11 core cart checkout popup featured coming soon"
git push

echo "DONE. Redeploy backend and frontend."
