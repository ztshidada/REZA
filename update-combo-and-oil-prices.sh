#!/usr/bin/env bash
set -e

echo "== Updating combo and oil prices =="

python3 - <<'PY'
import json
from pathlib import Path

files = [
    Path("backend/data/products.json"),
    Path("frontend/assets/data/products.json")
]

for file in files:
    data = json.loads(file.read_text())

    for p in data:
        name = str(p.get("name", "")).lower()
        pid = str(p.get("id", "")).lower()

        # Complete Anti-Ageing Skin Combo R480 -> R500
        if (
            "complete anti-ageing skin combo" in name
            or "complete anti ageing skin combo" in name
            or pid == "reza-starter-pack-combo"
        ):
            p["price"] = 500
            p["updatedAt"] = "2026-09-01T00:00:00.000Z"
            print(f"Updated combo price in {file}: {p.get('name')} -> R500")

        # Tissue Oil R80 -> R100
        if (
            "tissue oil" in name
            and "10" not in name
            and "stock pack" not in name
            and "business pack" not in name
            and "cracked heels" not in name
        ) or pid == "reza-luxury-tissue-oil":
            p["price"] = 100
            p["updatedAt"] = "2026-09-01T00:00:00.000Z"
            print(f"Updated oil price in {file}: {p.get('name')} -> R100")

    file.write_text(json.dumps(data, indent=2))

print("✅ Prices updated.")
PY

git add backend/data/products.json frontend/assets/data/products.json update-combo-and-oil-prices.sh

git commit -m "Update combo and tissue oil prices"

git push

echo "== Done =="
