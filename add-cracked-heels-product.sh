#!/usr/bin/env bash
set -e

echo "== Adding Reza Cracked Heels product =="

IMG_SOURCE="$HOME/Downloads/cracked-heels.jpg"
IMG_TARGET_REL="assets/images/products/reza-cracked-heels-premium-tissue-oil.jpg"
IMG_TARGET_FRONTEND="frontend/$IMG_TARGET_REL"

if [ ! -f "$IMG_SOURCE" ]; then
  echo "❌ Image not found at: $IMG_SOURCE"
  echo "Please save the picture as ~/Downloads/cracked-heels.jpg and run again."
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "backup-before-cracked-heels-$STAMP"
cp -R backend "backup-before-cracked-heels-$STAMP/backend"
cp -R frontend "backup-before-cracked-heels-$STAMP/frontend"

mkdir -p frontend/assets/images/products
cp "$IMG_SOURCE" "$IMG_TARGET_FRONTEND"

python3 - <<'PY'
import json, os
from pathlib import Path

root = Path(".")
backend_file = root / "backend/data/products.json"
frontend_file = root / "frontend/assets/data/products.json"

product_id = "reza-cracked-heels-premium-tissue-oil"
image_url = "https://rezaholdings.co.za/assets/images/products/reza-cracked-heels-premium-tissue-oil.jpg"

product = {
    "id": product_id,
    "name": "Reza Cracked Heels Premium Tissue Oil",
    "category": "Singles",
    "productType": "Single",
    "status": "sale",
    "price": 200,
    "stock": 50,
    "badge": "New",
    "image": image_url,
    "description": "A luxurious multi-purpose tissue oil specially formulated to improve the appearance of cracked heels and leave heels soft, smooth and beautiful.",
    "benefits": [
        "Helps improve the appearance of cracked heels",
        "Deeply nourishing formula",
        "Non-greasy and lightweight feel",
        "Safe and effective for daily use",
        "Suitable for all skin types"
    ],
    "howToUse": "Apply to clean skin and massage gently into cracked heels in circular motions twice daily for best results.",
    "showOnline": True,
    "showInPopup": False,
    "updatedAt": "2026-05-30T00:00:00.000Z"
}

def upsert_products(file_path):
    if file_path.exists():
        try:
            data = json.loads(file_path.read_text())
        except:
            data = []
    else:
        data = []

    if not isinstance(data, list):
        data = []

    found = False
    for i, item in enumerate(data):
        if str(item.get("id")) == product_id:
            data[i] = {**item, **product}
            found = True
            break

    if not found:
        data.append(product)

    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(json.dumps(data, indent=2))

upsert_products(backend_file)
upsert_products(frontend_file)

print("✅ Product added/updated in:")
print("-", backend_file)
print("-", frontend_file)
PY

echo "== Done =="
echo "Product added:"
echo "  Reza Cracked Heels Premium Tissue Oil"
echo "  Price: R200"
echo ""
echo "Image copied to:"
echo "  frontend/assets/images/products/reza-cracked-heels-premium-tissue-oil.jpg"
echo ""
echo "Now test:"
echo "1) Start your project"
echo "2) Open /shop.html"
echo "3) Open /product.html?id=reza-cracked-heels-premium-tissue-oil"
