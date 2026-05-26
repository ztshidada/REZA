#!/bin/bash
set -e

echo "Fixing Reza product display properly..."

mkdir -p frontend/js frontend/assets/css

cat > frontend/js/reza-products-final.js <<'JS'
(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function img(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function addToCart(product) {
    const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
    const existing = cart.find(item => item.id === product.id);

    if (existing) existing.qty += 1;
    else cart.push({ ...product, qty: 1 });

    localStorage.setItem("reza_cart", JSON.stringify(cart));

    const count = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count]").forEach(el => {
      el.textContent = count;
    });

    alert("Added to cart");
  }

  window.addToCart = addToCart;

  function productCard(product, mode) {
    const isComing = mode === "coming";
    const badge = isComing ? "Coming Soon" : (product.badge || "On Sale");

    return `
      <article class="reza-final-product-card">
        <div class="reza-final-product-image-wrap">
          <span class="reza-final-badge">${badge}</span>
          <img
            src="${img(product.image)}"
            alt="${product.name || "Reza product"}"
            loading="lazy"
            class="reza-final-product-image"
          >
        </div>

        <div class="reza-final-product-body">
          <p class="reza-final-product-type">${product.productType || product.category || ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-final-price">${isComing ? "Coming Soon" : money(product.price)}</p>
          <p class="reza-final-description">${product.description || ""}</p>

          ${
            isComing
              ? `<button class="reza-final-btn muted" type="button">Coming Soon</button>`
              : `<button class="reza-final-btn" type="button" onclick='addToCart(${JSON.stringify(product).replace(/'/g, "&apos;")})'>Add to Cart</button>`
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
      document.querySelector(".product-grid"),
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products")
    ].filter(Boolean);
  }

  function findComingSoonGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid")
    ].filter(Boolean);
  }

  async function renderProducts() {
    try {
      const response = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await response.json();

      if (!data.success || !Array.isArray(data.products)) return;

      const all = data.products;

      const saleProducts = all.filter(product => {
        return product.status !== "comingSoon" &&
               product.category !== "Coming Soon" &&
               product.showOnline !== false;
      });

      const comingProducts = all.filter(product => {
        return product.status === "comingSoon" ||
               product.category === "Coming Soon" ||
               product.productType === "Coming Soon";
      });

      const saleGrids = findSaleGrids();
      const comingGrids = findComingSoonGrids();

      saleGrids.forEach(grid => {
        grid.classList.add("reza-final-products-grid");

        const isHomeFeatured =
          grid.id === "featuredProducts" ||
          grid.classList.contains("featured-products");

        const productsToShow = isHomeFeatured ? saleProducts.slice(0, 3) : saleProducts;

        grid.innerHTML = productsToShow.length
          ? productsToShow.map(product => productCard(product, "sale")).join("")
          : `<p class="reza-final-empty">No products available yet.</p>`;
      });

      comingGrids.forEach(grid => {
        grid.classList.add("reza-final-products-grid");

        grid.innerHTML = comingProducts.length
          ? comingProducts.map(product => productCard(product, "coming")).join("")
          : `<p class="reza-final-empty">No coming soon products yet.</p>`;
      });

    } catch (error) {
      console.warn("Reza product render failed:", error);
    }
  }

  document.addEventListener("DOMContentLoaded", renderProducts);
  window.addEventListener("load", renderProducts);
})();
JS

cat > frontend/assets/css/reza-products-final.css <<'CSS'
/* Reza final product display fix */

.reza-final-products-grid,
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
  align-items: stretch !important;
  width: min(1180px, calc(100% - 36px)) !important;
  margin-left: auto !important;
  margin-right: auto !important;
  overflow: visible !important;
}

.reza-final-product-card {
  background: rgba(255,255,255,.92) !important;
  border: 1px solid rgba(0,0,0,.08) !important;
  border-radius: 28px !important;
  overflow: hidden !important;
  box-shadow: 0 18px 55px rgba(50,30,15,.12) !important;
  display: flex !important;
  flex-direction: column !important;
  min-height: 100% !important;
}

