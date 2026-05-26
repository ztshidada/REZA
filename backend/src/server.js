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
