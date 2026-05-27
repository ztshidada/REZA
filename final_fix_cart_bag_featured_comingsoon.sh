#!/bin/bash
set -e

echo "Final fixing cart bag, cart page, featured products and coming soon images..."
echo "No product data will be reset."

mkdir -p frontend/js frontend/assets/css

# =========================================================
# 1. ONE CART SYSTEM FOR ALL PAGES
# =========================================================
cat > frontend/js/reza-cart-global.js <<'JS'
(function () {
  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];

  function readAnyCart() {
    for (const key of CART_KEYS) {
      try {
        const value = JSON.parse(localStorage.getItem(key) || "[]");
        if (Array.isArray(value) && value.length) return value;
      } catch {}
    }
    return [];
  }

  function saveEverywhere(cart) {
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    localStorage.setItem("reza_cart_items", JSON.stringify(cart));
    updateBagCount();
  }

  function updateBagCount() {
    const cart = readAnyCart();
    const count = cart.reduce((total, item) => total + Number(item.qty || item.quantity || 1), 0);

    document.querySelectorAll(
      ".cart-count,.cart-badge,.bag-count,[data-cart-count],#cartCount,#cart-count,#bagCount"
    ).forEach(el => {
      el.textContent = count;
    });

    document.querySelectorAll('a[href*="cart"], .cart-link, .bag-link').forEach(link => {
      link.setAttribute("href", "cart.html");
      link.setAttribute("data-count", count);
    });

    document.body.setAttribute("data-cart-count", count);
  }

  window.RezaCart = {
    read: readAnyCart,
    save: saveEverywhere,
    count: updateBagCount
  };

  window.addToCart = function (product) {
    const cart = readAnyCart();
    const id = product.id || product.name;
    const existing = cart.find(item => String(item.id || item.name) === String(id));

    if (existing) {
      existing.qty = Number(existing.qty || existing.quantity || 1) + 1;
      existing.quantity = existing.qty;
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

    saveEverywhere(cart);

    const toast = document.createElement("div");
    toast.className = "reza-cart-toast";
    toast.textContent = "Added to bag";
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 1600);
  };

  document.addEventListener("DOMContentLoaded", updateBagCount);
  window.addEventListener("load", updateBagCount);
  window.addEventListener("storage", updateBagCount);
})();
JS

cat > frontend/assets/css/reza-cart-global.css <<'CSS'
.reza-cart-toast{
  position:fixed;
  right:18px;
  bottom:18px;
  z-index:999999;
  background:#241812;
  color:#fff8ed;
  padding:14px 20px;
  border-radius:999px;
  font-weight:900;
  box-shadow:0 20px 55px rgba(0,0,0,.25);
}

/* make cart/bag count visible even where old design hides it */
.cart-count,
.cart-badge,
.bag-count,
[data-cart-count],
#cartCount,
#cart-count,
#bagCount{
  display:inline-flex !important;
  min-width:24px !important;
  height:24px !important;
  align-items:center !important;
  justify-content:center !important;
  border-radius:999px !important;
  background:#e5bd55 !important;
  color:#241812 !important;
  font-weight:1000 !important;
}
CSS

