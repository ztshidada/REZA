#!/bin/bash
set -e

echo "Adding Reza product pack..."

if [ ! -d "frontend" ] || [ ! -d "backend" ]; then
  echo "Please run this script from inside your project folder, e.g:"
  echo "cd ~/Downloads/reza-v11-champagne-luxury"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p frontend/assets/images/products
mkdir -p frontend/assets/data
mkdir -p backend/data

cp "$SCRIPT_DIR"/reza_product_images/*.jpg frontend/assets/images/products/

SCRIPT_DIR="$SCRIPT_DIR" python3 - <<'PY'
from pathlib import Path
import json, os

script_dir = Path(os.environ.get("SCRIPT_DIR", "."))
data_file = script_dir / "products-data.json"
new_products = json.loads(data_file.read_text(encoding="utf-8"))
targets = [
    Path("backend/data/products.json"),
    Path("frontend/assets/data/products.json"),
]

for target in targets:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        try:
            current = json.loads(target.read_text())
            if isinstance(current, dict) and "products" in current:
                current = current["products"]
            if not isinstance(current, list):
                current = []
        except Exception:
            current = []
    else:
        current = []

    by_id = {p.get("id"): p for p in current if isinstance(p, dict) and p.get("id")}
    for p in new_products:
        by_id[p["id"]] = p

    merged = list(by_id.values())
    target.write_text(json.dumps(merged, indent=2), encoding="utf-8")
    print(f"Updated {target} with {len(new_products)} Reza products.")
PY

cat > frontend/coming-soon.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Coming Soon | Reza Holdings</title>
  <link rel="stylesheet" href="reza-style.css">
  <style>
    body{background:#fff8ee;color:#251711}
    .soon-hero{padding:90px 8vw 48px;background:linear-gradient(135deg,#fff8ee,#f4dfc2)}
    .soon-hero h1{font-family:Georgia,serif;font-size:clamp(3rem,8vw,6rem);line-height:.9;margin:0 0 16px}
    .soon-hero p{max-width:720px;font-size:1.1rem;line-height:1.6}
    .soon-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px;padding:44px 8vw 90px}
    .soon-card{background:white;border-radius:28px;overflow:hidden;box-shadow:0 20px 60px rgba(96,62,24,.12);border:1px solid rgba(190,140,54,.16)}
    .soon-card img{width:100%;height:280px;object-fit:cover;display:block}
    .soon-card .body{padding:22px}
    .soon-card h3{margin:0 0 8px;font-size:1.35rem}
    .soon-card p{color:#665246;line-height:1.5}
    .badge{display:inline-flex;background:#e5bd62;color:#2b180d;border-radius:999px;padding:8px 13px;font-weight:900;margin-bottom:10px}
    .top-link{display:inline-flex;margin-top:20px;padding:12px 18px;border-radius:999px;background:#241812;color:white;text-decoration:none;font-weight:900}
  </style>
</head>
<body>
  <section class="soon-hero">
    <p style="letter-spacing:.25em;font-weight:900;color:#a56c17">REZA HOLDINGS</p>
    <h1>Coming Soon</h1>
    <p>These premium Reza products are being prepared for launch. Marine Collagen, Sea Moss and the bathing soap collection will appear here until they are ready for sale.</p>
    <a class="top-link" href="index.html">Back Home</a>
  </section>
  <main id="comingSoonGrid" class="soon-grid"></main>

  <script>
    const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
    function money(v){ return Number(v||0) > 0 ? "R " + Number(v).toLocaleString("en-ZA") : "Coming Soon"; }
    async function loadSoon(){
      let products = [];
      try {
        const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
        const data = await res.json();
        products = data.products || [];
      } catch(e) {
        const res = await fetch("assets/data/products.json?t=" + Date.now());
        products = await res.json();
      }
      products = products.filter(p => p.comingSoon || p.status === "coming-soon" || p.showOnline === false);
      document.getElementById("comingSoonGrid").innerHTML = products.map(p => `
        <article class="soon-card">
          <img src="${p.image}" alt="${p.name}">
          <div class="body">
            <span class="badge">${p.badge || "Coming Soon"}</span>
            <h3>${p.name}</h3>
            <p>${p.description || ""}</p>
            <strong>${money(p.price)}</strong>
          </div>
        </article>
      `).join("") || "<p>No coming soon products yet.</p>";
    }
    loadSoon();
  </script>
</body>
</html>
HTML

# Add a small Coming Soon link near Catalog/Shop if possible
python3 - <<'PY'
from pathlib import Path
for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")
    if "coming-soon.html" in text:
        continue
    # Add after Catalog or Shop link if found
    replacements = [
        ('<a href="shop.html">Catalog</a>', '<a href="shop.html">Catalog</a><a href="coming-soon.html">Coming Soon</a>'),
        ('<a href="shop.html">Shop</a>', '<a href="shop.html">Shop</a><a href="coming-soon.html">Coming Soon</a>'),
        ('<a href="catalog.html">Catalog</a>', '<a href="catalog.html">Catalog</a><a href="coming-soon.html">Coming Soon</a>'),
    ]
    for old, new in replacements:
        if old in text:
            text = text.replace(old, new, 1)
            p.write_text(text, encoding="utf-8")
            print("Added Coming Soon link to", p)
            break
PY

git add .
git commit -m "Add Reza product pack and coming soon page"
git push

echo "Done. Redeploy in this order:"
echo "1) reza-backend"
echo "2) reza-frontend"
