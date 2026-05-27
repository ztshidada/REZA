const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");
const paymentRoutes = require("./routes/payments");

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
// REZA ORDERS API - SAFE ADD
// ======================================================
const REZA_SAFE_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaSafeEnsureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_SAFE_ORDERS_FILE)) {
    fs.writeFileSync(REZA_SAFE_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaSafeReadOrders() {
  try {
    rezaSafeEnsureOrdersFile();
    return JSON.parse(fs.readFileSync(REZA_SAFE_ORDERS_FILE, "utf8"));
  } catch {
    return [];
  }
}

function rezaSafeWriteOrders(orders) {
  rezaSafeEnsureOrdersFile();
  fs.writeFileSync(REZA_SAFE_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

app.get("/api/orders", (req, res) => {
  res.json({ success: true, orders: rezaSafeReadOrders() });
});

app.post("/api/orders", (req, res) => {
  const body = req.body || {};
  const items = Array.isArray(body.items) ? body.items : [];

  if (!items.length) {
    return res.status(400).json({ success: false, message: "Cart is empty" });
  }

  const orders = rezaSafeReadOrders();

  const subtotal = items.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  const orderNumber =
    "REZA-" +
    new Date().toISOString().slice(0, 10).replace(/-/g, "") +
    "-" +
    String(orders.length + 1).padStart(4, "0");

  const order = {
    id: orderNumber.toLowerCase(),
    orderNumber,
    customer: body.customer || {},
    items,
    subtotal,
    total: subtotal,
    delivery: "Calculated after order",
    status: "New Order",
    paymentStatus: "Pending",
    createdAt: new Date().toISOString()
  };

  orders.unshift(order);
  rezaSafeWriteOrders(orders);

  res.json({ success: true, message: "Order created", order });
});
// ======================================================
// END REZA ORDERS API - SAFE ADD
// ======================================================



// ======================================================
// REZA LIVE BACKEND MARKER
// ======================================================
app.get("/api/debug/live-version", (req, res) => {
  res.json({
    success: true,
    marker: "REZA_BACKEND_YOCO_FORCE_20260527_V3",
    time: new Date().toISOString()
  });
});



// ======================================================
// REZA ABSOLUTE EARLY YOCO WEBHOOK INTERCEPTOR V3
// ======================================================
app.use("/api/payments/yoco/webhook", express.json({ type: "*/*" }), (req, res, next) => {
  if (req.method !== "POST") return next();

  try {
    const file = path.join(DATA_DIR, "orders.json");
    const eventsFile = path.join(DATA_DIR, "yoco-events.json");

    const payload = req.body || {};
    const d = payload.data || payload.payload || payload.object || payload.checkout || payload.payment || payload;

    const refs = [...new Set([
      payload.id,
      payload.checkoutId,
      payload.paymentId,
      payload.reference,
      payload.orderId,
      payload.orderNumber,
      payload.metadata && payload.metadata.orderId,
      payload.metadata && payload.metadata.orderNumber,

      d.id,
      d.checkoutId,
      d.paymentId,
      d.reference,
      d.orderId,
      d.orderNumber,
      d.metadata && d.metadata.orderId,
      d.metadata && d.metadata.orderNumber,

      d.checkout && d.checkout.id,
      d.checkout && d.checkout.checkoutId,
      d.payment && d.payment.id,
      d.payment && d.payment.checkoutId
    ].filter(Boolean).map(String))];

    const raw = JSON.stringify(payload).toLowerCase();
    const paidEvent =
      raw.includes("payment.succeeded") ||
      raw.includes("checkout.succeeded") ||
      raw.includes("checkout.completed") ||
      raw.includes('"status":"paid"') ||
      raw.includes('"status":"succeeded"') ||
      raw.includes('"status":"successful"');

    let orders = [];
    try {
      orders = JSON.parse(fs.readFileSync(file, "utf8"));
    } catch {
      orders = [];
    }

    let found = -1;
    let matchedRef = "";

    for (const ref of refs) {
      found = orders.findIndex(o => {
        const possible = [
          o.id,
          o.orderNumber,
          o.orderNo,
          o.yocoCheckoutId,
          o.checkoutId,
          o.paymentId,
          o.yocoPaymentId,
          o.payment && o.payment.checkoutId,
          o.payment && o.payment.id,
          o.yoco && o.yoco.checkoutId,
          o.yoco && o.yoco.id
        ].filter(Boolean).map(String);

        return possible.includes(ref);
      });

      if (found !== -1) {
        matchedRef = ref;
        break;
      }
    }

    let update = null;

    if (paidEvent && found !== -1) {
      const now = new Date().toISOString();

      orders[found] = {
        ...orders[found],
        paymentStatus: "Paid",
        status: "Paid",
        paidAt: orders[found].paidAt || now,
        yocoPaidAt: orders[found].yocoPaidAt || now,
        yocoMatchedRef: matchedRef,
        yocoPaidSource: "absolute-early-webhook-v3",
        updatedAt: now
      };

      fs.writeFileSync(file, JSON.stringify(orders, null, 2));

      update = {
        success: true,
        message: "Order marked paid",
        matchedRef,
        orderNumber: orders[found].orderNumber || orders[found].id
      };
    } else {
      update = {
        success: false,
        message: found === -1 ? "No matching order found" : "Event was not paid",
        refs
      };
    }

    let events = [];
    try {
      events = JSON.parse(fs.readFileSync(eventsFile, "utf8"));
    } catch {
      events = [];
    }

    events.unshift({
      receivedAt: new Date().toISOString(),
      route: "absolute-early-webhook-v3",
      paidEvent,
      refs,
      update,
      payload
    });

    fs.writeFileSync(eventsFile, JSON.stringify(events.slice(0, 100), null, 2));

    return res.status(200).json({
      success: true,
      route: "absolute-early-webhook-v3",
      paidEvent,
      refs,
      update
    });

  } catch (err) {
    return res.status(500).json({
      success: false,
      route: "absolute-early-webhook-v3",
      message: err.message
    });
  }
});
// ======================================================
// END REZA ABSOLUTE EARLY YOCO WEBHOOK INTERCEPTOR V3
// ======================================================


app.get("/api/payments/yoco/webhook", (req, res) => {
  res.json({
    success: true,
    message: "Yoco webhook endpoint is live. Browser GET is only for testing.",
    webhookUrl: "https://api.rezaholdings.co.za/api/payments/yoco/webhook"
  });
});


app.get("/api/debug/yoco-key", (req, res) => {
  const key = process.env.YOCO_SECRET_KEY || process.env.YOCO_LIVE_SECRET_KEY || "";
  res.json({
    success: true,
    present: Boolean(key),
    prefix: key ? key.slice(0, 12) : "",
    length: key.length,
    startsWithSkLive: key.startsWith("sk_live_"),
    startsWithYocoLive: key.startsWith("yoco_live_"),
    startsWithSkTest: key.startsWith("sk_test_"),
    startsWithYocoTest: key.startsWith("yoco_test_")
  });
});



// ======================================================
// REZA YOCO CREATE CHECKOUT BRIDGE
// Saves orderNumber + yocoCheckoutId into backend/data/orders.json
// BEFORE older /api/payments router handles it.
// ======================================================
app.post("/api/payments/yoco/create-checkout", async (req, res) => {
  try {
    const body = req.body || {};
    const incoming = body.order || body;
    const items = Array.isArray(incoming.items) ? incoming.items : [];

    if (!items.length) {
      return res.status(400).json({ success: false, message: "Cart is empty." });
    }

    const total = Number(
      incoming.total !== undefined
        ? incoming.total
        : items.reduce((sum, item) => sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1), 0)
    );

    if (total < 2) {
      return res.status(400).json({ success: false, message: "Yoco payments must be at least R2.00." });
    }

    const key = process.env.YOCO_SECRET_KEY || process.env.YOCO_LIVE_SECRET_KEY || "";
    if (!key) {
      return res.status(500).json({ success: false, message: "YOCO_SECRET_KEY is missing on Render." });
    }

    const ordersFile = path.join(__dirname, "../data/orders.json");
    fs.mkdirSync(path.dirname(ordersFile), { recursive: true });

    let orders = [];
    try {
      orders = JSON.parse(fs.readFileSync(ordersFile, "utf8"));
      if (!Array.isArray(orders)) orders = [];
    } catch {
      orders = [];
    }

    const orderNumber =
      incoming.orderNumber ||
      incoming.id ||
      "REZA-" + new Date().toISOString().slice(0,10).replace(/-/g,"") + "-" + String(orders.length + 1).padStart(4, "0");

    const frontendUrl = process.env.FRONTEND_URL || process.env.SITE_URL || "https://rezaholdings.co.za";

    const order = {
      ...incoming,
      id: orderNumber,
      orderNumber,
      customer: incoming.customer || {},
      items,
      subtotal: Number(incoming.subtotal || total),
      total,
      paymentMethod: "Yoco",
      paymentStatus: "Pending Payment",
      deliveryStatus: incoming.deliveryStatus || "New Order",
      status: "New Order",
      source: "reza-v11-yoco-bridge",
      createdAt: incoming.createdAt || new Date().toISOString()
    };

    const payload = {
      amount: Math.max(Math.round(total * 100), 200),
      currency: "ZAR",
      successUrl: `${frontendUrl}/payment-success.html?order=${encodeURIComponent(orderNumber)}`,
      cancelUrl: `${frontendUrl}/payment-cancelled.html?order=${encodeURIComponent(orderNumber)}`,
      failureUrl: `${frontendUrl}/payment-failed.html?order=${encodeURIComponent(orderNumber)}`,
      metadata: {
        orderId: String(orderNumber),
        orderNumber: String(orderNumber),
        customerName: String(order.customer?.fullName || order.customer?.name || ""),
        customerPhone: String(order.customer?.phone || "")
      }
    };

    const yocoRes = await fetch("https://payments.yoco.com/api/checkouts", {
      method: "POST",
      headers: {
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
        "Idempotency-Key": String(orderNumber)
      },
      body: JSON.stringify(payload)
    });

    const checkout = await yocoRes.json().catch(() => ({}));

    if (!yocoRes.ok || !checkout.redirectUrl) {
      return res.status(502).json({
        success: false,
        message: checkout.displayMessage || checkout.message || checkout.error || "Yoco checkout failed",
        yoco: checkout
      });
    }

    const savedOrder = {
      ...order,
      yocoCheckoutId: checkout.id,
      yocoRedirectUrl: checkout.redirectUrl,
      yocoPaymentId: checkout.paymentId || null,
      yocoProcessingMode: checkout.processingMode || null,
      updatedAt: new Date().toISOString()
    };

    const idx = orders.findIndex(o => String(o.id) === String(orderNumber) || String(o.orderNumber) === String(orderNumber));

    if (idx >= 0) orders[idx] = { ...orders[idx], ...savedOrder };
    else orders.unshift(savedOrder);

    fs.writeFileSync(ordersFile, JSON.stringify(orders, null, 2));

    return res.json({
      success: true,
      order: savedOrder,
      checkout,
      redirectUrl: checkout.redirectUrl
    });
  } catch (error) {
    console.error("Reza Yoco bridge checkout error:", error);
    return res.status(500).json({ success: false, message: error.message });
  }
});
// ======================================================
// END REZA YOCO CREATE CHECKOUT BRIDGE
// ======================================================


app.use("/api/payments", paymentRoutes);


// ======================================================
// REZA ADVANCED ADMIN ORDER MANAGEMENT
// ======================================================
const REZA_ADMIN_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaAdminEnsureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_ADMIN_ORDERS_FILE)) {
    fs.writeFileSync(REZA_ADMIN_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaAdminReadOrders() {
  try {
    rezaAdminEnsureOrdersFile();
    const data = JSON.parse(fs.readFileSync(REZA_ADMIN_ORDERS_FILE, "utf8"));
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function rezaAdminWriteOrders(orders) {
  rezaAdminEnsureOrdersFile();
  fs.writeFileSync(REZA_ADMIN_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

function rezaAdminFindOrderIndex(orders, id) {
  return orders.findIndex(o =>
    String(o.id || "") === String(id) ||
    String(o.orderNumber || "") === String(id)
  );
}

app.get("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  res.json({ success: true, order: orders[index] });
});

app.patch("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const existing = orders[index];
  const incoming = req.body || {};

  orders[index] = {
    ...existing,
    ...incoming,
    id: existing.id || existing.orderNumber || incoming.id,
    orderNumber: existing.orderNumber || existing.id || incoming.orderNumber,
    customer: {
      ...(existing.customer || {}),
      ...(incoming.customer || {})
    },
    items: Array.isArray(incoming.items) ? incoming.items : existing.items,
    updatedAt: new Date().toISOString()
  };

  rezaAdminWriteOrders(orders);
  res.json({ success: true, message: "Order updated", order: orders[index] });
});

app.put("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const incoming = req.body || {};
  orders[index] = {
    ...incoming,
    id: incoming.id || incoming.orderNumber || req.params.id,
    orderNumber: incoming.orderNumber || incoming.id || req.params.id,
    updatedAt: new Date().toISOString()
  };

  rezaAdminWriteOrders(orders);
  res.json({ success: true, message: "Order replaced", order: orders[index] });
});

app.delete("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const deleted = orders.splice(index, 1)[0];
  rezaAdminWriteOrders(orders);

  res.json({ success: true, message: "Order deleted", order: deleted });
});
// ======================================================
// END REZA ADVANCED ADMIN ORDER MANAGEMENT
// ======================================================



// ======================================================
// REZA YOCO PAID SYNC FIX
// This does not expose keys. It updates local order status when
// Yoco confirms a checkout/payment is paid.
// ======================================================
const REZA_YOCO_EVENTS_FILE = path.join(DATA_DIR, "yoco-events.json");

function rezaSafeJsonFile(file, fallback) {
  try {
    if (!fs.existsSync(file)) fs.writeFileSync(file, JSON.stringify(fallback, null, 2));
    const data = JSON.parse(fs.readFileSync(file, "utf8"));
    return data;
  } catch {
    return fallback;
  }
}

function rezaWriteJsonFile(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function rezaGetOrdersFileForYocoSync() {
  return path.join(DATA_DIR, "orders.json");
}

function rezaReadOrdersForYocoSync() {
  const file = rezaGetOrdersFileForYocoSync();
  return rezaSafeJsonFile(file, []);
}

function rezaWriteOrdersForYocoSync(orders) {
  const file = rezaGetOrdersFileForYocoSync();
  rezaWriteJsonFile(file, orders);
}

function rezaFindOrderByAnyYocoRef(orders, ref) {
  const value = String(ref || "").trim();
  if (!value) return -1;

  return orders.findIndex(o => {
    const possible = [
      o.id,
      o.orderNumber,
      o.orderNo,
      o.yocoCheckoutId,
      o.checkoutId,
      o.paymentId,
      o.yocoPaymentId,
      o.metadata?.orderId,
      o.metadata?.orderNumber,
      o.payment?.checkoutId,
      o.payment?.id,
      o.yoco?.checkoutId,
      o.yoco?.id
    ].filter(Boolean).map(String);

    return possible.includes(value);
  });
}

function rezaMarkOrderPaidByRefs(refs, eventData = {}) {
  const orders = rezaReadOrdersForYocoSync();
  let index = -1;
  let matchedRef = "";

  for (const ref of refs.filter(Boolean)) {
    index = rezaFindOrderByAnyYocoRef(orders, ref);
    if (index !== -1) {
      matchedRef = String(ref);
      break;
    }
  }

  if (index === -1) {
    return { success: false, message: "Order not found for refs", refs };
  }

  const now = new Date().toISOString();
  const existing = orders[index];

  orders[index] = {
    ...existing,
    paymentStatus: "Paid",
    status: existing.status === "Cancelled" ? existing.status : "Paid",
    yocoPaidAt: existing.yocoPaidAt || now,
    yocoLastEventAt: now,
    yocoMatchedRef: matchedRef,
    yocoLastEvent: {
      id: eventData.id || eventData.eventId || eventData.paymentId || eventData.checkoutId || "",
      type: eventData.type || eventData.eventType || "",
      status: eventData.status || eventData.paymentStatus || "",
      checkoutId: eventData.checkoutId || eventData.id || "",
      paymentId: eventData.paymentId || eventData.chargeId || ""
    },
    updatedAt: now
  };

  rezaWriteOrdersForYocoSync(orders);

  return {
    success: true,
    message: "Order marked paid",
    order: orders[index],
    matchedRef
  };
}

function rezaExtractYocoRefs(payload) {
  const d = payload || {};
  const data = d.data || d.payload || d.object || d.payment || d.checkout || d;

  const refs = [
    d.id,
    d.checkoutId,
    d.paymentId,
    d.orderId,
    d.orderNumber,
    d.reference,
    d.metadata?.orderId,
    d.metadata?.orderNumber,

    data.id,
    data.checkoutId,
    data.paymentId,
    data.orderId,
    data.orderNumber,
    data.reference,
    data.metadata?.orderId,
    data.metadata?.orderNumber,

    data.checkout?.id,
    data.checkout?.checkoutId,
    data.payment?.id,
    data.payment?.checkoutId
  ];

  return [...new Set(refs.filter(Boolean).map(String))];
}

function rezaIsYocoPaidPayload(payload) {
  const raw = JSON.stringify(payload || {}).toLowerCase();

  return (
    raw.includes("payment.succeeded") ||
    raw.includes("payment_success") ||
    raw.includes("checkout.completed") ||
    raw.includes("checkout.succeeded") ||
    raw.includes('"status":"succeeded"') ||
    raw.includes('"status":"successful"') ||
    raw.includes('"status":"paid"') ||
    raw.includes('"paymentstatus":"paid"')
  );
}

app.post("/api/payments/yoco/webhook-safe-sync", express.json({ type: "*/*" }), (req, res) => {
  const payload = req.body || {};
  const events = rezaSafeJsonFile(REZA_YOCO_EVENTS_FILE, []);

  events.unshift({
    receivedAt: new Date().toISOString(),
    payload
  });

  rezaWriteJsonFile(REZA_YOCO_EVENTS_FILE, events.slice(0, 100));

  if (!rezaIsYocoPaidPayload(payload)) {
    return res.json({
      success: true,
      message: "Yoco event logged but not marked paid",
      paidEvent: false,
      refs: rezaExtractYocoRefs(payload)
    });
  }

  const refs = rezaExtractYocoRefs(payload);
  const result = rezaMarkOrderPaidByRefs(refs, payload);

  res.json({
    success: true,
    paidEvent: true,
    refs,
    update: result
  });
});

app.get("/api/payments/yoco/events", (req, res) => {
  const events = rezaSafeJsonFile(REZA_YOCO_EVENTS_FILE, []);
  res.json({
    success: true,
    count: events.length,
    events: events.slice(0, 20)
  });
});

app.post("/api/payments/yoco/mark-paid-by-ref", (req, res) => {
  const refs = [
    req.body?.orderId,
    req.body?.orderNumber,
    req.body?.checkoutId,
    req.body?.yocoCheckoutId,
    req.body?.paymentId
  ].filter(Boolean);

  const result = rezaMarkOrderPaidByRefs(refs, {
    type: "manual-sync",
    status: "paid",
    checkoutId: req.body?.checkoutId || req.body?.yocoCheckoutId || ""
  });

  if (!result.success) return res.status(404).json(result);
  res.json(result);
});
// ======================================================
// END REZA YOCO PAID SYNC FIX
// ======================================================



// ======================================================
// REZA REAL YOCO WEBHOOK + RETURN PAID FIX
// Logs actual webhook events and marks matching orders as Paid.
// ======================================================
const REZA_YOCO_REAL_EVENTS_FILE = path.join(DATA_DIR, "yoco-events.json");

function rezaJsonRead(file, fallback) {
  try {
    if (!fs.existsSync(file)) fs.writeFileSync(file, JSON.stringify(fallback, null, 2));
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function rezaJsonWrite(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function rezaOrdersRead() {
  return rezaJsonRead(path.join(DATA_DIR, "orders.json"), []);
}

function rezaOrdersWrite(orders) {
  rezaJsonWrite(path.join(DATA_DIR, "orders.json"), orders);
}

function rezaYocoRefs(payload) {
  const d = payload || {};
  const data = d.data || d.payload || d.object || d.checkout || d.payment || d;

  return [...new Set([
    d.id,
    d.checkoutId,
    d.paymentId,
    d.reference,
    d.orderId,
    d.orderNumber,
    d.metadata?.orderId,
    d.metadata?.orderNumber,

    data.id,
    data.checkoutId,
    data.paymentId,
    data.reference,
    data.orderId,
    data.orderNumber,
    data.metadata?.orderId,
    data.metadata?.orderNumber,

    data.checkout?.id,
    data.checkout?.checkoutId,
    data.payment?.id,
    data.payment?.checkoutId
  ].filter(Boolean).map(String))];
}

function rezaLooksPaid(payload) {
  const raw = JSON.stringify(payload || {}).toLowerCase();
  return (
    raw.includes("payment.succeeded") ||
    raw.includes("checkout.succeeded") ||
    raw.includes("checkout.completed") ||
    raw.includes('"status":"paid"') ||
    raw.includes('"status":"succeeded"') ||
    raw.includes('"status":"successful"')
  );
}

function rezaMarkPaidByRefs(refs, source = "yoco") {
  const orders = rezaOrdersRead();
  let foundIndex = -1;
  let matched = "";

  for (const ref of refs.filter(Boolean)) {
    const r = String(ref);
    foundIndex = orders.findIndex(o => {
      const possible = [
        o.id,
        o.orderNumber,
        o.orderNo,
        o.yocoCheckoutId,
        o.checkoutId,
        o.paymentId,
        o.yocoPaymentId,
        o.payment?.checkoutId,
        o.payment?.id,
        o.yoco?.checkoutId,
        o.yoco?.id
      ].filter(Boolean).map(String);

      return possible.includes(r);
    });

    if (foundIndex !== -1) {
      matched = r;
      break;
    }
  }

  if (foundIndex === -1) {
    return { success: false, message: "No matching order found", refs };
  }

  const now = new Date().toISOString();

  orders[foundIndex] = {
    ...orders[foundIndex],
    paymentStatus: "Paid",
    status: orders[foundIndex].status === "Cancelled" ? "Paid" : "Paid",
    paidAt: orders[foundIndex].paidAt || now,
    yocoPaidAt: orders[foundIndex].yocoPaidAt || now,
    yocoMatchedRef: matched,
    yocoPaidSource: source,
    updatedAt: now
  };

  rezaOrdersWrite(orders);

  return {
    success: true,
    message: "Order marked paid",
    matchedRef: matched,
    order: orders[foundIndex]
  };
}

// Return-success endpoint. Frontend calls this after Yoco redirects back.
app.post("/api/payments/yoco/return-success", (req, res) => {
  const body = req.body || {};
  const refs = [
    body.orderId,
    body.orderNumber,
    body.checkoutId,
    body.yocoCheckoutId,
    body.paymentId
  ].filter(Boolean);

  const result = rezaMarkPaidByRefs(refs, "success-return");

  if (!result.success) return res.status(404).json(result);
  res.json(result);
});

// Manual/admin sync endpoint.
app.post("/api/payments/yoco/mark-paid-by-ref", (req, res) => {
  const body = req.body || {};
  const refs = [
    body.orderId,
    body.orderNumber,
    body.checkoutId,
    body.yocoCheckoutId,
    body.paymentId
  ].filter(Boolean);

  const result = rezaMarkPaidByRefs(refs, "admin-sync");

  if (!result.success) return res.status(404).json(result);
  res.json(result);
});

// Webhook event viewer.
app.get("/api/payments/yoco/events", (req, res) => {
  const events = rezaJsonRead(REZA_YOCO_REAL_EVENTS_FILE, []);
  res.json({
    success: true,
    count: events.length,
    events: events.slice(0, 30)
  });
});



// REAL YOCO WEBHOOK HANDLER - REZA OVERRIDE

// ======================================================
// REZA FORCE-FIRST YOCO WEBHOOK HANDLER
// Must appear BEFORE old webhook route that says:
// "No order/checkout id found"
// ======================================================
const REZA_FORCE_YOCO_EVENTS_FILE = path.join(DATA_DIR, "yoco-events.json");

function rezaForceReadJson(file, fallback) {
  try {
    if (!fs.existsSync(file)) fs.writeFileSync(file, JSON.stringify(fallback, null, 2));
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function rezaForceWriteJson(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function rezaForceOrdersFile() {
  return path.join(DATA_DIR, "orders.json");
}

function rezaForceReadOrders() {
  return rezaForceReadJson(rezaForceOrdersFile(), []);
}

function rezaForceWriteOrders(orders) {
  rezaForceWriteJson(rezaForceOrdersFile(), orders);
}

function rezaForceRefs(payload) {
  const d = payload || {};
  const data = d.data || d.payload || d.object || d.checkout || d.payment || d;

  return [...new Set([
    d.id,
    d.checkoutId,
    d.paymentId,
    d.reference,
    d.orderId,
    d.orderNumber,
    d.metadata?.orderId,
    d.metadata?.orderNumber,

    data.id,
    data.checkoutId,
    data.paymentId,
    data.reference,
    data.orderId,
    data.orderNumber,
    data.metadata?.orderId,
    data.metadata?.orderNumber,

    data.checkout?.id,
    data.checkout?.checkoutId,
    data.payment?.id,
    data.payment?.checkoutId
  ].filter(Boolean).map(String))];
}

function rezaForcePaid(payload) {
  const raw = JSON.stringify(payload || {}).toLowerCase();
  return (
    raw.includes("payment.succeeded") ||
    raw.includes("checkout.succeeded") ||
    raw.includes("checkout.completed") ||
    raw.includes('"status":"paid"') ||
    raw.includes('"status":"succeeded"') ||
    raw.includes('"status":"successful"')
  );
}

function rezaForceMarkPaid(refs, source) {
  const orders = rezaForceReadOrders();
  let found = -1;
  let matchedRef = "";

  for (const ref of refs.filter(Boolean)) {
    const r = String(ref);
    found = orders.findIndex(o => {
      const possible = [
        o.id,
        o.orderNumber,
        o.orderNo,
        o.yocoCheckoutId,
        o.checkoutId,
        o.paymentId,
        o.yocoPaymentId,
        o.payment?.checkoutId,
        o.payment?.id,
        o.yoco?.checkoutId,
        o.yoco?.id
      ].filter(Boolean).map(String);

      return possible.includes(r);
    });

    if (found !== -1) {
      matchedRef = r;
      break;
    }
  }

  if (found === -1) {
    return { success:false, message:"No matching order found", refs };
  }

  const now = new Date().toISOString();

  orders[found] = {
    ...orders[found],
    paymentStatus: "Paid",
    status: "Paid",
    paidAt: orders[found].paidAt || now,
    yocoPaidAt: orders[found].yocoPaidAt || now,
    yocoMatchedRef: matchedRef,
    yocoPaidSource: source || "webhook",
    updatedAt: now
  };

  rezaForceWriteOrders(orders);

  return {
    success:true,
    message:"Order marked paid",
    matchedRef,
    orderNumber: orders[found].orderNumber || orders[found].id
  };
}

app.post("/api/payments/yoco/webhook", express.json({ type: "*/*" }), (req, res) => {
  const payload = req.body || {};
  const refs = rezaForceRefs(payload);
  const paidEvent = rezaForcePaid(payload);

  let update = null;
  if (paidEvent) update = rezaForceMarkPaid(refs, "force-first-webhook");

  const events = rezaForceReadJson(REZA_FORCE_YOCO_EVENTS_FILE, []);
  events.unshift({
    receivedAt: new Date().toISOString(),
    route: "force-first-webhook",
    paidEvent,
    refs,
    update,
    payload
  });
  rezaForceWriteJson(REZA_FORCE_YOCO_EVENTS_FILE, events.slice(0, 100));

  return res.status(200).json({
    success:true,
    received:true,
    route:"force-first-webhook",
    paidEvent,
    refs,
    update
  });
});
// ======================================================
// END REZA FORCE-FIRST YOCO WEBHOOK HANDLER
// ======================================================


app.post("/api/payments/yoco/webhook", express.json({ type: "*/*" }), (req, res) => {
  const payload = req.body || {};
  const events = rezaJsonRead(REZA_YOCO_REAL_EVENTS_FILE, []);

  const refs = rezaYocoRefs(payload);
  const paidEvent = rezaLooksPaid(payload);

  let update = null;
  if (paidEvent) {
    update = rezaMarkPaidByRefs(refs, "webhook");
  }

  events.unshift({
    receivedAt: new Date().toISOString(),
    paidEvent,
    refs,
    update,
    payload
  });

  rezaJsonWrite(REZA_YOCO_REAL_EVENTS_FILE, events.slice(0, 100));

  res.status(200).json({
    success: true,
    received: true,
    paidEvent,
    refs,
    update
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