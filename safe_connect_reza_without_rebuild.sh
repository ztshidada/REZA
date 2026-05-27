#!/bin/bash
set -e

echo "Safe Reza connection repair..."
echo "No pages will be rebuilt. No products will be reset."

# =========================================================
# 1. Backend: add orders API only if missing
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

orders_block = r'''
// ======================================================
// REZA ORDERS API - SAFE ADD
// ======================================================
const REZA_SAFE_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaSafeEnsureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_SAFE_ORDERS_FILE)) {
    fs.writeFileSync(REZA_SAFE_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaSafeReadOrders() {
  try {
    rezaSafeEnsureOrdersFile();
    return JSON.parse(fs.readFileSync(REZA_SAFE_ORDERS_FILE, "utf8"));
  } catch {
    return [];
  }
}

function rezaSafeWriteOrders(orders) {
  rezaSafeEnsureOrdersFile();
  fs.writeFileSync(REZA_SAFE_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

app.get("/api/orders", (req, res) => {
  res.json({ success: true, orders: rezaSafeReadOrders() });
});

app.post("/api/orders", (req, res) => {
  const body = req.body || {};
  const items = Array.isArray(body.items) ? body.items : [];

  if (!items.length) {
    return res.status(400).json({ success: false, message: "Cart is empty" });
  }

  const orders = rezaSafeReadOrders();

  const subtotal = items.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  const orderNumber =
    "REZA-" +
    new Date().toISOString().slice(0, 10).replace(/-/g, "") +
    "-" +
    String(orders.length + 1).padStart(4, "0");

  const order = {
    id: orderNumber.toLowerCase(),
    orderNumber,
    customer: body.customer || {},
    items,
    subtotal,
    total: subtotal,
    delivery: "Calculated after order",
    status: "New Order",
    paymentStatus: "Pending",
    createdAt: new Date().toISOString()
  };

  orders.unshift(order);
  rezaSafeWriteOrders(orders);

  res.json({ success: true, message: "Order created", order });
});
// ======================================================
// END REZA ORDERS API - SAFE ADD
// ======================================================
'''

if 'REZA ORDERS API - SAFE ADD' not in text and 'app.post("/api/orders"' not in text:
    marker = 'app.use((req, res) => {'
    if marker in text:
        text = text.replace(marker, orders_block + "\n\n" + marker, 1)
    else:
        text += "\n\n" + orders_block

p.write_text(text)
print("Backend orders API checked.")
PY

# =========================================================
# 2. Patch app.js safely: live API + one cart source
# =========================================================
python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/js/app.js")
if p.exists():
    text = p.read_text()

    text = re.sub(
        r'const API_BASE=localStorage\.getItem\("REZA_API_BASE"\)\|\|"http://localhost:10000"',
        'const API_BASE=localStorage.getItem("REZA_API_BASE")||(location.hostname.includes("localhost")?"http://localhost:10000":"https://api.rezaholdings.co.za")',
        text,
        count=1
    )

    text = re.sub(
        r'function cart\(\)\{try\{return JSON\.parse\(localStorage\.getItem\("reza_v11_cart"\)\|\|"\[\]"\)\}catch\{return\[\]\}\}',
        '''function cart(){const keys=["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"];for(const k of keys){try{const v=JSON.parse(localStorage.getItem(k)||"[]");if(Array.isArray(v)&&v.length)return v}catch{}}return[]}''',
        text,
        count=1
    )

    text = re.sub(
        r'function saveCart\(c\)\{localStorage\.setItem\("reza_v11_cart",JSON\.stringify\(c\)\);count\(\)\}',
        '''function saveCart(c){["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"].forEach(k=>localStorage.setItem(k,JSON.stringify(c)));count()}''',
        text,
        count=1
    )

    text = re.sub(
        r'localStorage\.removeItem\("reza_v11_cart"\);alert\("Order created: "\+d\.order\.orderNumber\);',
        '''["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"].forEach(k=>localStorage.removeItem(k));alert("Order created: "+d.order.orderNumber);''',
        text,
        count=1
    )

    p.write_text(text)
    print("frontend/js/app.js patched.")
PY

# =========================================================
# 3. Patch reza-cart-system: all cart keys + all count badges
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("frontend/js/reza-cart-system.js")
text = p.read_text()

text = text.replace(
    'const CART_KEYS = ["reza_cart", "rezaCart", "cart"];',
    'const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];'
)

old_write = '''    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));'''