# =========================================================
# 2. FORCE CART PAGE TO DISPLAY SAVED CART
# =========================================================
cat > frontend/js/reza-cart-page-final.js <<'JS'
(function () {
  function money(value) {
    const n = Number(value || 0);
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function readCart() {
    if (window.RezaCart) return window.RezaCart.read();
    try { return JSON.parse(localStorage.getItem("reza_cart") || "[]"); }
    catch { return []; }
  }

  function saveCart(cart) {
    if (window.RezaCart) window.RezaCart.save(cart);
    else localStorage.setItem("reza_cart", JSON.stringify(cart));
  }

  function image(src) {
    return src || "assets/images/reza-card-bg.svg";
  }

  function getItemsBox() {
    return document.querySelector("#cartItems") ||
           document.querySelector(".cart-items") ||
           document.querySelector("#cartList") ||
           document.querySelector(".cart-list") ||
           document.querySelector("main");
  }

  function getSummaryBox() {
    return document.querySelector("#orderSummary") ||
           document.querySelector(".order-summary") ||
           document.querySelector(".summary");
  }

  function render() {
    const cart = readCart();
    const itemsBox = getItemsBox();
    const summaryBox = getSummaryBox();

    const subtotal = cart.reduce((sum, item) => {
      return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
    }, 0);

    if (!itemsBox) return;

    if (!cart.length) {
      itemsBox.innerHTML = `
        <section class="reza-cart-empty-box">
          <h1>Your cart is empty</h1>
          <p>Add products before checkout.</p>
          <a href="shop.html">Shop Products</a>
        </section>
      `;
    } else {
      itemsBox.innerHTML = `
        <section class="reza-cart-wrap">
          <div class="reza-cart-items">
            ${cart.map((item, index) => {
              const qty = Number(item.qty || item.quantity || 1);
              return `
                <article class="reza-cart-item">
                  <img src="${image(item.image)}" alt="${item.name || "Product"}">
                  <div>
                    <h3>${item.name || "Product"}</h3>
                    <p>${money(item.price || 0)}</p>
                  </div>
                  <div class="reza-cart-qty">
                    <button data-minus="${index}">−</button>
                    <strong>${qty}</strong>
                    <button data-plus="${index}">+</button>
                  </div>
                  <strong>${money(Number(item.price || 0) * qty)}</strong>
                  <button class="reza-cart-remove" data-remove="${index}">Remove</button>
                </article>
              `;
            }).join("")}
          </div>

          <aside class="reza-cart-summary-final">
            <h2>Summary</h2>
            <div><span>Subtotal</span><strong>${money(subtotal)}</strong></div>
            <div><span>Delivery</span><strong>Calculated after order</strong></div>
            <hr>
            <div class="total"><span>Total</span><strong>${money(subtotal)}</strong></div>
            <button>Checkout</button>
          </aside>
        </section>
      `;
    }

    if (summaryBox) {
      summaryBox.innerHTML = "";
    }

    document.querySelectorAll("[data-minus]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.minus);
        cart[i].qty = Math.max(1, Number(cart[i].qty || cart[i].quantity || 1) - 1);
        cart[i].quantity = cart[i].qty;
        saveCart(cart);
        render();
      };
    });

    document.querySelectorAll("[data-plus]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.plus);
        cart[i].qty = Number(cart[i].qty || cart[i].quantity || 1) + 1;
        cart[i].quantity = cart[i].qty;
        saveCart(cart);
        render();
      };
    });

    document.querySelectorAll("[data-remove]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.remove);
        cart.splice(i, 1);
        saveCart(cart);
        render();
      };
    });
  }

  document.addEventListener("DOMContentLoaded", render);
  window.addEventListener("load", render);
})();
JS

cat > frontend/assets/css/reza-cart-page-final.css <<'CSS'
.reza-cart-wrap{
  width:min(1200px,calc(100% - 32px));
  margin:60px auto;
  display:grid;
  grid-template-columns:1fr 380px;
  gap:26px;
}

.reza-cart-item{
  display:grid;
  grid-template-columns:90px 1fr auto auto auto;
  gap:16px;
  align-items:center;
  background:rgba(255,255,255,.9);
  border-radius:24px;
  padding:14px;
  margin-bottom:14px;
  box-shadow:0 18px 45px rgba(60,40,20,.08);
}

.reza-cart-item img{
  width:90px;
  height:90px;
  object-fit:cover;
  border-radius:18px;
  background:#fff7ef;
}

.reza-cart-item h3{
  margin:0 0 6px;
}

.reza-cart-qty{
  display:flex;
  gap:9px;
  align-items:center;
}

.reza-cart-qty button,
.reza-cart-remove{
  border:0;
  border-radius:999px;
  padding:9px 13px;
  font-weight:900;
  cursor:pointer;
}

.reza-cart-remove{
  background:#241812;
  color:white;
}

.reza-cart-summary-final{
  background:rgba(255,255,255,.9);
  border-radius:28px;
  padding:24px;
  height:max-content;
  box-shadow:0 18px 45px rgba(60,40,20,.08);
}

.reza-cart-summary-final h2{
  font-family:Georgia,serif;
  font-size:2.5rem;
  margin:0 0 16px;
}

.reza-cart-summary-final div{
  display:flex;
  justify-content:space-between;
  margin:13px 0;
}

.reza-cart-summary-final .total{
  font-size:1.3rem;
}

