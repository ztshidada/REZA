#!/bin/bash
set -e

echo "🔗 Fixing full Admin ↔ Backend ↔ Customer connection..."

mkdir -p backend/data frontend/js admin/js

# 1) Replace backend with clean working API for products + media
cat > backend/src/server.js <<'JS'
const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 10000;

app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json({ limit: "80mb" }));
app.use(express.urlencoded({ extended: true, limit: "80mb" }));

const DATA_DIR = path.join(__dirname, "../data");
const PRODUCTS_FILE = path.join(DATA_DIR, "products.json");
const MEDIA_FILE = path.join(DATA_DIR, "media.json");

function ensureData() {
  fs.mkdirSync(DATA_DIR, { recursive: true });

  if (!fs.existsSync(PRODUCTS_FILE)) {
    fs.writeFileSync(PRODUCTS_FILE, JSON.stringify([
      {
        id: "reza-skin-glow",
        name: "Reza Skin Glow",
        category: "Skincare",
        price: 350,
        stock: 25,
        badge: "Best Seller",
        image: "assets/images/reza-card-bg.svg",
        description: "Premium Reza beauty product for glowing skin.",
        showOnline: true
      },
      {
        id: "reza-wellness-combo",
        name: "Reza Wellness Combo",
        category: "Wellness",
        price: 600,
        stock: 15,
        badge: "Combo",
        image: "assets/images/reza-card-bg.svg",
        description: "A premium wellness combo for everyday self-care.",
        showOnline: true
      }
    ], null, 2));
  }

  if (!fs.existsSync(MEDIA_FILE)) {
    fs.writeFileSync(MEDIA_FILE, JSON.stringify({
      heroImage: "assets/images/reza-soft-beauty-bg.svg",
      heroTitle: "Champagne Luxury",
      updatedAt: new Date().toISOString()
    }, null, 2));
  }
}

function readJson(file, fallback) {
  try {
    ensureData();
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function writeJson(file, data) {
  ensureData();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function makeId(name) {
  return String(name || "product")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "") + "-" + Date.now();
}

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Reza API is online",
    productsRoute: "/api/products",
    mediaRoute: "/api/media",
    time: new Date().toISOString()
  });
});

app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Reza API healthy",
    time: new Date().toISOString()
  });
});

/* MEDIA */
app.get("/api/media", (req, res) => {
  const media = readJson(MEDIA_FILE, {});
  res.json({ success: true, media });
});

app.post("/api/media", (req, res) => {
  const current = readJson(MEDIA_FILE, {});
  const next = {
    ...current,
    ...req.body,
    updatedAt: new Date().toISOString()
  };

  writeJson(MEDIA_FILE, next);

  res.json({
    success: true,
    message: "Media saved successfully",
    media: next
  });
});

/* PRODUCTS */
app.get("/api/products", (req, res) => {
  const products = readJson(PRODUCTS_FILE, []);
  res.json({ success: true, products });
});

app.post("/api/products", (req, res) => {
  const products = readJson(PRODUCTS_FILE, []);

  const incoming = req.body || {};
  const product = {
    id: incoming.id || makeId(incoming.name),
    name: incoming.name || "New Product",
    category: incoming.category || "General",
    price: Number(incoming.price || 0),
    stock: Number(incoming.stock || 0),
    badge: incoming.badge || "",
    image: incoming.image || incoming.productImage || "assets/images/reza-card-bg.svg",
    description: incoming.description || "",
    benefits: incoming.benefits || [],
    howToUse: incoming.howToUse || "",
    showOnline: incoming.showOnline !== false
  };

  products.push(product);
  writeJson(PRODUCTS_FILE, products);

  res.json({
    success: true,
    message: "Product saved successfully",
    product,
    products
  });
});

app.put("/api/products/:id", (req, res) => {
  const products = readJson(PRODUCTS_FILE, []);
  const index = products.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }

  products[index] = {
    ...products[index],
    ...req.body,
    price: req.body.price !== undefined ? Number(req.body.price) : products[index].price,
    stock: req.body.stock !== undefined ? Number(req.body.stock) : products[index].stock
  };

  writeJson(PRODUCTS_FILE, products);

  res.json({
    success: true,
    message: "Product updated successfully",
    product: products[index],
    products
  });
});

