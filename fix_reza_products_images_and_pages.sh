#!/bin/bash
set -e

echo "Fixing product images, sale products, and coming soon products..."

mkdir -p frontend/assets/images/products
mkdir -p backend/data

# Copy product images from the pack if they exist
if [ -d "reza-products-pack/products" ]; then
  cp reza-products-pack/products/* frontend/assets/images/products/ 2>/dev/null || true
fi

if [ -d "reza-products-pack/assets/images/products" ]; then
  cp reza-products-pack/assets/images/products/* frontend/assets/images/products/ 2>/dev/null || true
fi

# Also copy any product-looking images from project root pack folder
find reza-products-pack -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -exec cp {} frontend/assets/images/products/ \; 2>/dev/null || true

python3 - <<'PY'
from pathlib import Path
import json
import re

img_dir = Path("frontend/assets/images/products")
images = list(img_dir.glob("*"))

def find_img(*keywords):
    for img in images:
        name = img.name.lower()
        if all(k.lower() in name for k in keywords):
            return f"https://rezaholdings.co.za/assets/images/products/{img.name}"
    return "https://rezaholdings.co.za/assets/images/reza-card-bg.svg"

products = [
    {
        "id": "reza-collagen-anti-ageing-cream",
        "name": "Reza Collagen Anti-Ageing Cream",
        "category": "Skincare",
        "status": "sale",
        "price": 0,
        "stock": 20,
        "badge": "On Sale",
        "image": find_img("collagen", "cream"),
        "description": "Anti-ageing cream for youthful, firm and radiant-looking skin.",
        "showOnline": True
    },
    {
        "id": "reza-starter-pack-combo",
        "name": "Reza Starter Pack Combo",
        "category": "Combos",
        "status": "sale",
        "price": 1400,
        "stock": 15,
        "badge": "Starter Combo",
        "image": find_img("starter"),
        "description": "Complete anti-ageing skincare solution starter combo.",
        "showOnline": True
    },
    {
        "id": "reza-complete-anti-ageing-skin-combo",
        "name": "Reza Complete Anti-Ageing Skin Combo",
        "category": "Combos",
        "status": "sale",
        "price": 480,
        "stock": 25,
        "badge": "Complete Combo",
        "image": find_img("complete"),
        "description": "A complete anti-ageing skin combo for youthful, firm and glowing skin.",
        "showOnline": True
    },
    {
        "id": "luxury-reza-marine-collagen",
        "name": "Luxury Reza Marine Collagen",
        "category": "Coming Soon",
        "status": "comingSoon",
        "price": 0,
        "stock": 0,
        "badge": "Coming Soon",
        "image": find_img("marine"),
        "description": "Premium beauty-from-within support for glow, repair and nourish.",
        "showOnline": False
    },
    {
        "id": "reza-acne-care-collection",
        "name": "Reza Acne Care Collection",
        "category": "Coming Soon",
        "status": "comingSoon",
        "price": 0,
        "stock": 0,
        "badge": "Coming Soon",
        "image": find_img("acne"),
        "description": "Luxury soap collection made for clearer, healthier-looking skin.",
        "showOnline": False
    },
    {
        "id": "reza-sea-moss",
        "name": "Reza Sea Moss",
        "category": "Coming Soon",
        "status": "comingSoon",
        "price": 0,
        "stock": 0,
        "badge": "Coming Soon",
        "image": find_img("sea", "moss"),
        "description": "Wildcrafted Irish sea moss for wellness and daily support.",
        "showOnline": False
    }
]

# Preserve any existing default products if you still want them removed? For now replace cleanly.
Path("backend/data/products.json").write_text(json.dumps(products, indent=2))
print("Saved backend/data/products.json")
for p in products:
    print(p["name"], "=>", p["image"])
PY

# Force frontend loader to separate sale and coming soon properly
cat > frontend/js/reza-products-render.js <<'JS'
(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function money(v) {
    const n = Number(v || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function normaliseImage(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function productCard(p, comingSoon = false) {
    return `
      <article class="product-card">
        <div class="product-img">
          ${p.badge ? `<span class="badge">${p.badge}</span>` : ""}
          <img src="${normaliseImage(p.image)}" alt="${p.name}" loading="lazy">
        </div>
        <div class="product-info">
          <h3>${p.name}</h3>
          <p class="price">${comingSoon ? "Coming Soon" : money(p.price)}</p>
          <p>${p.description || ""}</p>
          ${
            comingSoon
              ? `<button class="btn secondary" type="button">Coming Soon</button>`
              : `<button class="btn primary" type="button" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  async function loadProducts() {
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !Array.isArray(data.products)) return;

      const saleProducts = data.products.filter(p => p.status !== "comingSoon" && p.showOnline !== false);
      const comingSoonProducts = data.products.filter(p => p.status === "comingSoon" || p.category === "Coming Soon");

      const saleGrids = [
        document.querySelector("#productsGrid"),
        document.querySelector("#productGrid"),
        document.querySelector(".products-grid"),
        document.querySelector(".product-grid"),
        document.querySelector("#featuredProducts")
      ].filter(Boolean);

      const comingGrids = [
        document.querySelector("#comingSoonGrid"),
        document.querySelector(".coming-soon-grid"),
        document.querySelector("#comingSoonProducts")
      ].filter(Boolean);

      if (saleGrids.length) {
        const html = saleProducts.map(p => productCard(p, false)).join("");
        saleGrids.forEach(grid => grid.innerHTML = html || "<p>No sale products found.</p>");
      }

      if (comingGrids.length) {
        const html = comingSoonProducts.map(p => productCard(p, true)).join("");
        comingGrids.forEach(grid => grid.innerHTML = html || "<p>No coming soon products found.</p>");
      }
    } catch (err) {
      console.warn("Could not load products", err);
    }
  }

  window.addToCart = window.addToCart || function(product) {
    const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
    const existing = cart.find(item => item.id === product.id);

    if (existing) existing.qty += 1;
    else cart.push({ ...product, qty: 1 });

    localStorage.setItem("reza_cart", JSON.stringify(cart));
    alert("Added to cart");
  };

  document.addEventListener("DOMContentLoaded", loadProducts);
})();
JS

# Inject renderer last into frontend pages
python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")
    text = re.sub(r'\s*<script src="js/reza-products-render\.js[^"]*"></script>\s*', '\n', text)
    text = text.replace("</body>", '  <script src="js/reza-products-render.js?v=products2"></script>\n</body>')
    p.write_text(text, encoding="utf-8")
    print("Injected:", p)
PY

# Fix coming-soon page grid ID if needed
if [ -f "frontend/coming-soon.html" ]; then
python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/coming-soon.html")
text = p.read_text(encoding="utf-8")

if "comingSoonGrid" not in text:
    # Try replace first product grid container class/id
    text = re.sub(
        r'<div([^>]*class="[^"]*(?:products-grid|product-grid|coming-soon-grid)[^"]*"[^>]*)>',
        r'<div id="comingSoonGrid" \1>',
        text,
        count=1
    )

p.write_text(text, encoding="utf-8")
print("Checked coming-soon.html")
PY
fi

git add .
git commit -m "Fix Reza product images and separate sale from coming soon"
git push

echo "Done. Redeploy backend and frontend."
