#!/bin/bash
set -e

echo "Fixing cart, popup once per session, coming soon images, and featured selection..."
echo "No products will be reset."

mkdir -p frontend/js frontend/assets/css

# ---------------------------------------------------------
# 1. Backend: add featured field safely without resetting products
# ---------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
text = p.read_text()

# Add showFeatured support into rezaCleanProduct if function exists
if "showFeatured" not in text and "function rezaCleanProduct" in text:
    text = text.replace(
        "showOnline: body.showOnline !== false,",
        "showOnline: body.showOnline !== false,\n    showFeatured: body.showFeatured === true,"
    )

# If showFeatured exists in body but old cleanProduct does not preserve it properly
if "showFeatured: body.showFeatured === true" not in text and "showOnline: body.showOnline !== false" in text:
    text = text.replace(
        "showOnline: body.showOnline !== false,",
        "showOnline: body.showOnline !== false,\n    showFeatured: body.showFeatured === true,"
    )

p.write_text(text)
print("Backend featured field checked.")
PY

# ---------------------------------------------------------
# 2. Admin Products: add Featured/Home field without replacing page
# ---------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import re

p = Path("admin/products.html")
text = p.read_text()

# Add select field if missing
if 'id="showFeatured"' not in text:
    text = text.replace(
        '<select id="showOnline">',
        '''<select id="showFeatured">
          <option value="false">Do not show on homepage featured</option>
          <option value="true">Show on homepage featured</option>
        </select>
        <select id="showOnline">'''
    )

# Add clear default
if '$("showFeatured").value = "false";' not in text:
    text = text.replace(
        '$("showOnline").value = "true";',
        '$("showFeatured").value = "false";\n  $("showOnline").value = "true";'
    )

# Add edit load
if '$("showFeatured").value = String(Boolean(p.showFeatured));' not in text:
    text = text.replace(
        '$("showOnline").value = String(p.showOnline !== false);',
        '$("showFeatured").value = String(Boolean(p.showFeatured));\n  $("showOnline").value = String(p.showOnline !== false);'
    )

# Add payload
if 'showFeatured: $("showFeatured").value === "true"' not in text:
    text = text.replace(
        'showOnline: $("showOnline").value === "true",',
        'showOnline: $("showOnline").value === "true",\n      showFeatured: $("showFeatured").value === "true",'
    )

# Add table column header
if "<th>Featured</th>" not in text:
    text = text.replace(
        "<th>Show</th>",
        "<th>Featured</th>\n            <th>Show</th>"
    )

# Add table cell after price
if '${p.showFeatured ? "⭐ Featured" : "—"}' not in text:
    text = text.replace(
        '<td>${money(p.price)}</td>\n      <td>${p.showOnline !== false ? "👁️ Visible" : "🙈 Hidden"}</td>',
        '<td>${money(p.price)}</td>\n      <td>${p.showFeatured ? "⭐ Featured" : "—"}</td>\n      <td>${p.showOnline !== false ? "👁️ Visible" : "🙈 Hidden"}</td>'
    )

p.write_text(text)
print("Admin products featured option patched.")
PY