new_write = '''    CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));'''

text = text.replace(old_write, new_write)

text = text.replace(
    'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],#cartCount").forEach(el => {',
    'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],[data-count],#cartCount").forEach(el => {'
)

p.write_text(text)
print("reza-cart-system.js patched.")
PY

# =========================================================
# 4. Patch reza-products-master: featuredGrid + coming-soon + count
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("frontend/js/reza-products-master.js")
text = p.read_text()

text = text.replace(
    'const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];',
    'const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];'
)

old_save = '''    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));'''

text = text.replace(old_save, '    CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));')

text = text.replace(
    'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],.bag-count").forEach(el => {',
    'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],[data-count],.bag-count,#cartCount").forEach(el => {'
)

text = text.replace(
'''      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")''',
'''      document.querySelector("#featuredGrid"),
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")'''
)

text = text.replace(
'''      p.status !== "comingSoon" &&
      p.category !== "Coming Soon" &&
      p.productType !== "Coming Soon"''',
'''      p.status !== "comingSoon" &&
      p.status !== "coming-soon" &&
      p.category !== "Coming Soon" &&
      p.productType !== "Coming Soon"'''
)

text = text.replace(
'''      p.status === "comingSoon" ||
      p.category === "Coming Soon" ||
      p.productType === "Coming Soon"''',
'''      p.status === "comingSoon" ||
      p.status === "coming-soon" ||
      p.category === "Coming Soon" ||
      p.productType === "Coming Soon" ||
      p.comingSoon === true'''
)

text = text.replace(
'''      if (grid.id === "featuredProducts" || grid.classList.contains("featured-products")) return;''',
'''      if (grid.id === "featuredGrid" || grid.id === "featuredProducts" || grid.classList.contains("featured-products")) return;'''
)

text = text.replace(
    'alert("Added to cart");',
    'console.log("Added to cart");'
)

p.write_text(text)
print("reza-products-master.js patched.")
PY

# =========================================================
# 5. Patch cart-master checkout button to actual link
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("frontend/js/reza-cart-master.js")
if p.exists():
    text = p.read_text()

    text = text.replace(
        'const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];',
        'const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];'
    )

    text = text.replace(
'''    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));''',
'''    CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));'''
    )

    text = text.replace(
        'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],.bag-count").forEach(el => {',
        'document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],[data-count],.bag-count,#cartCount").forEach(el => {'
    )

    text = text.replace(
        '<button type="button" class="reza-checkout-btn">Checkout</button>',
        '<a href="checkout.html" class="reza-checkout-btn">Checkout</a>'
    )

    p.write_text(text)
    print("reza-cart-master.js patched.")
PY

# =========================================================
# 6. Patch coming-soon inline filter + image URLs
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("frontend/coming-soon.html")
text = p.read_text()

text = text.replace(
'products = products.filter(p => p.comingSoon || p.status === "coming-soon" || p.showOnline === false);',
'products = products.filter(p => p.comingSoon || p.status === "comingSoon" || p.status === "coming-soon" || p.category === "Coming Soon" || p.productType === "Coming Soon");'
)

text = text.replace(
'<img src="${p.image}" alt="${p.name}">',
'<img src="${p.image && p.image.startsWith("/") ? API_BASE + p.image : (p.image || "assets/images/reza-card-bg.svg")}" alt="${p.name}">'
)

p.write_text(text)
print("coming-soon.html patched.")
PY

# =========================================================
# 7. Patch home inline featured logic to selected 3
# =========================================================
python3 - <<'PY'
from pathlib import Path

p = Path("frontend/index.html")
text = p.read_text()

text = text.replace(
'const products = (data.products || []).filter(p => p.showOnline !== false).slice(0, 4);',
'''const saleProducts = (data.products || []).filter(p => p.showOnline !== false && p.status !== "comingSoon" && p.status !== "coming-soon" && p.category !== "Coming Soon" && p.productType !== "Coming Soon");
        const selectedFeatured = saleProducts.filter(p => p.showFeatured === true).slice(0, 3);
        const products = selectedFeatured.length ? selectedFeatured : saleProducts.slice(0, 3);'''
)

text = text.replace('Add to Cart', 'Add to Bag')

p.write_text(text)
print("index.html featured patched.")
PY

# =========================================================
# 8. Commit and push
# =========================================================
git add .
git commit -m "Safe fix Reza connections without rebuilding pages"
git push

echo "DONE. Redeploy backend and frontend."
