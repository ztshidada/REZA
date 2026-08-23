#!/usr/bin/env bash
set -e

echo "== Reza product batch update v2 =="

FILES=(
  "$HOME/Downloads/cream-single.jpg"
  "$HOME/Downloads/lotion-single.jpg"
  "$HOME/Downloads/glow-soap-single.jpg"
  "$HOME/Downloads/tissue-oil-single.jpg"
  "$HOME/Downloads/full-glow-combo.jpg"
  "$HOME/Downloads/tissue-oil-10-pack.jpg"
  "$HOME/Downloads/cream-10-pack.jpg"
  "$HOME/Downloads/lotion-10-pack.jpg"
  "$HOME/Downloads/glow-soap-10-pack-new.jpg"
)

for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing image: $f"
    echo "Save/rename the image first, then run again."
    exit 1
  fi
done

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "backup-before-product-batch-v2-$STAMP"
cp -R backend "backup-before-product-batch-v2-$STAMP/backend"
cp -R frontend "backup-before-product-batch-v2-$STAMP/frontend"
cp -R admin "backup-before-product-batch-v2-$STAMP/admin"

mkdir -p frontend/assets/images/products
mkdir -p admin/assets/images/products

copy_img () {
  src="$1"
  name="$2"
  cp "$src" "frontend/assets/images/products/$name"
  cp "$src" "admin/assets/images/products/$name"
}

copy_img "$HOME/Downloads/cream-single.jpg" "reza-collagen-anti-ageing-cream-new.jpg"
copy_img "$HOME/Downloads/lotion-single.jpg" "reza-anti-ageing-lotion-new.jpg"
copy_img "$HOME/Downloads/glow-soap-single.jpg" "reza-glow-soap-new.jpg"
copy_img "$HOME/Downloads/tissue-oil-single.jpg" "reza-luxury-tissue-oil-new.jpg"
copy_img "$HOME/Downloads/full-glow-combo.jpg" "reza-full-glow-combo-new.jpg"
copy_img "$HOME/Downloads/tissue-oil-10-pack.jpg" "reza-tissue-oil-10-pack-new.jpg"
copy_img "$HOME/Downloads/cream-10-pack.jpg" "reza-cream-10-pack-new.jpg"
copy_img "$HOME/Downloads/lotion-10-pack.jpg" "reza-lotion-10-pack-new.jpg"
copy_img "$HOME/Downloads/glow-soap-10-pack-new.jpg" "reza-glow-soap-10-pack-new.jpg"

python3 - <<'PY'
import json
from pathlib import Path

files = [
    Path("backend/data/products.json"),
    Path("frontend/assets/data/products.json")
]

def product(
    id,
    name,
    category,
    product_type,
    price,
    stock,
    badge,
    image,
    description,
    benefits,
    how_to_use
):
    return {
        "id": id,
        "name": name,
        "category": category,
        "productType": product_type,
        "status": "sale",
        "price": price,
        "stock": stock,
        "badge": badge,
        "image": f"assets/images/products/{image}",
        "description": description,
        "benefits": benefits,
        "howToUse": how_to_use,
        "showOnline": True,
        "showInPopup": False,
        "updatedAt": "2026-08-23T00:00:00.000Z"
    }