# ---------------------------------------------------------
# 3. Frontend Product Renderer: preserve images, featured = only selected 3
# ---------------------------------------------------------
cat > frontend/js/reza-products-master.js <<'JS'
(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];

  function readCart() {
    for (const key of CART_KEYS) {
      try {
        const data = JSON.parse(localStorage.getItem(key) || "[]");
        if (Array.isArray(data) && data.length) return data;
      } catch {}
    }
    return [];
  }

  function saveCart(cart) {
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    updateCartCount();
  }

  function updateCartCount() {
    const cart = readCart();
    const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);

    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],.bag-count").forEach(el => {
      el.textContent = count;
    });

    const cartLinks = document.querySelectorAll('a[href*="cart"], .cart-link, .bag-link');
    cartLinks.forEach(el => {
      if (!el.querySelector(".cart-count") && !el.querySelector(".bag-count")) {
        el.setAttribute("data-count", count);
      }
    });
  }

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  window.addToCart = function(product) {
    const cart = readCart();
    const existing = cart.find(item => item.id === product.id);

    if (existing) {
      existing.qty = Number(existing.qty || existing.quantity || 1) + 1;
      existing.quantity = existing.qty;
    } else {
      cart.push({
        id: product.id,
        name: product.name,
        price: Number(product.price || 0),
        image: product.image || "",
        category: product.category || "",
        productType: product.productType || "",
        qty: 1,
        quantity: 1
      });
    }

    saveCart(cart);
    alert("Added to cart");
  };

  function productCard(product, mode) {
    const coming = mode === "coming";
    const badge = coming ? "Coming Soon" : (product.badge || product.productType || "On Sale");

    return `
      <article class="reza-master-card">
        <div class="reza-master-imgbox">
          <span>${badge}</span>
          <img src="${imageUrl(product.image)}" alt="${product.name}" loading="lazy">
        </div>
        <div class="reza-master-body">
          <p class="reza-master-type">${product.category || ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-master-price">${coming ? "Coming Soon" : money(product.price)}</p>
          <p>${product.description || ""}</p>
          ${
            coming
              ? `<button type="button" class="reza-master-btn muted">Coming Soon</button>`
              : `<button type="button" class="reza-master-btn" onclick='addToCart(${JSON.stringify(product).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  function findSaleGrids() {
    return [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid")
    ].filter(Boolean);
  }

  function findFeaturedGrids() {
    return [
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")
    ].filter(Boolean);
  }

  function findComingGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid"),
      document.querySelector("[data-coming-soon-products]")
    ].filter(Boolean);
  }

  async function loadProducts() {
    updateCartCount();

    let products = [];
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      products = Array.isArray(data.products) ? data.products : [];
    } catch (error) {
      console.warn("Products failed to load", error);
      return;
    }

    const visibleSale = products.filter(p =>
      p.showOnline !== false &&
      p.status !== "comingSoon" &&
      p.category !== "Coming Soon" &&
      p.productType !== "Coming Soon"
    );

    const comingSoon = products.filter(p =>
      p.status === "comingSoon" ||
      p.category === "Coming Soon" ||
      p.productType === "Coming Soon"
    );

    const featuredSelected = visibleSale.filter(p => p.showFeatured === true).slice(0, 3);
    const featuredFallback = visibleSale.slice(0, 3);
    const featured = featuredSelected.length ? featuredSelected : featuredFallback;

    findSaleGrids().forEach(grid => {
      if (grid.id === "featuredProducts" || grid.classList.contains("featured-products")) return;
      grid.classList.add("reza-master-grid");
      grid.innerHTML = visibleSale.length
        ? visibleSale.map(p => productCard(p, "sale")).join("")
        : `<p class="reza-empty">No products available yet.</p>`;
    });

    findFeaturedGrids().forEach(grid => {
      grid.classList.add("reza-master-grid");
      grid.innerHTML = featured.length
        ? featured.map(p => productCard(p, "sale")).join("")
        : `<p class="reza-empty">No featured products selected yet.</p>`;
    });

    findComingGrids().forEach(grid => {
      grid.classList.add("reza-master-grid");
      grid.innerHTML = comingSoon.length
        ? comingSoon.map(p => productCard(p, "coming")).join("")
        : `<p class="reza-empty">No coming soon products yet.</p>`;
    });
  }

  document.addEventListener("DOMContentLoaded", loadProducts);
  window.addEventListener("load", loadProducts);
})();
JS

cat > frontend/assets/css/reza-products-master.css <<'CSS'
.reza-master-grid,
.products-grid,
.product-grid,
#productsGrid,
#productGrid,
#featuredProducts,
.featured-products,
#comingSoonGrid,
.coming-soon-grid {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)) !important;
  gap: 28px !important;
  width: min(1180px, calc(100% - 36px)) !important;
  margin-left: auto !important;
  margin-right: auto !important;
  overflow: visible !important;
}

.reza-master-card {
  background: rgba(255,255,255,.96) !important;
  border: 1px solid rgba(0,0,0,.08) !important;
  border-radius: 28px !important;
  overflow: hidden !important;
  display: flex !important;
  flex-direction: column !important;
  box-shadow: 0 20px 60px rgba(50,30,15,.12) !important;
}