.reza-cart-summary-final button,
.reza-cart-empty-box a{
  width:100%;
  display:flex;
  justify-content:center;
  border:0;
  border-radius:999px;
  padding:15px 22px;
  background:linear-gradient(135deg,#edcf76,#c89532);
  color:#241812;
  font-weight:1000;
  text-decoration:none;
  cursor:pointer;
}

.reza-cart-empty-box{
  width:min(1000px,calc(100% - 32px));
  margin:80px auto;
  text-align:center;
  background:rgba(255,255,255,.78);
  border-radius:32px;
  padding:60px 24px;
}

.reza-cart-empty-box h1{
  font-family:Georgia,serif;
  font-size:clamp(3rem,8vw,5rem);
  margin:0;
}

.reza-cart-empty-box a{
  width:max-content;
  margin:20px auto 0;
}

@media(max-width:800px){
  .reza-cart-wrap{
    grid-template-columns:1fr;
  }

  .reza-cart-item{
    grid-template-columns:74px 1fr;
  }

  .reza-cart-item img{
    width:74px;
    height:74px;
  }

  .reza-cart-qty,
  .reza-cart-item > strong,
  .reza-cart-remove{
    grid-column:2;
  }
}
CSS

# =========================================================
# 3. PRODUCTS: featured selection + coming soon live images
# =========================================================
cat > frontend/js/reza-products-live-final.js <<'JS'
(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", { maximumFractionDigits: 0 });
  }

  function img(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function isComingSoon(p) {
    return p.status === "comingSoon" ||
           p.category === "Coming Soon" ||
           p.productType === "Coming Soon";
  }

  function isVisibleSale(p) {
    return p.showOnline !== false && !isComingSoon(p);
  }

  function card(p, coming = false) {
    return `
      <article class="reza-live-card">
        <div class="reza-live-img">
          <span>${coming ? "Coming Soon" : (p.productType || p.badge || "Product")}</span>
          <img src="${img(p.image)}" alt="${p.name}" loading="lazy">
        </div>
        <div class="reza-live-body">
          <p class="type">${p.category || ""}</p>
          <h3>${p.name || "Reza Product"}</h3>
          <p class="price">${coming ? "Coming Soon" : money(p.price)}</p>
          <p>${p.description || ""}</p>
          ${
            coming
              ? `<button type="button" class="muted">Coming Soon</button>`
              : `<button type="button" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Bag</button>`
          }
        </div>
      </article>
    `;
  }

  function allSaleGrids() {
    return [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid")
    ].filter(Boolean).filter(grid => {
      return grid.id !== "featuredProducts" &&
             !grid.classList.contains("featured-products") &&
             !grid.closest("[data-home-featured]");
    });
  }

  function featuredGrids() {
    return [
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")
    ].filter(Boolean);
  }

  function comingGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid"),
      document.querySelector("[data-coming-soon-products]")
    ].filter(Boolean);
  }

  async function load() {
    let products = [];
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      products = Array.isArray(data.products) ? data.products : [];
    } catch (error) {
      console.warn("Product load failed", error);
      return;
    }

    const sale = products.filter(isVisibleSale);
    const coming = products.filter(isComingSoon);

    const selectedFeatured = sale.filter(p => p.showFeatured === true).slice(0, 3);
    const featured = selectedFeatured.length ? selectedFeatured : sale.slice(0, 3);

    allSaleGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = sale.map(p => card(p, false)).join("") || `<p class="reza-empty">No products yet.</p>`;
    });

    featuredGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = featured.map(p => card(p, false)).join("") || `<p class="reza-empty">No featured products selected.</p>`;
    });

    comingGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = coming.map(p => card(p, true)).join("") || `<p class="reza-empty">No coming soon products yet.</p>`;
    });
  }

  document.addEventListener("DOMContentLoaded", load);
  window.addEventListener("load", load);
})();
JS

cat > frontend/assets/css/reza-products-live-final.css <<'CSS'
.reza-live-grid{
  display:grid !important;
  grid-template-columns:repeat(auto-fit,minmax(280px,1fr)) !important;
  gap:28px !important;
  width:min(1180px,calc(100% - 36px)) !important;
  margin-left:auto !important;
  margin-right:auto !important;
}

.reza-live-card{
  background:rgba(255,255,255,.96) !important;
  border-radius:28px !important;
  overflow:hidden !important;
  box-shadow:0 20px 60px rgba(50,30,15,.12) !important;
  display:flex !important;
  flex-direction:column !important;
}

.reza-live-img{
  height:360px !important;
  background:#fff7ef !important;
  position:relative !important;
  display:grid !important;
  place-items:center !important;
  overflow:hidden !important;
}

.reza-live-img img{
  width:100% !important;
  height:100% !important;
  object-fit:contain !important;
  object-position:center !important;
}

