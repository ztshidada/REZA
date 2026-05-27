#!/bin/bash
set -e

echo "Applying Reza Manyora products + cart + popup once fix..."

mkdir -p frontend/assets/images/products
mkdir -p frontend/assets/css
mkdir -p frontend/js
mkdir -p backend/data

# Copy product/special images into frontend public assets
cp -f reza-manyora-products-cart-popup-fix/assets/* frontend/assets/images/products/ 2>/dev/null || true

python3 - <<'PY'
from pathlib import Path
import json
from datetime import datetime

products_file = Path("backend/data/products.json")
products_file.parent.mkdir(parents=True, exist_ok=True)

try:
    existing = json.loads(products_file.read_text())
    if not isinstance(existing, list):
        existing = []
except Exception:
    existing = []

def img(name):
    return f"https://rezaholdings.co.za/assets/images/products/{name}"

new_products = [
    {
        "id": "manyora-special",
        "name": "Manyora Special",
        "category": "Specials",
        "productType": "Special",
        "status": "sale",
        "price": 12500,
        "stock": 0,
        "badge": "Special",
        "image": img("manyora-special.jpg"),
        "description": "Limited time Reza skincare special. Best value for your skin.",
        "showOnline": True,
        "showInPopup": True
    },
    {
        "id": "bozza-special",
        "name": "Bozza Special",
        "category": "Specials",
        "productType": "Special",
        "status": "sale",
        "price": 2500,
        "stock": 0,
        "badge": "Special",
        "image": img("bozza-special.jpg"),
        "description": "Buy 10 bottles each and get 5 bottles of cream free.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "complete-anti-ageing-skin-combo",
        "name": "Complete Anti-Ageing Skin Combo",
        "category": "Combos",
        "productType": "Combo",
        "status": "sale",
        "price": 480,
        "stock": 0,
        "badge": "Combo",
        "image": img("complete-anti-ageing-skin-combo.jpg"),
        "description": "Complete anti-ageing skin combo for youthful, firm and glowing skin.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "starter-pack-combo-2500",
        "name": "Starter Pack Combo",
        "category": "Combos",
        "productType": "Combo",
        "status": "sale",
        "price": 2500,
        "stock": 0,
        "badge": "Starter Pack",
        "image": img("starter-pack-combo-2500.jpg"),
        "description": "30 premium products. One complete skincare routine.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "reza-anti-ageing-power-combo",
        "name": "Reza Anti-Ageing Power Combo",
        "category": "Combos",
        "productType": "Combo",
        "status": "sale",
        "price": 2000,
        "stock": 0,
        "badge": "Power Combo",
        "image": img("complete-anti-ageing-skin-combo-2.jpg"),
        "description": "10 lotions plus 10 creams. Powerful anti-ageing combo.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "timeless-beauty-combo",
        "name": "Timeless Beauty Combo",
        "category": "Combos",
        "productType": "Combo",
        "status": "sale",
        "price": 400,
        "stock": 0,
        "badge": "Combo",
        "image": img("timeless-beauty-combo.jpg"),
        "description": "The perfect duo for younger, healthier-looking skin.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "reza-anti-ageing-lotion",
        "name": "Reza Anti-Ageing Lotion",
        "category": "Singles",
        "productType": "Single",
        "status": "sale",
        "price": 200,
        "stock": 0,
        "badge": "Single",
        "image": img("anti-ageing-lotion.jpg"),
        "description": "Firms, hydrates and renews for visibly youthful radiant skin.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "reza-collagen-anti-ageing-cream",
        "name": "Reza Collagen Anti-Ageing Cream",
        "category": "Singles",
        "productType": "Single",
        "status": "sale",
        "price": 200,
        "stock": 0,
        "badge": "Single",
        "image": img("anti-ageing-cream.jpg"),
        "description": "Youthful, firming and radiant collagen anti-ageing cream.",
        "showOnline": True,
        "showInPopup": False
    },
    {
        "id": "reza-tissue-oil-business-pack",
        "name": "Reza Tissue Oil Business Pack",
        "category": "10 Pack",
        "productType": "Pack of 10",
        "status": "sale",
        "price": 500,
        "stock": 0,
        "badge": "Business Pack",
        "image": img("tissue-oil-business-pack.jpg"),
        "description": "Start a business with 10 bottles. Low investment and high opportunity.",
        "showOnline": True,
        "showInPopup": False
    }
]

by_id = {p.get("id"): p for p in existing if p.get("id")}
for p in new_products:
    p["updatedAt"] = datetime.utcnow().isoformat() + "Z"
    by_id[p["id"]] = p

products = list(by_id.values())
products_file.write_text(json.dumps(products, indent=2))
print(f"Saved {len(products)} products to backend/data/products.json")

popup = {
    "enabled": True,
    "category": "Specials",
    "title": "Manyora Special",
    "message": "Limited time Reza skincare special. Best value for your skin.",
    "buttonText": "Shop Manyora",
    "buttonLink": "shop.html",
    "image": img("manyora-special.jpg"),
    "updatedAt": datetime.utcnow().isoformat() + "Z"
}
Path("backend/data/popup.json").write_text(json.dumps(popup, indent=2))
print("Saved Manyora popup to backend/data/popup.json")
PY

python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
if not p.exists():
    raise SystemExit("backend/src/server.js not found")

text = p.read_text()

if 'const fs = require("fs")' not in text and "const fs = require('fs')" not in text:
    text = 'const fs = require("fs");\n' + text
if 'const path = require("path")' not in text and "const path = require('path')" not in text:
    text = 'const path = require("path");\n' + text

text = text.replace("app.use(express.json());", 'app.use(express.json({ limit: "100mb" }));')

api = r'''
// ======================================================
// REZA PRODUCTS + POPUP JSON API
// ======================================================
const REZA_DATA_DIR = path.join(__dirname, "../data");
const REZA_PRODUCTS_FILE = path.join(REZA_DATA_DIR, "products.json");
const REZA_POPUP_FILE = path.join(REZA_DATA_DIR, "popup.json");

function rezaEnsureData() {
  fs.mkdirSync(REZA_DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_PRODUCTS_FILE)) fs.writeFileSync(REZA_PRODUCTS_FILE, "[]");
  if (!fs.existsSync(REZA_POPUP_FILE)) {
    fs.writeFileSync(REZA_POPUP_FILE, JSON.stringify({
      enabled:false, category:"Specials", title:"", message:"",
      buttonText:"Shop Now", buttonLink:"shop.html", image:""
    }, null, 2));
  }
}
function rezaRead(file, fallback) {
  try { rezaEnsureData(); return JSON.parse(fs.readFileSync(file, "utf8")); }
  catch(e) { return fallback; }
}
function rezaWrite(file, data) {
  rezaEnsureData();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}
function rezaSlug(value) {
  return String(value || "product").toLowerCase().trim()
    .replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}
function rezaProductPayload(body, current = {}) {
  const name = body.name || current.name || "New Product";
  return {
    ...current,
    id: current.id || body.id || `${rezaSlug(name)}-${Date.now()}`,
    name,
    category: body.category || current.category || "Singles",
    productType: body.productType || current.productType || "Single",
    status: body.status || current.status || "sale",
    price: Number(body.price ?? current.price ?? 0),
    stock: Number(body.stock ?? current.stock ?? 0),
    badge: body.badge ?? current.badge ?? "",
    image: body.image ?? current.image ?? "",
    description: body.description ?? current.description ?? "",
    showOnline: body.showOnline !== undefined ? Boolean(body.showOnline) : (current.showOnline !== false),
    showInPopup: body.showInPopup !== undefined ? Boolean(body.showInPopup) : Boolean(current.showInPopup),
    updatedAt: new Date().toISOString()
  };
}

app.get("/api/products", (req, res) => {
  res.json({ success:true, products: rezaRead(REZA_PRODUCTS_FILE, []) });
});
app.post("/api/products", (req, res) => {
  const products = rezaRead(REZA_PRODUCTS_FILE, []);
  const product = rezaProductPayload(req.body || {});
  products.push(product);
  rezaWrite(REZA_PRODUCTS_FILE, products);
  res.json({ success:true, message:"Product added", product, products });
});
app.put("/api/products/:id", (req, res) => {
  const products = rezaRead(REZA_PRODUCTS_FILE, []);
  const i = products.findIndex(p => p.id === req.params.id);
  if (i < 0) return res.status(404).json({ success:false, message:"Product not found" });
  products[i] = rezaProductPayload(req.body || {}, products[i]);
  rezaWrite(REZA_PRODUCTS_FILE, products);
  res.json({ success:true, message:"Product updated", product: products[i], products });
});
app.patch("/api/products/:id/toggle", (req, res) => {
  const products = rezaRead(REZA_PRODUCTS_FILE, []);
  const p = products.find(p => p.id === req.params.id);
  if (!p) return res.status(404).json({ success:false, message:"Product not found" });
  p.showOnline = !p.showOnline;
  p.updatedAt = new Date().toISOString();
  rezaWrite(REZA_PRODUCTS_FILE, products);
  res.json({ success:true, message:p.showOnline ? "Product visible" : "Product hidden", product:p, products });
});
app.delete("/api/products/:id", (req, res) => {
  const products = rezaRead(REZA_PRODUCTS_FILE, []).filter(p => p.id !== req.params.id);
  rezaWrite(REZA_PRODUCTS_FILE, products);
  res.json({ success:true, message:"Product deleted", products });
});

app.get("/api/popup", (req, res) => {
  res.json({ success:true, popup: rezaRead(REZA_POPUP_FILE, {}) });
});
app.post("/api/popup", (req, res) => {
  const popup = {
    enabled: Boolean(req.body.enabled),
    category: req.body.category || "Specials",
    title: req.body.title || "",
    message: req.body.message || "",
    buttonText: req.body.buttonText || "Shop Now",
    buttonLink: req.body.buttonLink || "shop.html",
    image: req.body.image || "",
    updatedAt: new Date().toISOString()
  };
  rezaWrite(REZA_POPUP_FILE, popup);
  res.json({ success:true, message:"Popup saved", popup });
});
// ======================================================
// END REZA PRODUCTS + POPUP JSON API
// ======================================================
'''

if "REZA PRODUCTS + POPUP JSON API" not in text and "REZA V11 PRODUCTS + POPUP ADMIN API" not in text:
    marker = "app.listen("
    idx = text.find(marker)
    if idx >= 0:
        text = text[:idx] + api + "\n\n" + text[idx:]
    else:
        text += "\n\n" + api

p.write_text(text)
print("Backend checked.")
PY

cat > frontend/js/reza-cart-system.js <<'JS'
(function(){
  const CART_KEYS = ["reza_cart", "rezaCart", "cart"];

  function readCart(){
    for(const key of CART_KEYS){
      try{
        const value = JSON.parse(localStorage.getItem(key) || "[]");
        if(Array.isArray(value) && value.length) return value;
      }catch(e){}
    }
    return [];
  }

  function writeCart(cart){
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    updateCartCount();
  }

  function normaliseProduct(product){
    const id = product.id || product.sku || product.name?.toLowerCase().replace(/[^a-z0-9]+/g, "-") || ("product-" + Date.now());
    return {
      id,
      name: product.name || "Reza Product",
      price: Number(product.price || 0),
      image: product.image || "",
      category: product.category || "",
      productType: product.productType || "",
      qty: Number(product.qty || 1)
    };
  }

  window.addToCart = function(product){
    const cart = readCart();
    const item = normaliseProduct(product || {});
    const existing = cart.find(x => x.id === item.id);

    if(existing) existing.qty = Number(existing.qty || 1) + 1;
    else cart.push(item);

    writeCart(cart);
    showToast(`${item.name} added to cart`);
  };

  window.rezaRemoveCartItem = function(id){
    writeCart(readCart().filter(item => item.id !== id));
    renderCartPage();
  };

  window.rezaChangeCartQty = function(id, change){
    const cart = readCart();
    const item = cart.find(x => x.id === id);
    if(item){
      item.qty = Math.max(1, Number(item.qty || 1) + change);
      writeCart(cart);
      renderCartPage();
    }
  };

  function updateCartCount(){
    const count = readCart().reduce((sum,item)=>sum + Number(item.qty || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],#cartCount").forEach(el => {
      el.textContent = count;
    });
  }

  function money(v){
    const n = Number(v || 0);
    return "R " + n.toLocaleString("en-ZA", {minimumFractionDigits:0, maximumFractionDigits:0});
  }

  function showToast(message){
    let toast = document.querySelector(".reza-cart-toast");
    if(!toast){
      toast = document.createElement("div");
      toast.className = "reza-cart-toast";
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add("show");
    setTimeout(()=>toast.classList.remove("show"), 2200);
  }

  function findCartTarget(){
    return document.querySelector("#cartItems") ||
           document.querySelector("#cartList") ||
           document.querySelector(".cart-items") ||
           document.querySelector(".cart-list") ||
           document.querySelector("[data-cart-items]");
  }

  function renderCartPage(){
    const isCartPage = /cart\.html/i.test(location.pathname) || document.querySelector("[data-cart-page]");
    if(!isCartPage) {
      updateCartCount();
      return;
    }

    let target = findCartTarget();

    if(!target){
      const main = document.querySelector("main") || document.body;
      target = document.createElement("section");
      target.className = "reza-cart-page-box";
      target.setAttribute("data-cart-items", "true");
      main.appendChild(target);
    }

    const cart = readCart();
    const subtotal = cart.reduce((sum,item)=>sum + Number(item.price || 0) * Number(item.qty || 1), 0);

    if(!cart.length){
      target.innerHTML = `
        <div class="reza-empty-cart">
          <h2>Your cart is empty</h2>
          <p>Add products from the catalog and they will appear here.</p>
          <a href="shop.html">Shop Products</a>
        </div>
      `;
    } else {
      target.innerHTML = `
        <div class="reza-cart-table">
          ${cart.map(item => `
            <div class="reza-cart-row">
              <img src="${item.image || "assets/images/reza-card-bg.svg"}" alt="${item.name}">
              <div>
                <h3>${item.name}</h3>
                <p>${item.category || ""} ${item.productType ? "• " + item.productType : ""}</p>
                <strong>${money(item.price)}</strong>
              </div>
              <div class="reza-cart-qty">
                <button onclick="rezaChangeCartQty('${item.id}', -1)">−</button>
                <span>${item.qty || 1}</span>
                <button onclick="rezaChangeCartQty('${item.id}', 1)">+</button>
              </div>
              <button class="reza-cart-remove" onclick="rezaRemoveCartItem('${item.id}')">Remove</button>
            </div>
          `).join("")}
        </div>
        <div class="reza-cart-summary">
          <p>Subtotal <strong>${money(subtotal)}</strong></p>
          <p>Delivery <strong>Calculated after order</strong></p>
          <hr>
          <p class="total">Total <strong>${money(subtotal)}</strong></p>
          <a href="checkout.html">Checkout</a>
        </div>
      `;
    }

    document.querySelectorAll(".cart-subtotal,[data-cart-subtotal]").forEach(el => el.textContent = money(subtotal));
    document.querySelectorAll(".cart-total,[data-cart-total]").forEach(el => el.textContent = money(subtotal));
    updateCartCount();
  }

  document.addEventListener("DOMContentLoaded", () => {
    updateCartCount();
    renderCartPage();
  });
  window.addEventListener("storage", () => {
    updateCartCount();
    renderCartPage();
  });
})();
JS

cat > frontend/assets/css/reza-cart-system.css <<'CSS'
.reza-cart-toast{position:fixed;right:18px;bottom:18px;z-index:999999;background:#241812;color:#fffaf2;padding:14px 18px;border-radius:999px;font-weight:900;opacity:0;transform:translateY(18px);pointer-events:none;transition:.25s ease}
.reza-cart-toast.show{opacity:1;transform:translateY(0)}
.reza-cart-page-box{width:min(1100px,calc(100% - 32px));margin:40px auto;display:grid;grid-template-columns:1.4fr .8fr;gap:24px}
.reza-cart-table,.reza-cart-summary,.reza-empty-cart{background:#fff;border-radius:28px;padding:22px;box-shadow:0 20px 60px rgba(50,30,15,.12)}
.reza-cart-row{display:grid;grid-template-columns:110px 1fr auto auto;gap:16px;align-items:center;padding:16px 0;border-bottom:1px solid #eee}
.reza-cart-row img{width:110px;height:90px;object-fit:contain;border-radius:16px;background:#fff7ee}
.reza-cart-row h3{margin:0 0 6px;font-size:1.05rem}.reza-cart-row p{margin:0 0 8px;color:#6f625b}
.reza-cart-qty{display:flex;gap:8px;align-items:center}.reza-cart-qty button,.reza-cart-remove{border:0;border-radius:999px;padding:9px 12px;font-weight:900;cursor:pointer}
.reza-cart-qty button{background:#f1ddb9}.reza-cart-remove{background:#241812;color:#fffaf2}
.reza-cart-summary p{display:flex;justify-content:space-between;gap:16px}.reza-cart-summary .total{font-size:1.3rem;font-weight:1000}
.reza-cart-summary a,.reza-empty-cart a{display:flex;justify-content:center;margin-top:16px;padding:14px 20px;border-radius:999px;background:linear-gradient(135deg,#e8c774,#c89334);color:#241812;font-weight:1000;text-decoration:none}
@media(max-width:760px){.reza-cart-page-box{grid-template-columns:1fr;width:calc(100% - 24px)}.reza-cart-row{grid-template-columns:82px 1fr;gap:12px}.reza-cart-row img{width:82px;height:82px}.reza-cart-qty,.reza-cart-remove{grid-column:2}}
CSS

cat > frontend/js/reza-popup.js <<'JS'
(function(){
  const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
  const POPUP_KEY = "reza_popup_seen_this_visit";

  async function loadPopup(){
    try{
      if(sessionStorage.getItem(POPUP_KEY) === "yes") return;
      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();
      if(!data.success || !data.popup || !data.popup.enabled) return;

      const p = data.popup;
      sessionStorage.setItem(POPUP_KEY, "yes");

      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" alt="${p.title || "Special"}" class="reza-popup-img">` : ""}
          <p class="reza-popup-kicker">${p.category || "Reza Special"}</p>
          <h2>${p.title || "Special Announcement"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;
      document.body.appendChild(overlay);
      const close = () => overlay.remove();
      overlay.querySelector(".reza-popup-close").onclick = close;
      overlay.addEventListener("click", e => { if(e.target === overlay) close(); });
    }catch(err){ console.warn("Popup not loaded", err); }
  }
  document.addEventListener("DOMContentLoaded", () => setTimeout(loadPopup, 1000));
})();
JS

cat > frontend/assets/css/reza-popup.css <<'CSS'
.reza-popup-overlay{position:fixed;inset:0;z-index:99999;background:rgba(20,14,10,.58);backdrop-filter:blur(10px);display:grid;place-items:center;padding:18px}
.reza-popup-card{width:min(560px,94vw);max-height:92vh;overflow:auto;background:linear-gradient(135deg,#fffaf2,#f1dcc0);border-radius:28px;padding:20px;position:relative;box-shadow:0 30px 90px rgba(0,0,0,.28);color:#241812}
.reza-popup-close{position:absolute;top:12px;right:12px;width:40px;height:40px;border:0;border-radius:50%;background:#241812;color:#fff;font-size:24px;cursor:pointer;z-index:2}
.reza-popup-img{width:100%;max-height:62vh;object-fit:contain;border-radius:20px;background:#fff7ee}
.reza-popup-kicker{text-transform:uppercase;letter-spacing:.22em;color:#a87622;font-weight:900;font-size:.75rem}
.reza-popup-card h2{font-family:Georgia,serif;font-size:2.25rem;margin:8px 0 8px}
.reza-popup-card a{display:inline-flex;margin-top:12px;padding:13px 20px;border-radius:999px;background:linear-gradient(135deg,#e8c774,#c89334);color:#241812;font-weight:1000;text-decoration:none}
@media(max-width:500px){.reza-popup-card h2{font-size:1.8rem}.reza-popup-img{max-height:56vh}}
CSS

cat > frontend/js/reza-products-final.js <<'JS'
(function () {
  const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  function productImage(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function card(product, mode) {
    const coming = mode === "coming";
    const safeProduct = {
      id: product.id,
      name: product.name,
      price: Number(product.price || 0),
      image: productImage(product.image),
      category: product.category || "",
      productType: product.productType || ""
    };
    return `
      <article class="reza-final-product-card">
        <div class="reza-final-product-image-wrap">
          <span class="reza-final-badge">${coming ? "Coming Soon" : (product.badge || product.category || "On Sale")}</span>
          <img class="reza-final-product-image" src="${productImage(product.image)}" alt="${product.name || "Reza product"}" loading="lazy">
        </div>
        <div class="reza-final-product-body">
          <p class="reza-final-product-type">${product.category || ""} ${product.productType ? "• " + product.productType : ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-final-price">${coming ? "Coming Soon" : money(product.price)}</p>
          <p class="reza-final-description">${product.description || ""}</p>
          ${
            coming
              ? `<button class="reza-final-btn muted" type="button">Coming Soon</button>`
              : `<button class="reza-final-btn" type="button" onclick='addToCart(${JSON.stringify(safeProduct).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  function grids(list) {
    return list.map(s => document.querySelector(s)).filter(Boolean);
  }

  async function render() {
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !Array.isArray(data.products)) return;

      const products = data.products;
      const sale = products.filter(p => p.showOnline !== false && p.status !== "comingSoon" && p.category !== "Coming Soon" && p.productType !== "Coming Soon");
      const coming = products.filter(p => p.status === "comingSoon" || p.category === "Coming Soon" || p.productType === "Coming Soon");

      const saleGrids = grids(["#productsGrid","#productGrid",".products-grid",".product-grid","#featuredProducts",".featured-products"]);
      const comingGrids = grids(["#comingSoonGrid","#comingSoonProducts",".coming-soon-grid"]);

      saleGrids.forEach(g => {
        g.classList.add("reza-final-products-grid");
        const isFeatured = g.id === "featuredProducts" || g.classList.contains("featured-products");
        const items = isFeatured ? sale.slice(0,3) : sale;
        g.innerHTML = items.map(p => card(p, "sale")).join("") || `<p class="reza-final-empty">No products available yet.</p>`;
      });

      comingGrids.forEach(g => {
        g.classList.add("reza-final-products-grid");
        g.innerHTML = coming.map(p => card(p, "coming")).join("") || `<p class="reza-final-empty">No coming soon products yet.</p>`;
      });
    } catch(e) { console.warn("Product render failed", e); }
  }

  document.addEventListener("DOMContentLoaded", render);
  window.addEventListener("load", render);
})();
JS

cat > frontend/assets/css/reza-products-final.css <<'CSS'
.reza-final-products-grid,.products-grid,.product-grid,#productsGrid,#productGrid,#featuredProducts,.featured-products,#comingSoonGrid,.coming-soon-grid{display:grid!important;grid-template-columns:repeat(auto-fit,minmax(280px,1fr))!important;gap:28px!important;width:min(1180px,calc(100% - 36px))!important;margin-left:auto!important;margin-right:auto!important;overflow:visible!important}
.reza-final-product-card{background:rgba(255,255,255,.94)!important;border:1px solid rgba(0,0,0,.08)!important;border-radius:28px!important;overflow:hidden!important;box-shadow:0 18px 55px rgba(50,30,15,.12)!important;display:flex!important;flex-direction:column!important}
.reza-final-product-image-wrap{position:relative!important;width:100%!important;background:#fff7ee!important;overflow:hidden!important;height:360px!important;display:flex!important;align-items:center!important;justify-content:center!important}
.reza-final-product-image{width:100%!important;height:100%!important;object-fit:contain!important;object-position:center!important;display:block!important;background:#fff7ee!important}
.reza-final-badge{position:absolute!important;top:16px!important;left:16px!important;z-index:5!important;background:linear-gradient(135deg,#e8c774,#c89334)!important;color:#241812!important;padding:9px 15px!important;border-radius:999px!important;font-weight:1000!important;font-size:.78rem!important;letter-spacing:.12em!important;text-transform:uppercase!important}
.reza-final-product-body{padding:22px!important;display:flex!important;flex-direction:column!important;gap:10px!important;flex:1!important}
.reza-final-product-type{margin:0!important;color:#a67724!important;font-size:.78rem!important;font-weight:900!important;letter-spacing:.12em!important;text-transform:uppercase!important}
.reza-final-product-body h3{margin:0!important;color:#241812!important;font-size:1.25rem!important;line-height:1.12!important;font-weight:1000!important}
.reza-final-price{margin:0!important;color:#9a6719!important;font-size:1.1rem!important;font-weight:1000!important}.reza-final-description{margin:0!important;color:#4f443d!important;line-height:1.55!important;font-size:.96rem!important}
.reza-final-btn{margin-top:auto!important;border:0!important;border-radius:999px!important;padding:13px 20px!important;background:linear-gradient(135deg,#e8c774,#c89334)!important;color:#241812!important;font-weight:1000!important;cursor:pointer!important;width:max-content!important}.reza-final-btn.muted{background:#241812!important;color:#fffaf2!important}
.reza-final-empty{grid-column:1/-1!important;text-align:center!important;font-weight:900!important;padding:40px!important}
.product-card img,.product-img img,.product-card .product-img img{object-fit:contain!important;object-position:center!important}
@media(max-width:760px){.reza-final-products-grid,.products-grid,.product-grid,#productsGrid,#productGrid,#featuredProducts,.featured-products,#comingSoonGrid,.coming-soon-grid{grid-template-columns:1fr!important;width:calc(100% - 28px)!important;gap:22px!important}.reza-final-product-image-wrap{height:300px!important}.reza-final-product-body{padding:18px!important}}
CSS

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")
    for pattern in [
        r'\s*<script src="js/live-api\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-products-render\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-products-final\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-cart-system\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-popup\.js[^"]*"></script>\s*',
        r'\s*<link rel="stylesheet" href="assets/css/reza-products-final\.css[^"]*">\s*',
        r'\s*<link rel="stylesheet" href="assets/css/reza-cart-system\.css[^"]*">\s*',
        r'\s*<link rel="stylesheet" href="assets/css/reza-popup\.css[^"]*">\s*',
    ]:
        text = re.sub(pattern, "\n", text)
    text = text.replace("</head>", '''  <link rel="stylesheet" href="assets/css/reza-products-final.css?v=manyora1">
  <link rel="stylesheet" href="assets/css/reza-cart-system.css?v=manyora1">
  <link rel="stylesheet" href="assets/css/reza-popup.css?v=manyora1">
</head>''')
    text = text.replace("</body>", '''  <script src="js/reza-cart-system.js?v=manyora1"></script>
  <script src="js/reza-products-final.js?v=manyora1"></script>
  <script src="js/reza-popup.js?v=manyora1"></script>
</body>''')
    p.write_text(text, encoding="utf-8")
    print("Injected:", p)
PY

git add .
git commit -m "Add Manyora special products fix cart and popup once"
git push

echo "Done. Redeploy backend, admin_frontend and reza-frontend."