app.delete("/api/products/:id", (req, res) => {
  const products = readJson(PRODUCTS_FILE, []);
  const next = products.filter(p => p.id !== req.params.id);

  writeJson(PRODUCTS_FILE, next);

  res.json({
    success: true,
    message: "Product deleted successfully",
    products: next
  });
});

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
    path: req.path
  });
});

app.listen(PORT, () => {
  ensureData();
  console.log(`Reza API running on port ${PORT}`);
});
JS

# 2) Admin shared API helper
cat > admin/js/api.js <<'JS'
window.REZA_API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

window.rezaApi = async function(path, options = {}) {
  const res = await fetch(window.REZA_API_BASE + path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    }
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok || data.success === false) {
    throw new Error(data.message || "API request failed");
  }
  return data;
};

window.fileToDataUrl = function(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
};
JS

# 3) Customer shared API helper
cat > frontend/js/live-api.js <<'JS'
window.REZA_API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

async function rezaFetch(path) {
  const res = await fetch(window.REZA_API_BASE + path + "?t=" + Date.now());
  return await res.json();
}

function money(v) {
  return "R " + Number(v || 0).toLocaleString("en-ZA", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function normaliseImage(src) {
  if (!src) return "assets/images/reza-card-bg.svg";
  if (src.startsWith("data:image")) return src;
  if (src.startsWith("http")) return src;
  if (src.startsWith("/")) return window.REZA_API_BASE + src;
  return src;
}

async function applyLiveMedia() {
  try {
    const data = await rezaFetch("/api/media");
    if (!data.success || !data.media) return;

    const img = normaliseImage(data.media.heroImage);

    document.querySelectorAll(".hero, .page-hero").forEach(el => {
      el.style.backgroundImage =
        `linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)), url("${img}")`;
      el.style.backgroundSize = "cover";
      el.style.backgroundPosition = "center";
    });
  } catch (e) {
    console.warn("Media not loaded", e);
  }
}

async function applyLiveProducts() {
  try {
    const data = await rezaFetch("/api/products");
    if (!data.success || !Array.isArray(data.products)) return;

    const products = data.products.filter(p => p.showOnline !== false);

    const grids = [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid"),
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products")
    ].filter(Boolean);

    if (!grids.length) return;

    const html = products.map(p => `
      <article class="product-card" data-id="${p.id}">
        <div class="product-img">
          ${p.badge ? `<span class="badge">${p.badge}</span>` : ""}
          <img src="${normaliseImage(p.image)}" alt="${p.name}" style="width:100%;height:260px;object-fit:cover;border-radius:22px;">
        </div>
        <div class="product-info">
          <h3>${p.name}</h3>
          <p class="price">${money(p.price)}</p>
          <p>${p.description || ""}</p>
          <button class="btn primary" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>
        </div>
      </article>
    `).join("");

    grids.forEach(grid => {
      grid.innerHTML = html || `<p>No products found.</p>`;
    });
  } catch (e) {
    console.warn("Products not loaded", e);
  }
}

window.addToCart = function(product) {
  const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
  const existing = cart.find(item => item.id === product.id);

  if (existing) {
    existing.qty += 1;
  } else {
    cart.push({ ...product, qty: 1 });
  }

  localStorage.setItem("reza_cart", JSON.stringify(cart));
  alert("Added to cart");
};

document.addEventListener("DOMContentLoaded", () => {
  applyLiveMedia();
  applyLiveProducts();
});
JS

# 4) Inject live-api.js into every customer page
python3 - <<'PY'
from pathlib import Path

for p in Path("frontend").glob("*.html"):
    text = p.read_text()
    if "js/live-api.js" not in text:
        text = text.replace("</body>", '  <script src="js/live-api.js"></script>\n</body>')
        p.write_text(text)
        print("Injected live-api.js into", p)
PY

# 5) Inject admin api.js into admin pages
python3 - <<'PY'
from pathlib import Path

for p in Path("admin").glob("*.html"):
    text = p.read_text()
    if "js/api.js" not in text:
        text = text.replace("</body>", '  <script src="js/api.js"></script>\n</body>')
        p.write_text(text)
        print("Injected api.js into", p)
PY

git add .
git commit -m "Connect admin products and media to backend and customer frontend"
git push

echo "✅ Full connection patch done."
