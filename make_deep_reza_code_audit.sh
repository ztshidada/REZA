#!/bin/bash
set -e

OUT="$HOME/Desktop/reza-deep-code-audit"
ZIP="$HOME/Desktop/reza-deep-code-audit.zip"

rm -rf "$OUT" "$ZIP"
mkdir -p "$OUT"

echo "Creating deep Reza code audit..."

# Copy project without heavy/private folders
mkdir -p "$OUT/project"
rsync -av ./ "$OUT/project/" \
  --exclude node_modules \
  --exclude .git \
  --exclude .env \
  --exclude "*.log" \
  --exclude ".DS_Store" >/dev/null

# Full file tree
find . \
  -path "./node_modules" -prune -o \
  -path "./.git" -prune -o \
  -type f -print | sort > "$OUT/01-full-file-tree.txt"

# HTML pages and what they load
{
  echo "===== HTML PAGES: CSS + JS ORDER ====="
  for f in frontend/*.html admin/*.html; do
    [ -f "$f" ] || continue
    echo
    echo "=================================================="
    echo "$f"
    echo "=================================================="
    grep -nE "<link|<script|onclick|href=|id=|class=|data-" "$f" || true
  done
} > "$OUT/02-html-css-js-map.txt"

# JavaScript functions
{
  echo "===== JS FUNCTIONS ====="
  find frontend admin backend -type f -name "*.js" 2>/dev/null | sort | while read f; do
    echo
    echo "=================================================="
    echo "$f"
    echo "=================================================="
    grep -nE "function |const .*=>|let .*=>|var .*=>|window\.|document\.|addEventListener|fetch\(|localStorage|sessionStorage|addToCart|cart|checkout|popup|featured|coming" "$f" || true
  done
} > "$OUT/03-js-function-map.txt"

# CSS selectors
{
  echo "===== CSS SELECTORS / IMPORTANT STYLE MAP ====="
  find frontend admin -type f -name "*.css" 2>/dev/null | sort | while read f; do
    echo
    echo "=================================================="
    echo "$f"
    echo "=================================================="
    grep -nE "cart|bag|product|featured|coming|popup|checkout|hero|nav|mobile|@media|grid|display|position|overflow|height|width" "$f" || true
  done
} > "$OUT/04-css-important-map.txt"

# Backend API routes
{
  echo "===== BACKEND API ROUTES ====="
  find backend -type f -name "*.js" 2>/dev/null | sort | while read f; do
    echo
    echo "=================================================="
    echo "$f"
    echo "=================================================="
    grep -nE "app\.get|app\.post|app\.put|app\.delete|router\.get|router\.post|router\.put|router\.delete|/api/|products|orders|media|popup|upload" "$f" || true
  done
} > "$OUT/05-backend-routes-map.txt"

# Cart keys and storage conflict map
{
  echo "===== CART / STORAGE CONFLICTS ====="
  grep -RIn \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    "reza_cart\|rezaCart\|reza_v11_cart\|cart_items\|cartItems\|localStorage\|sessionStorage\|addToCart\|cartCount\|bag-count\|cart-badge" \
    frontend admin backend || true
} > "$OUT/06-cart-storage-conflicts.txt"

# Product rendering conflict map
{
  echo "===== PRODUCT RENDERING CONFLICTS ====="
  grep -RIn \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    "renderProducts\|productCard\|productsGrid\|product-grid\|featured\|showFeatured\|comingSoon\|Coming Soon\|showOnline\|productType\|category" \
    frontend admin backend || true
} > "$OUT/07-product-render-conflicts.txt"

# Checkout map
{
  echo "===== CHECKOUT MAP ====="
  grep -RIn \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    "checkout\|Checkout\|placeOrder\|orders\|/api/orders\|payfast\|yoco\|customer\|delivery" \
    frontend admin backend || true
} > "$OUT/08-checkout-map.txt"

# Popup map
{
  echo "===== POPUP MAP ====="
  grep -RIn \
    --exclude-dir=node_modules \
    --exclude-dir=.git \
    "popup\|Popup\|announcement\|special\|sessionStorage\|showInPopup\|/api/popup" \
    frontend admin backend || true
} > "$OUT/09-popup-map.txt"

# Current Git status
{
  echo "===== GIT STATUS ====="
  git status || true
  echo
  echo "===== LAST 30 COMMITS ====="
  git log --oneline -30 || true
} > "$OUT/10-git-status.txt"

# Check for duplicated scripts inside HTML
{
  echo "===== DUPLICATE SCRIPT/CSS CHECK ====="
  for f in frontend/*.html admin/*.html; do
    [ -f "$f" ] || continue
    echo
    echo "=================================================="
    echo "$f"
    echo "=================================================="
    grep -oE 'src="[^"]+\.js[^"]*"' "$f" | sort | uniq -c || true
    grep -oE 'href="[^"]+\.css[^"]*"' "$f" | sort | uniq -c || true
  done
} > "$OUT/11-duplicate-load-check.txt"

# Zip everything
cd "$HOME/Desktop"
zip -rq "$ZIP" reza-deep-code-audit

echo ""
echo "DONE ✅"
echo "Upload this file:"
echo "$ZIP"