items = [
    product(
        "reza-collagen-anti-ageing-cream",
        "Reza Anti-Ageing Collagen Cream",
        "Singles",
        "Single",
        200,
        80,
        "Single",
        "reza-collagen-anti-ageing-cream-new.jpg",
        "A luxurious collagen-infused cream formulated to nourish and hydrate the skin while helping improve the appearance of fine lines and loss of firmness.",
        [
            "Boosts collagen production",
            "Firms skin",
            "Reduces fine lines",
            "Deeply moisturizes and nourishes"
        ],
        "Apply to clean skin and massage gently until absorbed. Use daily for best results."
    ),
    product(
        "reza-anti-ageing-lotion",
        "Reza Anti-Ageing Collagen Lotion",
        "Singles",
        "Single",
        200,
        80,
        "Single",
        "reza-anti-ageing-lotion-new.jpg",
        "A nourishing body lotion infused with collagen to help hydrate, smooth and improve the appearance of dry, dull-looking skin.",
        [
            "Hydrates skin",
            "Smooths dry-looking skin",
            "Leaves skin soft and supple",
            "Supports youthful-looking radiance"
        ],
        "Apply generously to clean skin and massage until absorbed. Use daily."
    ),
    product(
        "reza-glow-soap",
        "Reza Glow Soap",
        "Singles",
        "Single",
        80,
        150,
        "Single",
        "reza-glow-soap-new.jpg",
        "A luxurious cleansing soap infused with carrot to gently cleanse and refresh the skin while helping improve the appearance of dull, uneven-looking skin.",
        [
            "Brightens dull skin",
            "Evens skin tone",
            "Helps fade dark spots",
            "Reduces blemishes",
            "Deeply cleanses",
            "Leaves skin soft and smooth"
        ],
        "Lather on wet skin, gently massage in circular motions, rinse thoroughly, and use morning and night for best results."
    ),
    product(
        "reza-luxury-tissue-oil",
        "Reza Luxury Tissue Oil",
        "Singles",
        "Single",
        80,
        150,
        "Single",
        "reza-luxury-tissue-oil-new.jpg",
        "A nourishing and moisturising body oil formulated to help soften dry skin and improve the appearance of uneven-looking skin.",
        [
            "Deeply nourishing",
            "Fast absorbing",
            "Helps improve uneven-looking skin",
            "Suitable for all skin types"
        ],
        "Apply to clean skin and massage gently in circular motions twice daily for best results."
    ),
    product(
        "reza-complete-glow-combo",
        "Reza Luxury Full Glow Combo",
        "Combos",
        "Combo",
        560,
        60,
        "Glow Combo",
        "reza-full-glow-combo-new.jpg",
        "Your complete skincare routine for nourished, hydrated and radiant-looking skin. This combo includes Glow Soap, Tissue Oil, Anti-Ageing Collagen Cream and Anti-Ageing Collagen Lotion.",
        [
            "Complete 4-step skincare routine",
            "Cleanses, moisturises and pampers skin",
            "Supports radiant-looking skin",
            "Best value glow combo"
        ],
        "Use the soap, tissue oil, cream and lotion as part of your daily skincare routine."
    ),
    product(
        "reza-tissue-oil-business-pack",
        "Reza Tissue Oil – 10 Bottle Stock Pack",
        "10 Packs",
        "10 Pack",
        500,
        50,
        "10 Pack",
        "reza-tissue-oil-10-pack-new.jpg",
        "Stock up and grow your Reza business with our 10-bottle Tissue Oil Pack. Perfect for distributors and resellers.",
        [
            "10 bottles",
            "Great for resellers",
            "More stock, more sales",
            "Business stock pack"
        ],
        "Sell individually or keep as stock for customers."
    ),
    product(
        "reza-anti-ageing-cream-10-pack",
        "Reza Anti-Ageing Collagen Cream – 10 Bottle Stock Pack",
        "10 Packs",
        "10 Pack",
        1000,
        40,
        "10 Pack",
        "reza-cream-10-pack-new.jpg",
        "Stock up on our nourishing Anti-Ageing Collagen Cream with this convenient 10-bottle pack. Perfect for distributors and resellers.",
        [
            "10 bottles",
            "Great for resellers",
            "More stock, more sales",
            "Quality skincare stock pack"
        ],
        "Sell individually or keep as stock for customers."
    ),
    product(
        "reza-anti-ageing-lotion-10-pack",
        "Reza Anti-Ageing Collagen Lotion – 10 Bottle Stock Pack",
        "10 Packs",
        "10 Pack",
        1000,
        40,
        "10 Pack",
        "reza-lotion-10-pack-new.jpg",
        "Stock up on our nourishing Anti-Ageing Collagen Lotion with a 10-bottle pack, perfect for distributors and resellers.",
        [
            "10 bottles",
            "Great for resellers",
            "More stock, more sales",
            "Hydration stock pack"
        ],
        "Sell individually or keep as stock for customers."
    ),
    product(
        "reza-glow-soap-10-pack",
        "Reza Glow Soap – 10 Bar Stock Pack",
        "10 Packs",
        "10 Pack",
        400,
        60,
        "10 Pack",
        "reza-glow-soap-10-pack-new.jpg",
        "Stock up on our signature Reza Glow Soap with 10 bars, perfect for distributors and resellers.",
        [
            "10 bars",
            "Great for resellers",
            "More stock, more sales",
            "Glow soap value pack"
        ],
        "Use daily or sell individually to customers."
    )
]

def load(path):
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, list) else []
    except Exception:
        return []

def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2))

for path in files:
    data = load(path)

    for new_item in items:
        found = False
        for index, old_item in enumerate(data):
            if str(old_item.get("id")) == new_item["id"]:
                data[index] = {**old_item, **new_item}
                found = True
                break

        if not found:
            data.append(new_item)

    save(path, data)

print("✅ Product batch v2 applied to backend and frontend product data.")
PY

echo ""
echo "== Done =="
echo "Updated/replaced products and copied images into frontend + admin assets."
echo "Test locally:"
echo "python3 -m http.server 5173"
echo "Open: http://localhost:5173/frontend/shop.html"
