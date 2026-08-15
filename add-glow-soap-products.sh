#!/usr/bin/env bash
set -e

echo "== Adding Glow Soap products =="

SINGLE_IMG="$HOME/Downloads/glow-soap-r80.jpg"
PACKSHOT_IMG="$HOME/Downloads/glow-soap-packshot.jpg"
TENPACK_IMG="$HOME/Downloads/glow-soap-10-for-400.jpg"
COMBO_IMG="$HOME/Downloads/complete-glow-combo-560.jpg"

for f in "$SINGLE_IMG" "$PACKSHOT_IMG" "$TENPACK_IMG" "$COMBO_IMG"; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing file: $f"
    echo "Please save all 4 images in ~/Downloads with the exact names."
    exit 1
  fi
done

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "backup-before-glow-soap-$STAMP"
cp -R backend "backup-before-glow-soap-$STAMP/backend"
cp -R frontend "backup-before-glow-soap-$STAMP/frontend"

mkdir -p frontend/assets/images/products

cp "$SINGLE_IMG" frontend/assets/images/products/reza-glow-soap.jpg
cp "$PACKSHOT_IMG" frontend/assets/images/products/reza-glow-soap-packshot.jpg
cp "$TENPACK_IMG" frontend/assets/images/products/reza-glow-soap-10-pack.jpg
cp "$COMBO_IMG" frontend/assets/images/products/reza-complete-glow-combo.jpg

python3 - <<'PY'
import json
from pathlib import Path

root = Path(".")
backend_file = root / "backend/data/products.json"
frontend_file = root / "frontend/assets/data/products.json"

products_to_add = [
    {
        "id": "reza-glow-soap",
        "name": "Reza Glow Soap",
        "category": "Singles",
        "productType": "Single",
        "status": "sale",
        "price": 80,
        "stock": 120,
        "badge": "New",
        "image": "https://rezaholdings.co.za/assets/images/products/reza-glow-soap.jpg",
        "description": "Glow Soap infused with carrot extract, lemon extract, honey, aloe vera and natural oils. Helps brighten dull skin, even skin tone and leave skin soft and smooth.",
        "benefits": [
            "Brightens dull skin",
            "Evens skin tone",
            "Helps fade dark spots",
            "Reduces blemishes",
            "Deeply cleanses",
            "Leaves skin soft and smooth"
        ],
        "howToUse": "Lather on wet skin, gently massage in circular motions, rinse thoroughly, and use morning and night for best results.",
        "showOnline": True,
        "showInPopup": False,
        "updatedAt": "2026-05-30T00:00:00.000Z"
    },
    {
        "id": "reza-glow-soap-10-pack",
        "name": "Reza Glow Soap 10 Pack",
        "category": "10 Packs",
        "productType": "10 Pack",
        "status": "sale",
        "price": 400,
        "stock": 60,
        "badge": "10 Pack",
        "image": "https://rezaholdings.co.za/assets/images/products/reza-glow-soap-10-pack.jpg",
        "description": "10 Reza Glow Soaps for R400. Great value pack for glowing, brighter and more radiant skin.",
        "benefits": [
            "Value pack",
            "Brighten your skin",
            "Boost your confidence",
            "Feel beautiful every day"
        ],
        "howToUse": "Use daily on wet skin. Lather, gently massage, rinse thoroughly and use consistently for best results.",
        "showOnline": True,
        "showInPopup": False,
        "updatedAt": "2026-05-30T00:00:00.000Z"
    },
    {
        "id": "reza-complete-glow-combo",
        "name": "Reza Complete Glow Combo",
        "category": "Combos",
        "productType": "Combo",
        "status": "sale",
        "price": 560,
        "stock": 45,
        "badge": "Glow Combo",
        "image": "https://rezaholdings.co.za/assets/images/products/reza-complete-glow-combo.jpg",
        "description": "4-step glow combo including anti-ageing lotion, tissue oil, anti-ageing cream and glow soap for younger, brighter and radiant skin.",
        "benefits": [
            "Youthful glow",
            "Deep hydration",
            "Firms and tightens",
            "Evens skin tone",
            "Protects and repairs"
        ],
        "howToUse": "Use the anti-ageing lotion, tissue oil, anti-ageing cream and glow soap as part of your daily skincare routine.",
        "showOnline": True,
        "showInPopup": False,
        "updatedAt": "2026-05-30T00:00:00.000Z"
    }
]

def read_products(path):
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, list) else []
    except:
        return []

def write_products(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2))

def upsert_products(path, new_items):
    data = read_products(path)

    for new_item in new_items:
        found = False
        for i, old_item in enumerate(data):
            if str(old_item.get("id")) == new_item["id"]:
                data[i] = {**old_item, **new_item}
                found = True
                break
        if not found:
            data.append(new_item)

    write_products(path, data)

upsert_products(backend_file, products_to_add)
upsert_products(frontend_file, products_to_add)

print("✅ Added/updated products in:")
print("-", backend_file)
print("-", frontend_file)
PY

echo ""
echo "== Done =="
echo "Added products:"
echo "1) Reza Glow Soap - R80"
echo "2) Reza Glow Soap 10 Pack - R400"
echo "3) Reza Complete Glow Combo - R560"
echo ""
echo "Now test locally:"
echo "python3 -m http.server 5173"
echo "Open:"
echo "http://localhost:5173/frontend/shop.html"
