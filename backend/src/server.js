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


// ======================================================
// REZA V11 PRODUCTS + POPUP ADMIN API
// ======================================================
const REZA_DATA_DIR = path.join(__dirname, "../data");
const REZA_PRODUCTS_FILE = path.join(REZA_DATA_DIR, "products.json");
const REZA_POPUP_FILE = path.join(REZA_DATA_DIR, "popup.json");

function rezaEnsureDataDir() {
  fs.mkdirSync(REZA_DATA_DIR, { recursive: true });

  if (!fs.existsSync(REZA_PRODUCTS_FILE)) {
    fs.writeFileSync(REZA_PRODUCTS_FILE, JSON.stringify([], null, 2));
  }

  if (!fs.existsSync(REZA_POPUP_FILE)) {
    fs.writeFileSync(REZA_POPUP_FILE, JSON.stringify({
      enabled: false,
      title: "Special Announcement",
      message: "Reza special coming soon.",
      buttonText: "Shop Now",
      buttonLink: "shop.html",
      image: "",
      updatedAt: new Date().toISOString()
    }, null, 2));
  }
}

function rezaReadJson(file, fallback) {
  try {
    rezaEnsureDataDir();
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    return fallback;
  }
}

function rezaWriteJson(file, data) {
  rezaEnsureDataDir();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function rezaSlug(input) {
  return String(input || "product")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function rezaCleanProduct(body) {
  const name = body.name || "New Product";

  return {
    id: body.id || `${rezaSlug(name)}-${Date.now()}`,
    name,
    category: body.category || "Skincare",
    productType: body.productType || "Single",
    status: body.status || "sale",
    price: Number(body.price || 0),
    stock: Number(body.stock || 0),
    badge: body.badge || "",
    image: body.image || "",
    description: body.description || "",
    showOnline: body.showOnline !== false,
    showFeatured: body.showFeatured === true,
    updatedAt: new Date().toISOString()
  };
}

// Products
app.get("/api/products", (req, res) => {
  const products = rezaReadJson(REZA_PRODUCTS_FILE, []);
  res.json({ success: true, products });
});

app.post("/api/products", (req, res) => {
  const products = rezaReadJson(REZA_PRODUCTS_FILE, []);
  const product = rezaCleanProduct(req.body || {});
  products.push(product);
  rezaWriteJson(REZA_PRODUCTS_FILE, products);

  res.json({
    success: true,
    message: "Product added",
    product,
    products
  });
});

app.put("/api/products/:id", (req, res) => {
  const products = rezaReadJson(REZA_PRODUCTS_FILE, []);
  const index = products.findIndex(p => p.id === req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }

  const current = products[index];
  products[index] = {
    ...current,
    ...rezaCleanProduct({ ...current, ...req.body, id: current.id }),
    id: current.id,
    updatedAt: new Date().toISOString()
  };

  rezaWriteJson(REZA_PRODUCTS_FILE, products);

  res.json({
    success: true,
    message: "Product updated",
    product: products[index],
    products
  });
});

app.patch("/api/products/:id/toggle", (req, res) => {
  const products = rezaReadJson(REZA_PRODUCTS_FILE, []);
  const product = products.find(p => p.id === req.params.id);

  if (!product) {
    return res.status(404).json({ success: false, message: "Product not found" });
  }

  product.showOnline = !product.showOnline;
  product.updatedAt = new Date().toISOString();

  rezaWriteJson(REZA_PRODUCTS_FILE, products);

  res.json({
    success: true,
    message: product.showOnline ? "Product visible" : "Product hidden",
    product,
    products
  });
});

app.delete("/api/products/:id", (req, res) => {
  const products = rezaReadJson(REZA_PRODUCTS_FILE, []);
  const next = products.filter(p => p.id !== req.params.id);

  rezaWriteJson(REZA_PRODUCTS_FILE, next);

  res.json({
    success: true,
    message: "Product deleted",
    products: next
  });
});

// Popup
app.get("/api/popup", (req, res) => {
  const popup = rezaReadJson(REZA_POPUP_FILE, {
    enabled: false,
    title: "",
    message: "",
    buttonText: "Shop Now",
    buttonLink: "shop.html",
    image: ""
  });

  res.json({ success: true, popup });
});

app.post("/api/popup", (req, res) => {
  const popup = {
    enabled: Boolean(req.body.enabled),
    title: req.body.title || "",
    message: req.body.message || "",
    buttonText: req.body.buttonText || "Shop Now",
    buttonLink: req.body.buttonLink || "shop.html",
    image: req.body.image || "",
    updatedAt: new Date().toISOString()
  };

  rezaWriteJson(REZA_POPUP_FILE, popup);

  res.json({
    success: true,
    message: "Popup saved",
    popup
  });
});

// ======================================================
// END REZA V11 PRODUCTS + POPUP ADMIN API
// ======================================================



// ======================================================
// REZA FINAL PRODUCTS + POPUP API
// ======================================================
const REZA_FINAL_DATA_DIR = path.join(__dirname, "../data");
const REZA_FINAL_PRODUCTS_FILE = path.join(REZA_FINAL_DATA_DIR, "products.json");
const REZA_FINAL_POPUP_FILE = path.join(REZA_FINAL_DATA_DIR, "popup.json");

function rezaFinalEnsureData(){
  fs.mkdirSync(REZA_FINAL_DATA_DIR, { recursive:true });
  if(!fs.existsSync(REZA_FINAL_PRODUCTS_FILE)){
    fs.writeFileSync(REZA_FINAL_PRODUCTS_FILE, JSON.stringify([], null, 2));
  }
  if(!fs.existsSync(REZA_FINAL_POPUP_FILE)){
    fs.writeFileSync(REZA_FINAL_POPUP_FILE, JSON.stringify({
      enabled:false,
      category:"Specials",
      title:"Manyora Special",
      message:"Limited time Reza skincare special. Best value for your skin.",
      buttonText:"Shop Special",
      buttonLink:"shop.html",
      image:"https://rezaholdings.co.za/assets/images/specials/manyora-special.jpg",
      updatedAt:new Date().toISOString()
    }, null, 2));
  }
}

function rezaFinalRead(file, fallback){
  try{
    rezaFinalEnsureData();
    return JSON.parse(fs.readFileSync(file, "utf8"));
  }catch(e){ return fallback; }
}
function rezaFinalWrite(file, data){
  rezaFinalEnsureData();
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}
function rezaFinalSlug(v){
  return String(v || "product").toLowerCase().trim().replace(/[^a-z0-9]+/g,"-").replace(/^-|-$/g,"");
}
function rezaFinalProduct(body){
  const name = body.name || "New Product";
  return {
    id: body.id || `${rezaFinalSlug(name)}-${Date.now()}`,
    name,
    category: body.category || "Skincare",
    productType: body.productType || "Single",
    status: body.status || "sale",
    price: Number(body.price || 0),
    stock: Number(body.stock || 0),
    badge: body.badge || "",
    image: body.image || "",
    description: body.description || "",
    showOnline: body.showOnline !== false,
    showFeatured: body.showFeatured === true,
    updatedAt: new Date().toISOString()
  };
}

app.get("/api/products", (req,res)=>{
  res.json({ success:true, products: rezaFinalRead(REZA_FINAL_PRODUCTS_FILE, []) });
});

app.post("/api/products", (req,res)=>{
  const products = rezaFinalRead(REZA_FINAL_PRODUCTS_FILE, []);
  const product = rezaFinalProduct(req.body || {});
  products.push(product);
  rezaFinalWrite(REZA_FINAL_PRODUCTS_FILE, products);
  res.json({ success:true, message:"Product added", product, products });
});

app.put("/api/products/:id", (req,res)=>{
  const products = rezaFinalRead(REZA_FINAL_PRODUCTS_FILE, []);
  const i = products.findIndex(p => p.id === req.params.id);
  if(i === -1) return res.status(404).json({ success:false, message:"Product not found" });
  products[i] = { ...products[i], ...rezaFinalProduct({ ...products[i], ...req.body, id:products[i].id }), id:products[i].id, updatedAt:new Date().toISOString() };
  rezaFinalWrite(REZA_FINAL_PRODUCTS_FILE, products);
  res.json({ success:true, message:"Product updated", product:products[i], products });
});

app.patch("/api/products/:id/toggle", (req,res)=>{
  const products = rezaFinalRead(REZA_FINAL_PRODUCTS_FILE, []);
  const product = products.find(p => p.id === req.params.id);
  if(!product) return res.status(404).json({ success:false, message:"Product not found" });
  product.showOnline = !product.showOnline;
  product.updatedAt = new Date().toISOString();
  rezaFinalWrite(REZA_FINAL_PRODUCTS_FILE, products);
  res.json({ success:true, message:product.showOnline ? "Product visible" : "Product hidden", product, products });
});

app.delete("/api/products/:id", (req,res)=>{
  const products = rezaFinalRead(REZA_FINAL_PRODUCTS_FILE, []);
  const next = products.filter(p => p.id !== req.params.id);
  rezaFinalWrite(REZA_FINAL_PRODUCTS_FILE, next);
  res.json({ success:true, message:"Product deleted", products:next });
});

app.get("/api/popup", (req,res)=>{
  res.json({ success:true, popup: rezaFinalRead(REZA_FINAL_POPUP_FILE, {}) });
});

app.post("/api/popup", (req,res)=>{
  const popup = {
    enabled: Boolean(req.body.enabled),
    category: req.body.category || "Specials",
    title: req.body.title || "",
    message: req.body.message || "",
    buttonText: req.body.buttonText || "Shop Now",
    buttonLink: req.body.buttonLink || "shop.html",
    image: req.body.image || "",
    updatedAt:new Date().toISOString()
  };
  rezaFinalWrite(REZA_FINAL_POPUP_FILE, popup);
  res.json({ success:true, message:"Popup saved", popup });
});
// ======================================================
// END REZA FINAL PRODUCTS + POPUP API
// ======================================================


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
