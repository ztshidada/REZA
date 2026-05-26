#!/bin/bash
set -e

echo "🔥 Reza: adding Manyora Special popup image and fixing admin controls..."

mkdir -p frontend/assets/images/specials frontend/assets/css frontend/js backend/data
cp reza-special-popup-fix/assets/images/specials/manyora-special.jpg frontend/assets/images/specials/manyora-special.jpg

python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
text = p.read_text()

if 'const fs = require("fs");' not in text and "const fs = require('fs');" not in text:
    text = 'const fs = require("fs");\n' + text
if 'const path = require("path");' not in text and "const path = require('path');" not in text:
    text = 'const path = require("path");\n' + text

text = text.replace("app.use(express.json());", 'app.use(express.json({ limit: "100mb" }));')
text = text.replace("app.use(express.urlencoded({ extended: true }));", 'app.use(express.urlencoded({ extended: true, limit: "100mb" }));')

api = """
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
"""

if "REZA FINAL PRODUCTS + POPUP API" not in text:
    markers = ["app.use((req, res)", 'app.get("*"', "app.get('*'", "app.listen("]
    for marker in markers:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx] + api + "\n" + text[idx:]
            break
    else:
        text += "\n" + api

p.write_text(text)
print("✅ backend patched")
PY

python3 - <<'PY'
from pathlib import Path
import json
products_file = Path("backend/data/products.json")
products_file.parent.mkdir(parents=True, exist_ok=True)
try:
    products = json.loads(products_file.read_text())
except Exception:
    products = []
for p in products:
    name = (p.get("name") or "").lower()
    p.setdefault("productType", "Single")
    p.setdefault("price", 0)
    p.setdefault("stock", 0)
    p.setdefault("description", "")
    p.setdefault("image", "")
    if "sea moss" in name or "marine collagen" in name or "acne care" in name or p.get("category") == "Coming Soon" or p.get("status") == "comingSoon":
        p["category"] = "Coming Soon"
        p["status"] = "comingSoon"
        p["productType"] = "Coming Soon"
        p["showOnline"] = False
        p["badge"] = "Coming Soon"
    else:
        p.setdefault("status", "sale")
        p["showOnline"] = p.get("showOnline", True)
products_file.write_text(json.dumps(products, indent=2))
print("✅ products normalized")
PY

