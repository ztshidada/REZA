#!/bin/bash
set -e

echo "🛍️ Forcing frontend to render live backend products..."

mkdir -p frontend/js

cat > frontend/js/reza-products-live-final.js <<'JS'
(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function formatMoney(value) {
    return "R " + Number(value || 0).toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function findProductContainer() {
    const selectors = [
      "#productsGrid",
      "#productGrid",
      "#featuredProducts",
      ".products-grid",
      ".product-grid",
      ".featured-products",
      ".luxury-products",
      ".products"
    ];

    for (const selector of selectors) {
      const el = document.querySelector(selector);
      if (el) return el;
    }

    const allSections = [...document.querySelectorAll("section, div")];
    const luxurySection = allSections.find(el =>
      el.innerText &&
      el.innerText.toLowerCase().includes("luxury picks")
    );

    if (luxurySection) {
      let grid = luxurySection.querySelector(".reza-live-products-grid");
      if (!grid) {
        grid = document.createElement("div");
        grid.className = "reza-live-products-grid";
        luxurySection.appendChild(grid);
      }
      return grid;
    }

    return null;
  }

  function productCard(p) {
    return `
      <article class="reza-live-card">
        <div class="reza-live-img-wrap">
          ${p.badge ? `<span class="reza-live-badge">${p.badge}</span>` : ""}
          <img src="${imageUrl(p.image)}" alt="${p.name}">
        </div>

        <div class="reza-live-info">
          <p class="reza-live-cat">${p.category || "Reza Holdings"}</p>
          <h3>${p.name || "Product"}</h3>
          <p class="reza-live-price">${formatMoney(p.price)}</p>
          <p class="reza-live-desc">${p.description || ""}</p>

          <button class="reza-live-btn" type="button"
            data-product='${JSON.stringify(p).replace(/'/g, "&apos;")}'>
            Add to Cart
          </button>
        </div>
      </article>
    `;
  }

  async function loadProducts() {
    const container = findProductContainer();

    if (!container) {
      console.warn("Reza products container not found.");
      return;
    }

    container.classList.add("reza-live-products-grid");
    container.innerHTML = `<div class="reza-live-loading">Loading products...</div>`;

    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !Array.isArray(data.products)) {
        container.innerHTML = `<div class="reza-live-empty">Products could not load.</div>`;
        return;
      }

      const products = data.products.filter(p => p.showOnline !== false);

      if (!products.length) {
        container.innerHTML = `<div class="reza-live-empty">No products found.</div>`;
        return;
      }

      container.innerHTML = products.map(productCard).join("");

      container.querySelectorAll(".reza-live-btn").forEach(btn => {
        btn.addEventListener("click", () => {
          const product = JSON.parse(btn.dataset.product.replace(/&apos;/g, "'"));
          const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
          const existing = cart.find(item => item.id === product.id);

          if (existing) existing.qty += 1;
          else cart.push({ ...product, qty: 1 });

          localStorage.setItem("reza_cart", JSON.stringify(cart));

          const badge = document.querySelector(".cart-count, #cartCount, .cart-badge");
          if (badge) badge.textContent = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);

          alert("Added to cart");
        });
      });

      console.log("✅ Reza live products rendered:", products.length);
    } catch (error) {
      console.error(error);
      container.innerHTML = `<div class="reza-live-empty">Could not connect to products API.</div>`;
    }
  }

  document.addEventListener("DOMContentLoaded", loadProducts);
  window.addEventListener("load", loadProducts);
})();
JS

cat >> frontend/css/app.css <<'CSS'

/* FINAL — Live backend products grid */
.reza-live-products-grid {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)) !important;
  gap: 28px !important;
  width: min(1180px, calc(100% - 40px));
  margin: 28px auto !important;
}

.reza-live-card {
  overflow: hidden;
  border-radius: 30px;
  background: rgba(255,255,255,.82);
  border: 1px solid rgba(120,80,40,.12);
  box-shadow: 0 24px 70px rgba(90,55,25,.13);
}

.reza-live-img-wrap {
  position: relative;
  height: 270px;
  background: #f7ead9;
  overflow: hidden;
}

.reza-live-img-wrap img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.reza-live-badge {
  position: absolute;
  top: 16px;
  left: 16px;
  z-index: 2;
  padding: 10px 16px;
  border-radius: 999px;
  background: #d4a247;
  color: #241812;
  font-weight: 900;
}

.reza-live-info {
  padding: 22px;
}

.reza-live-cat {
  color: #9b6b25;
  font-weight: 900;
  letter-spacing: .12em;
  text-transform: uppercase;
  font-size: .75rem;
}

.reza-live-info h3 {
  margin: 8px 0;
  font-size: 1.5rem;
}

.reza-live-price {
  font-size: 1.35rem;
  font-weight: 1000;
  color: #8a5b19;
}

.reza-live-desc {
  color: #5e5047;
  line-height: 1.6;
}

.reza-live-btn {
  width: 100%;
  border: 0;
  border-radius: 999px;
  padding: 15px 20px;
  margin-top: 14px;
  cursor: pointer;
  font-weight: 1000;
  background: linear-gradient(135deg, #f0c96f, #c9943d);
  color: #241812;
}

.reza-live-loading,
.reza-live-empty {
  grid-column: 1 / -1;
  padding: 30px;
  border-radius: 24px;
  background: rgba(255,255,255,.75);
  text-align: center;
  font-weight: 900;
}
CSS

python3 - <<'PY'
from pathlib import Path

for p in Path("frontend").glob("*.html"):
    text = p.read_text()
    if "js/reza-products-live-final.js" not in text:
        text = text.replace("</body>", '  <script src="js/reza-products-live-final.js"></script>\n</body>')
        p.write_text(text)
        print("Injected final products renderer into", p)
PY

git add .
git commit -m "Force customer frontend to render live backend products"
git push

echo "✅ Done. Redeploy reza-frontend only."