.reza-master-imgbox {
  position: relative !important;
  width: 100% !important;
  height: 360px !important;
  background: #fff7ef !important;
  overflow: hidden !important;
  display: grid !important;
  place-items: center !important;
}

.reza-master-imgbox img {
  width: 100% !important;
  height: 100% !important;
  object-fit: contain !important;
  object-position: center !important;
  display: block !important;
}

.reza-master-imgbox span {
  position: absolute !important;
  top: 16px !important;
  left: 16px !important;
  z-index: 2 !important;
  background: linear-gradient(135deg,#edcf76,#c89532) !important;
  color: #251812 !important;
  border-radius: 999px !important;
  padding: 9px 16px !important;
  font-size: .76rem !important;
  letter-spacing: .16em !important;
  text-transform: uppercase !important;
  font-weight: 1000 !important;
}

.reza-master-body {
  padding: 22px !important;
  display: flex !important;
  flex-direction: column !important;
  gap: 10px !important;
  flex: 1 !important;
}

.reza-master-type {
  margin: 0 !important;
  color: #a87622 !important;
  font-size: .78rem !important;
  font-weight: 900 !important;
  letter-spacing: .14em !important;
  text-transform: uppercase !important;
}

.reza-master-body h3 {
  margin: 0 !important;
  font-size: 1.25rem !important;
  line-height: 1.12 !important;
  color: #241812 !important;
}

.reza-master-price {
  margin: 0 !important;
  font-weight: 1000 !important;
  color: #9a6719 !important;
  font-size: 1.08rem !important;
}

.reza-master-body p {
  line-height: 1.5 !important;
}

.reza-master-btn {
  margin-top: auto !important;
  width: max-content !important;
  border: 0 !important;
  border-radius: 999px !important;
  padding: 13px 20px !important;
  background: linear-gradient(135deg,#edcf76,#c89532) !important;
  color: #241812 !important;
  font-weight: 1000 !important;
  cursor: pointer !important;
}

.reza-master-btn.muted {
  background: #2d2621 !important;
  color: #fffaf2 !important;
}

.reza-empty {
  grid-column: 1 / -1 !important;
  text-align: center !important;
  font-weight: 900 !important;
  padding: 40px !important;
}

@media(max-width: 760px) {
  .reza-master-grid,
  .products-grid,
  .product-grid,
  #productsGrid,
  #productGrid,
  #featuredProducts,
  .featured-products,
  #comingSoonGrid,
  .coming-soon-grid {
    grid-template-columns: 1fr !important;
    width: calc(100% - 28px) !important;
  }

  .reza-master-imgbox {
    height: 310px !important;
  }
}
CSS

# ---------------------------------------------------------
# 4. Cart page: force cart.html to read the same cart keys
# ---------------------------------------------------------
cat > frontend/js/reza-cart-master.js <<'JS'
(function () {
  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];

  function readCart() {
    for (const key of CART_KEYS) {
      try {
        const data = JSON.parse(localStorage.getItem(key) || "[]");
        if (Array.isArray(data) && data.length) return data;
      } catch {}
    }
    return [];
  }

  function saveCart(cart) {
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    updateCartCount(cart);
  }

  function money(value) {
    const n = Number(value || 0);
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function updateCartCount(cart = readCart()) {
    const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],.bag-count").forEach(el => {
      el.textContent = count;
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    return src;
  }

  function findCartContainer() {
    return (
      document.querySelector("#cartItems") ||
      document.querySelector(".cart-items") ||
      document.querySelector("#cartList") ||
      document.querySelector(".cart-list")
    );
  }

  function findSummaryContainer() {
    return (
      document.querySelector("#orderSummary") ||
      document.querySelector(".order-summary") ||
      document.querySelector(".summary")
    );
  }

  function renderCart() {
    const cart = readCart();
    updateCartCount(cart);

    const itemBox = findCartContainer();
    const summaryBox = findSummaryContainer();

    const subtotal = cart.reduce((sum, item) => {
      return sum + (Number(item.price || 0) * Number(item.qty || item.quantity || 1));
    }, 0);

    if (!cart.length) {
      document.body.classList.add("reza-cart-empty-state");
      if (itemBox) {
        itemBox.innerHTML = `
          <div class="reza-cart-empty">
            <h1>Your cart is empty</h1>
            <p>Add products before checkout.</p>
            <a href="shop.html">Shop Products</a>
          </div>
        `;
      }
    } else {
      document.body.classList.remove("reza-cart-empty-state");
      if (itemBox) {
        itemBox.innerHTML = cart.map((item, index) => {
          const qty = Number(item.qty || item.quantity || 1);
          return `
            <div class="reza-cart-row">
              <img src="${imageUrl(item.image)}" alt="${item.name || "Product"}">
              <div>
                <h3>${item.name || "Product"}</h3>
                <p>${money(item.price || 0)}</p>
              </div>
              <div class="reza-cart-controls">
                <button type="button" data-minus="${index}">−</button>
                <strong>${qty}</strong>
                <button type="button" data-plus="${index}">+</button>
              </div>
              <strong>${money(Number(item.price || 0) * qty)}</strong>
              <button type="button" data-remove="${index}" class="reza-remove">Remove</button>
            </div>
          `;
        }).join("");

        itemBox.querySelectorAll("[data-minus]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.minus);
            cart[i].qty = Math.max(1, Number(cart[i].qty || cart[i].quantity || 1) - 1);
            cart[i].quantity = cart[i].qty;
            saveCart(cart);
            renderCart();
          };
        });

        itemBox.querySelectorAll("[data-plus]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.plus);
            cart[i].qty = Number(cart[i].qty || cart[i].quantity || 1) + 1;
            cart[i].quantity = cart[i].qty;
            saveCart(cart);
            renderCart();
          };
        });

        itemBox.querySelectorAll("[data-remove]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.remove);
            cart.splice(i, 1);
            saveCart(cart);
            renderCart();
          };
        });
      }
    }

    if (summaryBox) {
      summaryBox.innerHTML = `
        <h2>Summary</h2>
        <div class="reza-summary-line"><span>Subtotal</span><strong>${money(subtotal)}</strong></div>
        <div class="reza-summary-line"><span>Delivery</span><strong>Calculated after order</strong></div>
        <hr>
        <div class="reza-summary-line total"><span>Total</span><strong>${money(subtotal)}</strong></div>
        <button type="button" class="reza-checkout-btn">Checkout</button>
      `;
    }
  }

  document.addEventListener("DOMContentLoaded", renderCart);
  window.addEventListener("load", renderCart);
})();
JS

