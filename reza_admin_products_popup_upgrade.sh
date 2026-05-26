#!/bin/bash
set -e

echo "Upgrading Reza admin: products CRUD, show/hide eye, categories, popup settings..."

mkdir -p backend/data admin/js frontend/js frontend/assets/css

# 1. Patch backend with products + popup APIs
python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
text = p.read_text()

# Add required imports if missing
if 'const fs = require("fs")' not in text and "const fs = require('fs')" not in text:
    text = 'const fs = require("fs");\n' + text

if 'const path = require("path")' not in text and "const path = require('path')" not in text:
    text = 'const path = require("path");\n' + text

# Increase body size for images
text = text.replace("app.use(express.json());", 'app.use(express.json({ limit: "100mb" }));')
text = text.replace("express.json()", 'express.json({ limit: "100mb" })')

api_block = r'''
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
'''

if "REZA V11 PRODUCTS + POPUP ADMIN API" not in text:
    # Insert before 404 or app.listen
    markers = [
        "app.use((req, res)",
        'app.get("*"',
        "app.get('*'",
        "app.listen("
    ]

    inserted = False
    for marker in markers:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx] + api_block + "\n\n" + text[idx:]
            inserted = True
            break

    if not inserted:
        text += "\n\n" + api_block

p.write_text(text)
print("Backend API patched.")
PY

