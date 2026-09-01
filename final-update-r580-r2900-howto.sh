#!/usr/bin/env bash
set -e

echo "== Final update: fix image paths, R580 combo, R2900 combo, How To Use page =="

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "backup-before-final-r580-r2900-howto-$STAMP"
cp -R backend "backup-before-final-r580-r2900-howto-$STAMP/backend"
cp -R frontend "backup-before-final-r580-r2900-howto-$STAMP/frontend"

python3 - <<'PY'
import json
import re
from pathlib import Path

product_files = [
    Path("backend/data/products.json"),
    Path("frontend/assets/data/products.json")
]

def load(path):
    if not path.exists():
        return []
    data = json.loads(path.read_text())
    return data if isinstance(data, list) else []

def save(path, data):
    path.write_text(json.dumps(data, indent=2))

def clean_image_path(value):
    if not isinstance(value, str):
        return value
    return value.replace("\\.jpg", ".jpg").replace("\\.jpeg", ".jpeg").replace("\\.png", ".png")

def upsert(data, item):
    for i, old in enumerate(data):
        if str(old.get("id")) == item["id"]:
            data[i] = {**old, **item}
            return
    data.append(item)

r580_combo = {
    "id": "reza-complete-glow-combo",
    "name": "Reza Glow Combo",
    "category": "Combos",
    "productType": "Combo",
    "status": "sale",
    "price": 580,
    "stock": 60,
    "badge": "Glow Combo",
    "image": "assets/images/products/reza-glow-combo-r580.jpg",
    "description": "The ultimate 4-in-1 Reza Glow Combo for healthy, clear and radiant-looking skin. Includes Anti-Ageing Lotion, Tissue Oil, Glow Soap and Collagen Anti-Ageing Cream.",
    "benefits": [
        "Brightens dark spots",
        "Fades acne and blemishes",
        "Evens skin tone",
        "Deep hydration",
        "Healthy youthful glow"
    ],
    "howToUse": "Use daily as a 4-step routine: wash with Glow Soap, apply Anti-Ageing Lotion, apply Tissue Oil to areas needing extra care, and apply Collagen Cream in the evening.",
    "showOnline": True,
    "showInPopup": False,
    "updatedAt": "2026-09-01T00:00:00.000Z"
}

ultimate_combo = {
    "id": "reza-ultimate-glow-combo-r2900",
    "name": "Reza Ultimate Glow Combo",
    "category": "Specials",
    "productType": "Special",
    "status": "sale",
    "price": 2900,
    "stock": 30,
    "badge": "Special Offer",
    "image": "assets/images/products/reza-ultimate-glow-combo-r2900.jpg",
    "description": "The ultimate Reza business stock combo with 40 products: 10 Anti-Ageing Lotions, 10 Tissue Oils, 10 Anti-Ageing Creams and 10 Glow Soaps. Includes free T-shirt and cap.",
    "benefits": [
        "40 products",
        "10 lotions",
        "10 tissue oils",
        "10 creams",
        "10 glow soaps",
        "Free T-shirt and cap",
        "Best value business stock combo"
    ],
    "howToUse": "Perfect for distributors, resellers and customers who want a full Reza skincare stock package.",
    "showOnline": True,
    "showInPopup": False,
    "updatedAt": "2026-09-01T00:00:00.000Z"
}

for path in product_files:
    data = load(path)

    for p in data:
        if "image" in p:
            p["image"] = clean_image_path(p["image"])

    upsert(data, r580_combo)
    upsert(data, ultimate_combo)

    save(path, data)

howto = Path("frontend/how-to-use.html")
howto.write_text("""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>How To Use | Reza Holdings</title>
  <meta name="description" content="How to use Reza Glow Combo daily routine." />
  <link rel="stylesheet" href="css/app.css" />
  <link rel="stylesheet" href="reza-style.css" />
  <style>
    body{
      background:linear-gradient(180deg,#fff7ed,#fff);
      color:#241812;
    }
    .howto-hero{
      max-width:1100px;
      margin:0 auto;
      padding:70px 18px 30px;
      text-align:center;
    }
    .howto-hero span{
      display:inline-flex;
      padding:8px 14px;
      border-radius:999px;
      background:rgba(200,147,52,.15);
      color:#8a5b14;
      font-weight:900;
      letter-spacing:.08em;
      text-transform:uppercase;
      font-size:12px;
      margin-bottom:14px;
    }
    .howto-hero h1{
      font-size:clamp(42px,8vw,82px);
      line-height:.9;
      letter-spacing:-.06em;
      margin:0;
    }
    .howto-hero p{
      max-width:760px;
      margin:18px auto 0;
      color:rgba(36,24,18,.72);
      font-size:18px;
      line-height:1.6;
    }
    .howto-card{
      max-width:1000px;
      margin:0 auto 80px;
      padding:18px;
    }
    .howto-card img{
      width:100%;
      display:block;
      border-radius:28px;
      box-shadow:0 24px 70px rgba(36,24,18,.15);
      background:#fff;
    }
    .howto-actions{
      display:flex;
      justify-content:center;
      gap:12px;
      flex-wrap:wrap;
      margin-top:22px;
    }
    .howto-actions a{
      text-decoration:none;
      border-radius:999px;
      padding:14px 22px;
      font-weight:1000;
      background:linear-gradient(135deg,#f5d36b,#c89334);
      color:#241812;
    }
    .howto-actions a.dark{
      background:#241812;
      color:#fffaf3;
    }
  </style>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="index.html">REZA</a>
    <nav class="site-nav">
      <a href="index.html">Home</a>
      <a href="shop.html">Catalog</a>
      <a href="testimony.html">Testimony</a>
      <a href="how-to-use.html">How To Use</a>
      <a href="contact.html">Contact</a>
    </nav>
  </header>

  <main>
    <section class="howto-hero">
      <span>Daily routine</span>
      <h1>How To Use</h1>
      <p>Follow the Reza Glow Combo morning and evening routine for consistent skincare results.</p>
    </section>

    <section class="howto-card">
      <img src="assets/images/pages/reza-how-to-use-glow-routine.jpg" alt="Reza Glow Combo how to use daily routine">
      <div class="howto-actions">
        <a href="shop.html">Shop Products</a>
        <a class="dark" href="testimony.html">View Testimonies</a>
      </div>
    </section>
  </main>
</body>
</html>
""")

# Add How To Use nav link to frontend pages if there is a Testimony link
for f in Path("frontend").glob("*.html"):
    text = f.read_text(errors="ignore")
    if f.name != "how-to-use.html" and "how-to-use.html" not in text:
        text = re.sub(
            r'(<a[^>]+href=["\\\']testimony\.html["\\\'][^>]*>.*?</a>)',
            r'\\1\n      <a href="how-to-use.html">How To Use</a>',
            text,
            count=1,
            flags=re.I | re.S
        )
        f.write_text(text)

print("✅ Product data fixed and How To Use page created.")
PY

git add backend/data/products.json \
        frontend/assets/data/products.json \
        frontend/how-to-use.html \
        frontend/*.html \
        final-update-r580-r2900-howto.sh

git commit -m "Update glow combo to R580 and add ultimate combo and how to use page" || true

git push

echo "== Done =="