.reza-final-product-image-wrap {
  position: relative !important;
  width: 100% !important;
  background: #fff7ee !important;
  border-radius: 28px 28px 0 0 !important;
  overflow: hidden !important;
  height: 360px !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
}

.reza-final-product-image {
  width: 100% !important;
  height: 100% !important;
  object-fit: contain !important;
  object-position: center !important;
  display: block !important;
  background: #fff7ee !important;
}

.reza-final-badge {
  position: absolute !important;
  top: 16px !important;
  left: 16px !important;
  z-index: 5 !important;
  background: linear-gradient(135deg,#e8c774,#c89334) !important;
  color: #241812 !important;
  padding: 9px 15px !important;
  border-radius: 999px !important;
  font-weight: 1000 !important;
  font-size: .78rem !important;
  letter-spacing: .14em !important;
  text-transform: uppercase !important;
}

.reza-final-product-body {
  padding: 22px !important;
  display: flex !important;
  flex-direction: column !important;
  gap: 10px !important;
  flex: 1 !important;
}

.reza-final-product-type {
  margin: 0 !important;
  color: #a67724 !important;
  font-size: .78rem !important;
  font-weight: 900 !important;
  letter-spacing: .14em !important;
  text-transform: uppercase !important;
}

.reza-final-product-body h3 {
  margin: 0 !important;
  color: #241812 !important;
  font-size: 1.25rem !important;
  line-height: 1.12 !important;
  font-weight: 1000 !important;
}

.reza-final-price {
  margin: 0 !important;
  color: #9a6719 !important;
  font-size: 1.1rem !important;
  font-weight: 1000 !important;
}

.reza-final-description {
  margin: 0 !important;
  color: #4f443d !important;
  line-height: 1.55 !important;
  font-size: .96rem !important;
}

.reza-final-btn {
  margin-top: auto !important;
  border: 0 !important;
  border-radius: 999px !important;
  padding: 13px 20px !important;
  background: linear-gradient(135deg,#e8c774,#c89334) !important;
  color: #241812 !important;
  font-weight: 1000 !important;
  cursor: pointer !important;
  width: max-content !important;
}

.reza-final-btn.muted {
  background: #241812 !important;
  color: #fffaf2 !important;
}

.reza-final-empty {
  grid-column: 1 / -1 !important;
  text-align: center !important;
  font-weight: 900 !important;
  padding: 40px !important;
}

/* Kill old product image rules that crop posters */
.product-card img,
.product-img img,
.product-card .product-img img {
  object-fit: contain !important;
  object-position: center !important;
}

/* Phone */
@media (max-width: 760px) {
  .reza-final-products-grid,
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
    gap: 22px !important;
  }

  .reza-final-product-image-wrap {
    height: 300px !important;
  }

  .reza-final-product-body {
    padding: 18px !important;
  }

  .reza-final-btn {
    padding: 12px 18px !important;
    font-size: .9rem !important;
  }
}
CSS

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    # Remove old product renderers that fight with this one
    text = re.sub(r'\s*<script src="js/live-api\.js[^"]*"></script>\s*', '\n', text)
    text = re.sub(r'\s*<script src="js/reza-products-render\.js[^"]*"></script>\s*', '\n', text)
    text = re.sub(r'\s*<script src="js/reza-products-final\.js[^"]*"></script>\s*', '\n', text)

    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/reza-products-final\.css[^"]*">\s*', '\n', text)

    text = text.replace(
      "</head>",
      '  <link rel="stylesheet" href="assets/css/reza-products-final.css?v=final-products-1">\n</head>'
    )

    text = text.replace(
      "</body>",
      '  <script src="js/reza-products-final.js?v=final-products-1"></script>\n</body>'
    )

    p.write_text(text, encoding="utf-8")
    print("Patched:", p)
PY

git add .
git commit -m "Fix final product card display and stop old render conflict"
git push

echo "Done. Redeploy reza-frontend only."