cat > frontend/assets/css/reza-cart-master.css <<'CSS'
.reza-cart-row {
  display: grid !important;
  grid-template-columns: 90px 1fr auto auto auto !important;
  gap: 16px !important;
  align-items: center !important;
  background: rgba(255,255,255,.86) !important;
  border-radius: 22px !important;
  padding: 14px !important;
  margin-bottom: 14px !important;
}

.reza-cart-row img {
  width: 90px !important;
  height: 90px !important;
  object-fit: cover !important;
  border-radius: 18px !important;
  background: #fff7ef !important;
}

.reza-cart-row h3 {
  margin: 0 0 6px !important;
}

.reza-cart-controls {
  display: flex !important;
  gap: 8px !important;
  align-items: center !important;
}

.reza-cart-controls button,
.reza-remove {
  border: 0 !important;
  border-radius: 999px !important;
  padding: 8px 12px !important;
  cursor: pointer !important;
  font-weight: 900 !important;
}

.reza-remove {
  background: #2d2621 !important;
  color: white !important;
}

.reza-cart-empty {
  text-align: center !important;
  background: rgba(255,255,255,.78) !important;
  border-radius: 30px !important;
  padding: 55px 22px !important;
}

.reza-cart-empty h1 {
  font-family: Georgia, serif !important;
  font-size: clamp(3rem, 8vw, 5rem) !important;
  margin: 0 !important;
}

