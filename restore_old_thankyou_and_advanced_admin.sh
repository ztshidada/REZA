#!/bin/bash
set -e

OLD="$HOME/Downloads/S_version_7_oclock_yoco_fixed"

if [ ! -d "$OLD" ]; then
  echo "Old folder not found: $OLD"
  exit 1
fi

echo "Backing up current frontend/admin..."
mkdir -p backup-before-old-pages
cp -R frontend backup-before-old-pages/frontend-backup 2>/dev/null || true
cp -R admin backup-before-old-pages/admin-backup 2>/dev/null || true

echo "Restoring old thank-you and payment pages..."
for file in thank-you.html payment-success.html payment-failed.html payment-cancelled.html; do
  if [ -f "$OLD/frontend/$file" ]; then
    cp "$OLD/frontend/$file" "frontend/$file"
    echo "Copied frontend/$file"
  elif [ -f "$OLD/frontend_public/$file" ]; then
    cp "$OLD/frontend_public/$file" "frontend/$file"
    echo "Copied frontend_public/$file"
  fi
done

echo "Copying old advanced admin into admin/advanced..."
mkdir -p admin/advanced

if [ -d "$OLD/admin_frontend/admin" ]; then
  cp -R "$OLD/admin_frontend/admin/"* admin/advanced/
elif [ -d "$OLD/frontend/admin" ]; then
  cp -R "$OLD/frontend/admin/"* admin/advanced/
fi

if [ -d "$OLD/admin_frontend/js" ]; then
  mkdir -p admin/advanced/js
  cp -R "$OLD/admin_frontend/js/"* admin/advanced/js/
elif [ -d "$OLD/frontend/js" ]; then
  mkdir -p admin/advanced/js
  cp -R "$OLD/frontend/js/"* admin/advanced/js/
fi

if [ -d "$OLD/admin_frontend/css" ]; then
  mkdir -p admin/advanced/css
  cp -R "$OLD/admin_frontend/css/"* admin/advanced/css/
elif [ -d "$OLD/frontend/css" ]; then
  mkdir -p admin/advanced/css
  cp -R "$OLD/frontend/css/"* admin/advanced/css/
fi

cat > admin/advanced.html <<'HTML'
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Advanced Admin | Reza</title>
  <style>
    body{font-family:Arial,sans-serif;background:#fff7ed;margin:0;padding:30px;color:#241812}
    .card{max-width:900px;margin:auto;background:white;border-radius:28px;padding:28px;box-shadow:0 20px 60px rgba(0,0,0,.12)}
    h1{font-family:Georgia,serif;font-size:3rem;margin:0 0 18px}
    a{display:inline-flex;margin:8px;padding:13px 18px;border-radius:999px;background:#241812;color:white;text-decoration:none;font-weight:900}
  </style>
</head>
<body>
  <div class="card">
    <h1>Advanced Admin</h1>
    <p>Old advanced admin pages copied safely. They are available here without replacing your current admin.</p>
    <a href="advanced/dashboard.html">Dashboard</a>
    <a href="advanced/orders.html">Orders</a>
    <a href="advanced/payments.html">Payments</a>
    <a href="advanced/shipping.html">Shipping</a>
    <a href="advanced/products.html">Products</a>
    <a href="advanced/media.html">Media</a>
  </div>
</body>
</html>
HTML

git add .
git commit -m "Restore old thank you pages and advanced admin safely"
git push

echo "Done. Redeploy frontend and admin."
