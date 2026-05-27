#!/bin/bash
set -e

PROJECT_DIR="$(pwd)"
OUT_DIR="$HOME/Desktop/reza-full-audit"
ZIP_FILE="$HOME/Desktop/reza-full-audit.zip"

rm -rf "$OUT_DIR" "$ZIP_FILE"
mkdir -p "$OUT_DIR"

echo "Creating Reza full audit bundle..."
echo "Project: $PROJECT_DIR"

# 1. Project tree
{
  echo "===== PROJECT TREE ====="
  find . \
    -path "./node_modules" -prune -o \
    -path "./.git" -prune -o \
    -path "./frontend/assets/images" -prune -o \
    -path "./frontend/uploads" -prune -o \
    -path "./backend/uploads" -prune -o \
    -type f -print | sort
} > "$OUT_DIR/00-project-tree.txt"

# 2. Git info
{
  echo "===== GIT STATUS ====="
  git status || true
  echo
  echo "===== LAST 20 COMMITS ====="
  git log --oneline -20 || true
  echo
  echo "===== REMOTES ====="
  git remote -v || true
} > "$OUT_DIR/01-git-info.txt"

# 3. Package files
mkdir -p "$OUT_DIR/package-files"
find . \
  -path "./node_modules" -prune -o \
  -path "./.git" -prune -o \
  \( -name "package.json" -o -name "package-lock.json" -o -name ".env.example" -o -name "render.yaml" -o -name "vite.config.*" \) \
  -type f -print | while read f; do
    safe=$(echo "$f" | sed 's#^\./##; s#[/]#__#g')
    cp "$f" "$OUT_DIR/package-files/$safe"
  done

# 4. Frontend HTML/CSS/JS
mkdir -p "$OUT_DIR/frontend-code"
if [ -d frontend ]; then
  find frontend \
    -path "frontend/assets/images" -prune -o \
    -path "frontend/uploads" -prune -o \
    \( -name "*.html" -o -name "*.css" -o -name "*.js" \) \
    -type f -print | while read f; do
      safe=$(echo "$f" | sed 's#[/]#__#g')
      cp "$f" "$OUT_DIR/frontend-code/$safe"
    done
fi

# 5. Admin HTML/CSS/JS
mkdir -p "$OUT_DIR/admin-code"
if [ -d admin ]; then
  find admin \
    \( -name "*.html" -o -name "*.css" -o -name "*.js" \) \
    -type f -print | while read f; do
      safe=$(echo "$f" | sed 's#[/]#__#g')
      cp "$f" "$OUT_DIR/admin-code/$safe"
    done
fi

# 6. Backend source
mkdir -p "$OUT_DIR/backend-code"
if [ -d backend ]; then
  find backend \
    -path "backend/node_modules" -prune -o \
    -path "backend/uploads" -prune -o \
    \( -name "*.js" -o -name "*.json" -o -name "*.env.example" \) \
    -type f -print | while read f; do
      safe=$(echo "$f" | sed 's#[/]#__#g')
      cp "$f" "$OUT_DIR/backend-code/$safe"
    done
fi

# 7. Search important connections
{
  echo "===== API URLS ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=assets --exclude="*.png" --exclude="*.jpg" --exclude="*.jpeg" --exclude="*.webp" \
    "api.rezaholdings\|localhost:10000\|fetch(\|/api/" . || true

  echo
  echo "===== CART KEYS ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git \
    "reza_cart\|rezaCart\|cart_items\|cartItems\|addToCart\|localStorage" frontend admin backend || true

  echo
  echo "===== POPUP ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git \
    "popup\|Popup\|sessionStorage\|localStorage" frontend admin backend || true

  echo
  echo "===== FEATURED PRODUCTS ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git \
    "featured\|Featured\|showFeatured\|featuredProducts" frontend admin backend || true

  echo
  echo "===== COMING SOON ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git \
    "Coming Soon\|comingSoon\|coming-soon\|comingSoonGrid" frontend admin backend || true

  echo
  echo "===== CHECKOUT ====="
  grep -RIn --exclude-dir=node_modules --exclude-dir=.git \
    "checkout\|Checkout\|order\|Order\|payfast\|yoco" frontend admin backend || true
} > "$OUT_DIR/02-important-search-results.txt"

# 8. HTML script/link order
{
  echo "===== HTML SCRIPT AND CSS ORDER ====="
  for f in frontend/*.html admin/*.html; do
    [ -f "$f" ] || continue
    echo
    echo "===== $f ====="
    grep -nE "<link|<script|cart|popup|featured|coming|checkout" "$f" || true
  done
} > "$OUT_DIR/03-html-script-css-order.txt"

# 9. File sizes
{
  echo "===== FILE SIZES ====="
  find . \
    -path "./node_modules" -prune -o \
    -path "./.git" -prune -o \
    -type f -print0 | xargs -0 ls -lh 2>/dev/null | sort -k5 -hr | head -100
} > "$OUT_DIR/04-largest-files.txt"

# 10. Make source zip excluding heavy/private folders
mkdir -p "$OUT_DIR/source-snapshot"
rsync -av \
  --exclude node_modules \
  --exclude .git \
  --exclude "frontend/assets/images" \
  --exclude "frontend/uploads" \
  --exclude "backend/uploads" \
  --exclude ".env" \
  --exclude "*.log" \
  ./ "$OUT_DIR/source-snapshot/" >/dev/null

cd "$HOME/Desktop"
zip -rq "$ZIP_FILE" reza-full-audit

echo
echo "DONE ✅"
echo "Audit ZIP created here:"
echo "$ZIP_FILE"
echo
echo "Upload this file to ChatGPT:"
echo "reza-full-audit.zip"