.reza-live-img span{
  position:absolute !important;
  top:15px !important;
  left:15px !important;
  background:linear-gradient(135deg,#edcf76,#c89532) !important;
  border-radius:999px !important;
  padding:9px 15px !important;
  color:#241812 !important;
  font-weight:1000 !important;
  letter-spacing:.14em !important;
  text-transform:uppercase !important;
  font-size:.75rem !important;
  z-index:2 !important;
}

.reza-live-body{
  padding:22px !important;
  display:flex !important;
  flex-direction:column !important;
  gap:10px !important;
  flex:1 !important;
}

.reza-live-body .type{
  color:#a87622 !important;
  font-weight:900 !important;
  letter-spacing:.14em !important;
  text-transform:uppercase !important;
  font-size:.78rem !important;
  margin:0 !important;
}

.reza-live-body h3{
  margin:0 !important;
  color:#241812 !important;
  font-size:1.25rem !important;
  line-height:1.12 !important;
}

.reza-live-body .price{
  color:#9a6719 !important;
  font-weight:1000 !important;
  margin:0 !important;
}

.reza-live-body button{
  margin-top:auto !important;
  width:max-content !important;
  border:0 !important;
  border-radius:999px !important;
  padding:13px 20px !important;
  background:linear-gradient(135deg,#edcf76,#c89532) !important;
  color:#241812 !important;
  font-weight:1000 !important;
  cursor:pointer !important;
}

.reza-live-body button.muted{
  background:#2d2621 !important;
  color:#fffaf2 !important;
}

@media(max-width:760px){
  .reza-live-grid{
    grid-template-columns:1fr !important;
    width:calc(100% - 28px) !important;
  }

  .reza-live-img{
    height:310px !important;
  }
}
CSS

# =========================================================
# 4. POPUP ONCE PER VISIT, HOME ONLY
# =========================================================
cat > frontend/js/reza-popup-session-final.js <<'JS'
(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const KEY = "reza_popup_seen_current_browser_session";

  function isHome() {
    const p = location.pathname.toLowerCase();
    return p === "/" || p.endsWith("/index.html") || p.endsWith("/index");
  }

  async function run() {
    if (!isHome()) return;
    if (sessionStorage.getItem(KEY) === "yes") return;

    try {
      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !data.popup || !data.popup.enabled) return;

      sessionStorage.setItem(KEY, "yes");

      const p = data.popup;
      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" class="reza-popup-img" alt="Special">` : ""}
          <p class="reza-popup-kicker">${p.category || "Specials"}</p>
          <h2>${p.title || "Special"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;
      document.body.appendChild(overlay);

      overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
      overlay.onclick = e => {
        if (e.target === overlay) overlay.remove();
      };
    } catch (error) {
      console.warn("Popup failed", error);
    }
  }

  document.addEventListener("DOMContentLoaded", () => setTimeout(run, 700));
})();
JS

# =========================================================
# 5. Inject clean scripts, remove old fighting scripts
# =========================================================
python3 - <<'PY'
from pathlib import Path
import re

remove_scripts = [
    "reza-products-render.js",
    "reza-products-final.js",
    "reza-products-master.js",
    "reza-products-live-final.js",
    "reza-cart-master.js",
    "reza-cart-page-final.js",
    "reza-cart-global.js",
    "reza-popup.js",
    "reza-popup-once.js",
    "reza-popup-session-final.js",
    "live-api.js",
]

remove_css = [
    "reza-products-final.css",
    "reza-products-master.css",
    "reza-products-live-final.css",
    "reza-cart-master.css",
    "reza-cart-page-final.css",
    "reza-cart-global.css",
]

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    for s in remove_scripts:
        text = re.sub(rf'\s*<script src="js/{re.escape(s)}[^"]*"></script>\s*', '\n', text)

    for c in remove_css:
        text = re.sub(rf'\s*<link rel="stylesheet" href="assets/css/{re.escape(c)}[^"]*">\s*', '\n', text)

    # bag/cart global on all pages
    text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-cart-global.css?v=final3">\n</head>')
    text = text.replace("</body>", '  <script src="js/reza-cart-global.js?v=final3"></script>\n</body>')

    # products on all pages
    text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-products-live-final.css?v=final3">\n</head>')
    text = text.replace("</body>", '  <script src="js/reza-products-live-final.js?v=final3"></script>\n</body>')

    # cart page only
    if p.name.lower() == "cart.html":
        text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-cart-page-final.css?v=final3">\n</head>')
        text = text.replace("</body>", '  <script src="js/reza-cart-page-final.js?v=final3"></script>\n</body>')

    # popup once per session
    text = text.replace("</body>", '  <script src="js/reza-popup-session-final.js?v=final3"></script>\n</body>')

    p.write_text(text, encoding="utf-8")
    print("Patched:", p)
PY

git add .
git commit -m "Final fix bag cart popup featured and coming soon display"
git push

echo "Done. Redeploy frontend. Backend/admin only if you did not deploy previous featured option patch."