.reza-cart-empty a,
.reza-checkout-btn {
  display: inline-flex !important;
  justify-content: center !important;
  align-items: center !important;
  margin-top: 18px !important;
  border: 0 !important;
  border-radius: 999px !important;
  padding: 14px 24px !important;
  background: linear-gradient(135deg,#edcf76,#c89532) !important;
  color: #241812 !important;
  font-weight: 1000 !important;
  text-decoration: none !important;
  cursor: pointer !important;
}

.reza-summary-line {
  display: flex !important;
  justify-content: space-between !important;
  gap: 14px !important;
  margin: 12px 0 !important;
}

.reza-summary-line.total {
  font-size: 1.25rem !important;
}

@media(max-width: 760px) {
  .reza-cart-row {
    grid-template-columns: 76px 1fr !important;
  }

  .reza-cart-controls,
  .reza-cart-row > strong,
  .reza-remove {
    grid-column: 2 !important;
  }
}
CSS

# ---------------------------------------------------------
# 5. Popup: once per browser session only
# ---------------------------------------------------------
cat > frontend/js/reza-popup-once.js <<'JS'
(function(){
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const SESSION_KEY = "reza_popup_seen_this_visit";

  function isHomePage() {
    const path = location.pathname.toLowerCase();
    return path === "/" || path.endsWith("/index.html") || path === "";
  }

  async function loadPopup(){
    try {
      if (!isHomePage()) return;
      if (sessionStorage.getItem(SESSION_KEY) === "yes") return;

      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !data.popup || !data.popup.enabled) return;

      const p = data.popup;
      sessionStorage.setItem(SESSION_KEY, "yes");

      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" alt="Special" class="reza-popup-img">` : ""}
          <p class="reza-popup-kicker">${p.category || "Specials"}</p>
          <h2>${p.title || "Special Announcement"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;

      document.body.appendChild(overlay);

      overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
      overlay.addEventListener("click", e => {
        if (e.target === overlay) overlay.remove();
      });
    } catch (err) {
      console.warn("Popup not loaded", err);
    }
  }

  document.addEventListener("DOMContentLoaded", () => setTimeout(loadPopup, 800));
})();
JS

# ---------------------------------------------------------
# 6. Inject final scripts last, remove old fighting scripts
# ---------------------------------------------------------
python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    # Remove old product/cart/popup scripts that fight each other
    remove_patterns = [
        r'\s*<script src="js/reza-products-render\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-products-final\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-products-master\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-cart-master\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-popup\.js[^"]*"></script>\s*',
        r'\s*<script src="js/reza-popup-once\.js[^"]*"></script>\s*',
        r'\s*<script src="js/live-api\.js[^"]*"></script>\s*',
    ]

    remove_css = [
        r'\s*<link rel="stylesheet" href="assets/css/reza-products-final\.css[^"]*">\s*',
        r'\s*<link rel="stylesheet" href="assets/css/reza-products-master\.css[^"]*">\s*',
        r'\s*<link rel="stylesheet" href="assets/css/reza-cart-master\.css[^"]*">\s*',
    ]

    for pat in remove_patterns + remove_css:
        text = re.sub(pat, '\n', text)

    if "assets/css/reza-products-master.css" not in text:
        text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-products-master.css?v=master2">\n</head>')

    if "assets/css/reza-cart-master.css" not in text:
        text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-cart-master.css?v=master2">\n</head>')

    # Keep existing popup css if already there, otherwise add
    if "assets/css/reza-popup.css" not in text:
        text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-popup.css?v=master2">\n</head>')

    # Product renderer on all pages
    text = text.replace("</body>", '  <script src="js/reza-products-master.js?v=master2"></script>\n</body>')

    # Cart renderer only on cart page
    if p.name.lower() == "cart.html":
        text = text.replace("</body>", '  <script src="js/reza-cart-master.js?v=master2"></script>\n</body>')

    # Popup once on all pages, but script itself only opens on home
    text = text.replace("</body>", '  <script src="js/reza-popup-once.js?v=master2"></script>\n</body>')

    p.write_text(text, encoding="utf-8")
    print("Patched:", p)
PY

git add .
git commit -m "Fix cart persistence popup once and featured product selection"
git push

echo "Done. Redeploy backend, admin, and frontend."