# 2. Replace admin products page with full working CRUD
cat > admin/products.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Products | Reza Admin</title>
  <style>
    *{box-sizing:border-box}
    body{margin:0;font-family:Arial,sans-serif;background:linear-gradient(135deg,#fffaf2,#f4e1c6);color:#241812}
    .layout{display:grid;grid-template-columns:280px 1fr;min-height:100vh}
    .side{padding:34px 28px;background:rgba(255,255,255,.55);border-right:1px solid rgba(0,0,0,.08)}
    .side h1{font-family:Georgia,serif;font-size:2.3rem;margin:0}.side h1 span{color:#b8872f}
    .side p{font-weight:800;color:#765c45}.side a{display:block;padding:15px 18px;margin:8px 0;border-radius:18px;color:#241812;text-decoration:none;font-weight:900}
    .side a.active,.side a:hover{background:#241812;color:#fffaf2}
    .main{padding:34px;overflow:auto}.head{display:flex;align-items:center;justify-content:space-between;gap:16px;margin-bottom:22px}
    h1.big{font-family:Georgia,serif;font-size:clamp(3rem,7vw,5.4rem);line-height:.9;margin:0}
    .btn{border:0;border-radius:999px;padding:13px 20px;font-weight:1000;cursor:pointer}
    .primary{background:linear-gradient(135deg,#e8c774,#c89334);color:#241812}.dark{background:#241812;color:#fffaf2}.danger{background:#a72222;color:white}.ghost{background:#fff;border:1px solid rgba(0,0,0,.14)}
    .card{background:rgba(255,255,255,.78);border-radius:28px;padding:22px;box-shadow:0 25px 70px rgba(60,38,20,.12)}
    .grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.full{grid-column:1/-1}
    input,select,textarea{width:100%;padding:14px;border-radius:14px;border:1px solid rgba(0,0,0,.15);font-size:1rem;background:white}
    textarea{min-height:90px}.preview{width:120px;height:90px;object-fit:cover;border-radius:16px;background:#f2dfc7}
    table{width:100%;border-collapse:collapse;margin-top:20px;background:white;border-radius:22px;overflow:hidden}
    th,td{padding:14px;border-bottom:1px solid #eee;text-align:left;vertical-align:middle}th{background:#f4e5cf}
    .actions{display:flex;gap:8px;flex-wrap:wrap}.small{padding:9px 12px;font-size:.85rem}.status{font-weight:900;margin:12px 0;color:#7a5017}
    .pill{display:inline-block;padding:7px 12px;border-radius:999px;background:#f0dfc2;font-weight:900}
    @media(max-width:850px){.layout{grid-template-columns:1fr}.grid{grid-template-columns:1fr}.main{padding:18px}.side{border-right:0}.head{align-items:flex-start;flex-direction:column}table{font-size:.84rem}th:nth-child(4),td:nth-child(4){display:none}}
  </style>
</head>
<body>
<div class="layout">
  <aside class="side">
    <h1>Reza <span>Admin</span></h1>
    <p>Champagne Luxury V11</p>
    <a href="dashboard.html">Dashboard</a>
    <a class="active" href="products.html">Products</a>
    <a href="media.html">Media</a>
    <a href="orders.html">Orders</a>
    <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
    <a href="login.html">Logout</a>
  </aside>

  <main class="main">
    <div class="head">
      <div>
        <h1 class="big">Products</h1>
        <p>Add, edit, hide/show and delete products.</p>
      </div>
      <button class="btn primary" id="newBtn">+ New Product</button>
    </div>

    <section class="card" id="formCard">
      <h2 id="formTitle">Add Product</h2>
      <div class="grid">
        <input id="name" placeholder="Product name">
        <input id="price" type="number" placeholder="Price, put 0 if unknown">
        <select id="category">
          <option>Skincare</option>
          <option>Combos</option>
          <option>Wellness</option>
          <option>Coming Soon</option>
          <option>Soap</option>
          <option>Collagen</option>
          <option>Sea Moss</option>
        </select>
        <select id="productType">
          <option>Single</option>
          <option>Pack of 5</option>
          <option>Pack of 10</option>
          <option>Combo</option>
          <option>Coming Soon</option>
        </select>
        <input id="stock" type="number" placeholder="Stock">
        <input id="badge" placeholder="Badge e.g. On Sale / Coming Soon">
        <select id="status">
          <option value="sale">On Sale</option>
          <option value="comingSoon">Coming Soon</option>
        </select>
        <select id="showOnline">
          <option value="true">Show on customer page</option>
          <option value="false">Hide from customer page</option>
        </select>
        <input class="full" id="imageFile" type="file" accept="image/*">
        <textarea class="full" id="description" placeholder="Description"></textarea>
      </div>
      <p class="status" id="statusText">Ready.</p>
      <div class="actions">
        <button class="btn primary" id="saveBtn">Save Product</button>
        <button class="btn ghost" id="clearBtn">Clear</button>
      </div>
    </section>

    <section class="card" style="margin-top:22px">
      <h2>Product List</h2>
      <table>
        <thead>
          <tr>
            <th>Image</th>
            <th>Name</th>
            <th>Category</th>
            <th>Type</th>
            <th>Price</th>
            <th>Show</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="productsBody"></tbody>
      </table>
    </section>
  </main>
</div>

<script>
const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
let products = [];
let editingId = null;
let imageData = "";

const $ = id => document.getElementById(id);

function fileToDataURL(file){
  return new Promise((resolve,reject)=>{
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

function money(v){
  const n = Number(v || 0);
  return n ? "R " + n.toLocaleString("en-ZA") : "R 0";
}

function setStatus(msg){ $("statusText").textContent = msg; }

function clearForm(){
  editingId = null;
  imageData = "";
  $("formTitle").textContent = "Add Product";
  ["name","price","stock","badge","description"].forEach(id => $(id).value = "");
  $("category").value = "Skincare";
  $("productType").value = "Single";
  $("status").value = "sale";
  $("showOnline").value = "true";
  $("imageFile").value = "";
  setStatus("Ready.");
}

async function api(path, options={}){
  const res = await fetch(API_BASE + path, {
    ...options,
    headers: { "Content-Type":"application/json", ...(options.headers || {}) }
  });
  const data = await res.json().catch(()=>({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API failed");
  return data;
}

async function loadProducts(){
  const data = await api("/api/products?t=" + Date.now());
  products = data.products || [];
  renderProducts();
}

function renderProducts(){
  $("productsBody").innerHTML = products.map(p => `
    <tr>
      <td><img class="preview" src="${p.image || ""}" onerror="this.style.opacity=.2"></td>
      <td><b>${p.name}</b><br><small>${p.description || ""}</small></td>
      <td>${p.category || ""}</td>
      <td><span class="pill">${p.productType || ""}</span></td>
      <td>${money(p.price)}</td>
      <td>${p.showOnline !== false ? "👁️ Visible" : "🙈 Hidden"}</td>
      <td>
        <div class="actions">
          <button class="btn small ghost" onclick="editProduct('${p.id}')">Edit</button>
          <button class="btn small dark" onclick="toggleProduct('${p.id}')">${p.showOnline !== false ? "Hide" : "Show"}</button>
          <button class="btn small danger" onclick="deleteProduct('${p.id}')">Delete</button>
        </div>
      </td>
    </tr>
  `).join("");
}

window.editProduct = function(id){
  const p = products.find(x => x.id === id);
  if(!p) return;

  editingId = id;
  $("formTitle").textContent = "Edit Product";
  $("name").value = p.name || "";
  $("price").value = p.price || 0;
  $("category").value = p.category || "Skincare";
  $("productType").value = p.productType || "Single";
  $("stock").value = p.stock || 0;
  $("badge").value = p.badge || "";
  $("status").value = p.status || "sale";
  $("showOnline").value = String(p.showOnline !== false);
  $("description").value = p.description || "";
  imageData = p.image || "";
  window.scrollTo({top:0,behavior:"smooth"});
};

window.toggleProduct = async function(id){
  await api("/api/products/" + id + "/toggle", { method:"PATCH" });
  await loadProducts();
};

window.deleteProduct = async function(id){
  if(!confirm("Delete this product?")) return;
  await api("/api/products/" + id, { method:"DELETE" });
  await loadProducts();
};

$("imageFile").addEventListener("change", async () => {
  const file = $("imageFile").files[0];
  if(file){
    setStatus("Reading image...");
    imageData = await fileToDataURL(file);
    setStatus("Image ready.");
  }
});

$("saveBtn").addEventListener("click", async () => {
  try{
    setStatus("Saving...");
    const payload = {
      name: $("name").value.trim(),
      price: Number($("price").value || 0),
      category: $("category").value,
      productType: $("productType").value,
      stock: Number($("stock").value || 0),
      badge: $("badge").value.trim(),
      status: $("status").value,
      showOnline: $("showOnline").value === "true",
      description: $("description").value.trim(),
      image: imageData
    };

    if(!payload.name){
      alert("Product name is required.");
      return;
    }

    if(editingId){
      await api("/api/products/" + editingId, { method:"PUT", body:JSON.stringify(payload) });
    } else {
      await api("/api/products", { method:"POST", body:JSON.stringify(payload) });
    }

    clearForm();
    await loadProducts();
    setStatus("Saved successfully.");
  }catch(err){
    console.error(err);
    alert(err.message);
    setStatus("Save failed.");
  }
});

$("clearBtn").addEventListener("click", clearForm);
$("newBtn").addEventListener("click", clearForm);

loadProducts().catch(err => {
  console.error(err);
  setStatus("Could not load products. Check backend deploy.");
});
</script>
</body>
</html>
HTML

# 3. Dashboard popup admin page
cat > admin/dashboard.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Dashboard | Reza Admin</title>
  <style>
    *{box-sizing:border-box}body{margin:0;font-family:Arial,sans-serif;background:linear-gradient(135deg,#fffaf2,#f4e1c6);color:#241812}
    .layout{display:grid;grid-template-columns:280px 1fr;min-height:100vh}.side{padding:34px 28px;background:rgba(255,255,255,.55);border-right:1px solid rgba(0,0,0,.08)}
    .side h1{font-family:Georgia,serif;font-size:2.3rem;margin:0}.side h1 span{color:#b8872f}.side p{font-weight:800;color:#765c45}
    .side a{display:block;padding:15px 18px;margin:8px 0;border-radius:18px;color:#241812;text-decoration:none;font-weight:900}.side a.active,.side a:hover{background:#241812;color:#fffaf2}
    .main{padding:34px}.big{font-family:Georgia,serif;font-size:clamp(3rem,7vw,5.4rem);line-height:.9;margin:0 0 20px}
    .card{background:rgba(255,255,255,.78);border-radius:28px;padding:22px;box-shadow:0 25px 70px rgba(60,38,20,.12);max-width:900px}
    .grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.full{grid-column:1/-1}
    input,select,textarea{width:100%;padding:14px;border-radius:14px;border:1px solid rgba(0,0,0,.15);font-size:1rem;background:white}textarea{min-height:110px}
    .btn{border:0;border-radius:999px;padding:13px 20px;font-weight:1000;cursor:pointer}.primary{background:linear-gradient(135deg,#e8c774,#c89334);color:#241812}.ghost{background:white;border:1px solid rgba(0,0,0,.14)}
    .status{font-weight:900;margin-top:14px;color:#7a5017}.preview{width:100%;max-height:240px;object-fit:cover;border-radius:18px;margin-top:12px}
    @media(max-width:850px){.layout{grid-template-columns:1fr}.grid{grid-template-columns:1fr}.main{padding:18px}.side{border-right:0}}
  </style>
</head>
<body>
<div class="layout">
  <aside class="side">
    <h1>Reza <span>Admin</span></h1>
    <p>Champagne Luxury V11</p>
    <a class="active" href="dashboard.html">Dashboard</a>
    <a href="products.html">Products</a>
    <a href="media.html">Media</a>
    <a href="orders.html">Orders</a>
    <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
    <a href="login.html">Logout</a>
  </aside>

  <main class="main">
    <h1 class="big">Dashboard</h1>
    <section class="card">
      <h2>Website Pop-up Message</h2>
      <p>Use this for specials, promotions, announcements or new product alerts.</p>
      <div class="grid">
        <select id="enabled">
          <option value="false">Popup OFF</option>
          <option value="true">Popup ON</option>
        </select>
        <input id="title" placeholder="Popup title">
        <input id="buttonText" placeholder="Button text e.g. Shop Special">
        <input id="buttonLink" placeholder="Button link e.g. shop.html">
        <input class="full" id="imageFile" type="file" accept="image/*">
        <textarea class="full" id="message" placeholder="Popup message"></textarea>
      </div>
      <img id="preview" class="preview" style="display:none">
      <p class="status" id="status">Loading...</p>
      <button class="btn primary" id="saveBtn">Save Pop-up</button>
      <button class="btn ghost" id="testBtn">Open Website</button>
    </section>
  </main>
</div>

<script>
const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
const $ = id => document.getElementById(id);
let imageData = "";

function fileToDataURL(file){
  return new Promise((resolve,reject)=>{
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

async function api(path, options={}){
  const res = await fetch(API_BASE + path, {
    ...options,
    headers:{ "Content-Type":"application/json", ...(options.headers || {}) }
  });
  const data = await res.json().catch(()=>({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API failed");
  return data;
}

async function loadPopup(){
  const data = await api("/api/popup?t=" + Date.now());
  const p = data.popup || {};
  $("enabled").value = String(Boolean(p.enabled));
  $("title").value = p.title || "";
  $("message").value = p.message || "";
  $("buttonText").value = p.buttonText || "Shop Now";
  $("buttonLink").value = p.buttonLink || "shop.html";
  imageData = p.image || "";
  if(imageData){
    $("preview").src = imageData;
    $("preview").style.display = "block";
  }
  $("status").textContent = "Ready.";
}

$("imageFile").addEventListener("change", async () => {
  const file = $("imageFile").files[0];
  if(file){
    imageData = await fileToDataURL(file);
    $("preview").src = imageData;
    $("preview").style.display = "block";
  }
});

$("saveBtn").addEventListener("click", async () => {
  try{
    $("status").textContent = "Saving...";
    await api("/api/popup", {
      method:"POST",
      body:JSON.stringify({
        enabled: $("enabled").value === "true",
        title: $("title").value.trim(),
        message: $("message").value.trim(),
        buttonText: $("buttonText").value.trim() || "Shop Now",
        buttonLink: $("buttonLink").value.trim() || "shop.html",
        image: imageData
      })
    });
    $("status").textContent = "Popup saved.";
    alert("Popup saved.");
  }catch(err){
    console.error(err);
    $("status").textContent = "Save failed.";
    alert(err.message);
  }
});

$("testBtn").addEventListener("click", () => window.open("https://rezaholdings.co.za/index.html","_blank"));
loadPopup().catch(err => {
  console.error(err);
  $("status").textContent = "Could not load popup. Check backend deploy.";
});
</script>
</body>
</html>
HTML

# 4. Customer popup script
cat > frontend/js/reza-popup.js <<'JS'
(function(){
  const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

  async function loadPopup(){
    try{
      const res = await fetch(API_BASE + "/api/popup?t=" + Date.now());
      const data = await res.json();

      if(!data.success || !data.popup || !data.popup.enabled) return;

      const p = data.popup;

      const overlay = document.createElement("div");
      overlay.className = "reza-popup-overlay";
      overlay.innerHTML = `
        <div class="reza-popup-card">
          <button class="reza-popup-close" type="button">×</button>
          ${p.image ? `<img src="${p.image}" alt="Special" class="reza-popup-img">` : ""}
          <p class="reza-popup-kicker">Reza Announcement</p>
          <h2>${p.title || "Special Announcement"}</h2>
          <p>${p.message || ""}</p>
          <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
        </div>
      `;

      document.body.appendChild(overlay);

      overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
      overlay.addEventListener("click", e => {
        if(e.target === overlay) overlay.remove();
      });
    }catch(err){
      console.warn("Popup not loaded", err);
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    setTimeout(loadPopup, 900);
  });
})();
JS

cat > frontend/assets/css/reza-popup.css <<'CSS'
.reza-popup-overlay{
  position:fixed;
  inset:0;
  z-index:99999;
  background:rgba(20,14,10,.55);
  backdrop-filter:blur(10px);
  display:grid;
  place-items:center;
  padding:18px;
}
.reza-popup-card{
  width:min(520px,94vw);
  background:linear-gradient(135deg,#fffaf2,#f1dcc0);
  border-radius:28px;
  padding:24px;
  position:relative;
  box-shadow:0 30px 90px rgba(0,0,0,.28);
  color:#241812;
}
.reza-popup-close{
  position:absolute;
  top:14px;
  right:14px;
  width:38px;
  height:38px;
  border:0;
  border-radius:50%;
  font-size:24px;
  cursor:pointer;
  background:#241812;
  color:white;
}
.reza-popup-img{
  width:100%;
  max-height:260px;
  object-fit:cover;
  border-radius:20px;
  margin-bottom:14px;
}
.reza-popup-kicker{
  text-transform:uppercase;
  letter-spacing:.22em;
  color:#a87622;
  font-weight:900;
  font-size:.75rem;
}
.reza-popup-card h2{
  font-family:Georgia,serif;
  font-size:2.4rem;
  margin:0 0 10px;
}
.reza-popup-card a{
  display:inline-flex;
  margin-top:14px;
  padding:13px 20px;
  border-radius:999px;
  background:linear-gradient(135deg,#e8c774,#c89334);
  color:#241812;
  font-weight:1000;
  text-decoration:none;
}
@media(max-width:500px){
  .reza-popup-card h2{font-size:2rem}
}
CSS

# Inject popup CSS and JS into all frontend pages
python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/reza-popup\.css[^"]*">\s*', '\n', text)
    text = re.sub(r'\s*<script src="js/reza-popup\.js[^"]*"></script>\s*', '\n', text)

    text = text.replace("</head>", '  <link rel="stylesheet" href="assets/css/reza-popup.css?v=1">\n</head>')
    text = text.replace("</body>", '  <script src="js/reza-popup.js?v=1"></script>\n</body>')

    p.write_text(text, encoding="utf-8")
    print("Injected popup:", p)
PY

git add .
git commit -m "Add product edit delete visibility and popup admin controls"
git push

echo "Done. Redeploy backend, admin, frontend."