cat > admin/dashboard.html <<'HTML'
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Dashboard | Reza Admin</title>
<style>*{box-sizing:border-box}body{margin:0;font-family:Arial,sans-serif;background:linear-gradient(135deg,#fffaf2,#f4e1c6);color:#241812}.layout{display:grid;grid-template-columns:280px 1fr;min-height:100vh}.side{padding:34px 28px;background:rgba(255,255,255,.62)}.side h1{font-family:Georgia,serif;font-size:2.2rem;margin:0}.side h1 span{color:#b8872f}.side a{display:block;padding:15px 18px;margin:8px 0;border-radius:18px;color:#241812;text-decoration:none;font-weight:900}.side a.active,.side a:hover{background:#241812;color:#fffaf2}.main{padding:34px}.big{font-family:Georgia,serif;font-size:clamp(3rem,7vw,5.4rem);line-height:.9;margin:0 0 20px}.card{background:rgba(255,255,255,.82);border-radius:28px;padding:22px;max-width:900px;box-shadow:0 25px 70px rgba(60,38,20,.12)}.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.full{grid-column:1/-1}input,select,textarea{width:100%;padding:14px;border-radius:14px;border:1px solid rgba(0,0,0,.15);font-size:1rem}textarea{min-height:110px}.btn{border:0;border-radius:999px;padding:13px 20px;font-weight:1000;cursor:pointer}.primary{background:linear-gradient(135deg,#e8c774,#c89334);color:#241812}.preview{width:100%;max-height:320px;object-fit:contain;border-radius:18px;margin-top:14px;background:#fff7ee}.status{font-weight:900;color:#875d1d}@media(max-width:850px){.layout{grid-template-columns:1fr}.grid{grid-template-columns:1fr}.main{padding:18px}}</style>
</head><body><div class="layout"><aside class="side"><h1>Reza <span>Admin</span></h1><p>Champagne Luxury V11</p><a class="active" href="dashboard.html">Dashboard</a><a href="products.html">Products</a><a href="media.html">Media</a><a href="orders.html">Orders</a><a href="https://rezaholdings.co.za" target="_blank">View Website</a><a href="login.html">Logout</a></aside><main class="main"><h1 class="big">Dashboard</h1><section class="card"><h2>Special Pop-up</h2><p>Turn this on when you want the website to show your special.</p><div class="grid"><select id="enabled"><option value="false">Popup OFF</option><option value="true">Popup ON</option></select><select id="category"><option>Specials</option><option>Announcement</option><option>New Product</option></select><input id="title" placeholder="Title e.g. Manyora Special"><input id="buttonText" placeholder="Button text e.g. Shop Special"><input class="full" id="buttonLink" placeholder="Button link e.g. shop.html"><input class="full" id="imageFile" type="file" accept="image/*"><textarea class="full" id="message" placeholder="Message"></textarea></div><img id="preview" class="preview" src="https://rezaholdings.co.za/assets/images/specials/manyora-special.jpg"><p class="status" id="status">Ready.</p><button class="btn primary" id="saveBtn">Save Pop-up</button></section></main></div>
<script>
const API=location.hostname.includes("localhost")?"http://localhost:10000":"https://api.rezaholdings.co.za";const $=id=>document.getElementById(id);let imageData="https://rezaholdings.co.za/assets/images/specials/manyora-special.jpg";
function fileToDataURL(file){return new Promise((res,rej)=>{const r=new FileReader();r.onload=()=>res(r.result);r.onerror=rej;r.readAsDataURL(file);});}
async function api(path,opt={}){const r=await fetch(API+path,{...opt,headers:{"Content-Type":"application/json",...(opt.headers||{})}});const d=await r.json().catch(()=>({}));if(!r.ok||d.success===false)throw new Error(d.message||"API failed");return d;}
async function load(){const d=await api("/api/popup?t="+Date.now());const p=d.popup||{};$("enabled").value=String(Boolean(p.enabled));$("category").value=p.category||"Specials";$("title").value=p.title||"Manyora Special";$("message").value=p.message||"Limited time Reza skincare special. Best value for your skin.";$("buttonText").value=p.buttonText||"Shop Special";$("buttonLink").value=p.buttonLink||"shop.html";imageData=p.image||imageData;$("preview").src=imageData;$("status").textContent="Ready."}
$("imageFile").onchange=async()=>{const f=$("imageFile").files[0];if(f){imageData=await fileToDataURL(f);$("preview").src=imageData;}}
$("saveBtn").onclick=async()=>{try{$("status").textContent="Saving...";await api("/api/popup",{method:"POST",body:JSON.stringify({enabled:$("enabled").value==="true",category:$("category").value,title:$("title").value,message:$("message").value,buttonText:$("buttonText").value||"Shop Special",buttonLink:$("buttonLink").value||"shop.html",image:imageData})});$("status").textContent="Saved.";alert("Popup saved.")}catch(e){alert(e.message);$("status").textContent="Save failed."}}
load().catch(e=>{$("status").textContent="Could not load popup. Deploy backend first.";console.error(e)});
</script></body></html>
HTML

cat > frontend/js/reza-popup.js <<'JS'
(function(){
  const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
  async function run(){
    try{
      const r = await fetch(API + "/api/popup?t=" + Date.now());
      const d = await r.json();
      const p = d.popup || {};
      if(!d.success || !p.enabled) return;
      const el = document.createElement("div");
      el.className = "reza-popup-overlay";
      el.innerHTML = `<div class="reza-popup-card"><button class="reza-popup-close">×</button>${p.image?`<img src="${p.image}" class="reza-popup-img" alt="Special">`:""}<p class="reza-popup-kicker">${p.category||"Specials"}</p><h2>${p.title||"Special"}</h2><p>${p.message||""}</p><a href="${p.buttonLink||"shop.html"}">${p.buttonText||"Shop Now"}</a></div>`;
      document.body.appendChild(el);
      el.querySelector(".reza-popup-close").onclick=()=>el.remove();
      el.onclick=e=>{if(e.target===el)el.remove();}
    }catch(e){console.warn("Popup failed",e)}
  }
  document.addEventListener("DOMContentLoaded",()=>setTimeout(run,800));
})();
JS

cat > frontend/assets/css/reza-popup.css <<'CSS'
.reza-popup-overlay{position:fixed;inset:0;z-index:99999;background:rgba(22,14,10,.55);backdrop-filter:blur(10px);display:grid;place-items:center;padding:18px}.reza-popup-card{width:min(560px,94vw);background:linear-gradient(135deg,#fffaf2,#f3ddc5);border-radius:28px;padding:22px;position:relative;box-shadow:0 30px 90px rgba(0,0,0,.3);color:#241812}.reza-popup-close{position:absolute;right:14px;top:14px;width:38px;height:38px;border:0;border-radius:50%;font-size:24px;background:#241812;color:white;cursor:pointer}.reza-popup-img{width:100%;max-height:360px;object-fit:contain;border-radius:20px;background:#fff;margin-bottom:14px}.reza-popup-kicker{text-transform:uppercase;letter-spacing:.22em;color:#a87622;font-weight:900;font-size:.75rem}.reza-popup-card h2{font-family:Georgia,serif;font-size:2.3rem;margin:0 0 10px}.reza-popup-card a{display:inline-flex;margin-top:14px;padding:13px 20px;border-radius:999px;background:linear-gradient(135deg,#e8c774,#c89334);color:#241812;font-weight:1000;text-decoration:none}
CSS

python3 - <<'PY'
from pathlib import Path
import re
for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")
    text = re.sub(r'\s*<link rel="stylesheet" href="assets/css/reza-popup\.css[^"]*">\s*','\n',text)
    text = re.sub(r'\s*<script src="js/reza-popup\.js[^"]*"></script>\s*','\n',text)
    text = text.replace("</head>", '<link rel="stylesheet" href="assets/css/reza-popup.css?v=popup2">\n</head>')
    text = text.replace("</body>", '<script src="js/reza-popup.js?v=popup2"></script>\n</body>')
    p.write_text(text, encoding="utf-8")
    print("Injected popup", p)
PY

cat >> frontend/assets/css/reza-products-final.css <<'CSS'

/* Coming soon image fix: never crop, show full poster/image */
#comingSoonGrid img,
.coming-soon-grid img,
.reza-final-product-image {
  object-fit: contain !important;
  object-position: center !important;
  background: #fff7ee !important;
}

.reza-final-product-image-wrap {
  background: #fff7ee !important;
}
CSS

git add .
git commit -m "Add special popup and stronger admin product controls"
git push

echo "✅ Done."
echo "Now redeploy:"
echo "1) reza-backend"
echo "2) admin_frontend"
echo "3) reza-frontend"
