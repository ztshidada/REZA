#!/bin/bash
set -e

echo "Restoring Yoco payment logic only..."
echo "No products, pages, or admin data will be reset."

mkdir -p backend/src/routes frontend

# ======================================================
# 1. Add self-contained Yoco payments route
# ======================================================
cat > backend/src/routes/payments.js <<'JS'
const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();
const YOCO_BASE_URL = "https://payments.yoco.com";

const DATA_DIR = path.join(__dirname, "../../data");
const ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function ensureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(ORDERS_FILE)) {
    fs.writeFileSync(ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function readOrders() {
  try {
    ensureOrdersFile();
    return JSON.parse(fs.readFileSync(ORDERS_FILE, "utf8"));
  } catch {
    return [];
  }
}

function writeOrders(orders) {
  ensureOrdersFile();
  fs.writeFileSync(ORDERS_FILE, JSON.stringify(orders, null, 2));
}

function cents(amount) {
  return Math.round(Number(amount || 0) * 100);
}

function getYocoSecretKey() {
  return process.env.YOCO_SECRET_KEY || process.env.YOCO_LIVE_SECRET_KEY || "";
}

function yocoConfigured() {
  const key = getYocoSecretKey();
  return Boolean(key && !key.includes("your_") && (key.startsWith("sk_") || key.startsWith("yoco_")));
}

function keyMode() {
  const key = getYocoSecretKey();
  if (key.startsWith("sk_live_") || key.startsWith("yoco_live_")) return "live";
  if (key.startsWith("sk_test_") || key.startsWith("yoco_test_")) return "test";
  return "missing";
}

function frontendUrl(req) {
  return process.env.FRONTEND_URL || process.env.SITE_URL || req.headers.origin || "https://rezaholdings.co.za";
}

function makeOrder(input) {
  const body = input || {};
  const items = Array.isArray(body.items) ? body.items : [];

  const total = Number(
    body.total !== undefined
      ? body.total
      : items.reduce((sum, item) => sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1), 0)
  );

  const orderNumber =
    body.id ||
    body.orderNumber ||
    "REZA-" +
      new Date().toISOString().slice(0, 10).replace(/-/g, "") +
      "-" +
      String(readOrders().length + 1).padStart(4, "0");

  return {
    ...body,
    id: orderNumber,
    orderNumber,
    customer: body.customer || {},
    items,
    subtotal: Number(body.subtotal || total),
    total,
    paymentMethod: "Yoco",
    paymentStatus: "Pending Payment",
    deliveryStatus: body.deliveryStatus || "New Order",
    status: body.status || "New Order",
    source: "reza-v11-checkout",
    yocoKeyMode: keyMode(),
    createdAt: body.createdAt || new Date().toISOString()
  };
}

function upsertOrder(order) {
  const orders = readOrders();
  const id = String(order.id || order.orderNumber);
  const index = orders.findIndex(o => String(o.id || o.orderNumber) === id);

  if (index >= 0) orders[index] = { ...orders[index], ...order };
  else orders.unshift(order);

  writeOrders(orders);
  return index >= 0 ? orders[index] : order;
}

function findOrder(id) {
  const orders = readOrders();
  return orders.find(o =>
    String(o.id) === String(id) ||
    String(o.orderNumber) === String(id) ||
    String(o.yocoCheckoutId) === String(id)
  );
}

function updateOrder(id, updates) {
  const orders = readOrders();
  const index = orders.findIndex(o =>
    String(o.id) === String(id) ||
    String(o.orderNumber) === String(id) ||
    String(o.yocoCheckoutId) === String(id)
  );

  if (index === -1) return null;

  orders[index] = { ...orders[index], ...updates, updatedAt: new Date().toISOString() };
  writeOrders(orders);
  return orders[index];
}

async function createYocoCheckout(order, req) {
  if (!yocoConfigured()) {
    throw new Error("YOCO_SECRET_KEY is not configured on Render.");
  }

  if (Number(order.total || 0) < 2) {
    throw new Error("Yoco payments must be at least R2.00.");
  }

  const publicUrl = frontendUrl(req);
  const orderId = order.id || order.orderNumber;

  const payload = {
    amount: Math.max(cents(order.total), 200),
    currency: "ZAR",
    successUrl: `${publicUrl}/payment-success.html?order=${encodeURIComponent(orderId)}`,
    cancelUrl: `${publicUrl}/payment-cancelled.html?order=${encodeURIComponent(orderId)}`,
    failureUrl: `${publicUrl}/payment-failed.html?order=${encodeURIComponent(orderId)}`,
    metadata: {
      orderId: String(orderId),
      orderNumber: String(orderId),
      customerName: String(order.customer?.name || order.customer?.fullName || ""),
      customerPhone: String(order.customer?.phone || "")
    }
  };

  const response = await fetch(`${YOCO_BASE_URL}/api/checkouts`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${getYocoSecretKey()}`,
      "Content-Type": "application/json",
      "Idempotency-Key": String(orderId)
    },
    body: JSON.stringify(payload)
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok || !data.redirectUrl) {
    const msg =
      data.displayMessage ||
      data.message ||
      data.error ||
      JSON.stringify(data) ||
      `Yoco checkout failed with status ${response.status}`;

    throw new Error(msg);
  }

  return data;
}

function eventLooksPaid(event) {
  const text = JSON.stringify(event || {}).toLowerCase();
  return (
    text.includes("payment.succeeded") ||
    text.includes("checkout.completed") ||
    text.includes('"status":"succeeded"') ||
    text.includes('"status":"successful"') ||
    text.includes('"status":"completed"')
  );
}

function extractOrderOrCheckoutId(event) {
  return (
    event?.payload?.metadata?.orderId ||
    event?.payload?.metadata?.orderNumber ||
    event?.metadata?.orderId ||
    event?.metadata?.orderNumber ||
    event?.payload?.checkoutId ||
    event?.checkoutId ||
    event?.payload?.id ||
    event?.id ||
    null
  );
}

router.get("/yoco/diagnostics", (req, res) => {
  res.json({
    success: true,
    yocoConfigured: yocoConfigured(),
    keyMode: keyMode(),
    webhookConfigured: Boolean(process.env.YOCO_WEBHOOK_SECRET),
    keySource: process.env.YOCO_SECRET_KEY ? "YOCO_SECRET_KEY" : process.env.YOCO_LIVE_SECRET_KEY ? "YOCO_LIVE_SECRET_KEY" : "missing",
    frontendUrl: process.env.FRONTEND_URL || process.env.SITE_URL || "https://rezaholdings.co.za",
    webhookUrl: "https://api.rezaholdings.co.za/api/payments/yoco/webhook"
  });
});

router.post("/yoco/create-checkout", async (req, res) => {
  try {
    const orderInput = req.body.order || req.body;
    const order = makeOrder(orderInput);

    if (!order.items.length) {
      return res.status(400).json({ success: false, message: "Cart is empty." });
    }

    const savedOrder = upsertOrder(order);
    const checkout = await createYocoCheckout(savedOrder, req);

    const updatedOrder = upsertOrder({
      ...savedOrder,
      yocoCheckoutId: checkout.id,
      yocoRedirectUrl: checkout.redirectUrl,
      yocoPaymentId: checkout.paymentId || null,
      yocoProcessingMode: checkout.processingMode || null,
      paymentStatus: "Pending Payment"
    });

    res.json({
      success: true,
      order: updatedOrder,
      checkout,
      redirectUrl: checkout.redirectUrl
    });
  } catch (error) {
    console.error("Yoco create checkout error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get("/yoco/status/:id", (req, res) => {
  const order = findOrder(req.params.id);

  if (!order) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  res.json({
    success: true,
    order,
    checkoutId: order.yocoCheckoutId,
    paymentStatus: order.paymentStatus,
    deliveryStatus: order.deliveryStatus,
    keyMode: keyMode()
  });
});

router.post("/yoco/verify-order/:orderId", (req, res) => {
  const order = findOrder(req.params.orderId);

  if (!order) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  res.json({
    success: true,
    order,
    paymentStatus: order.paymentStatus,
    checkoutId: order.yocoCheckoutId
  });
});

router.get("/yoco/webhook", (req, res) => {
  res.json({
    success: true,
    message: "Yoco webhook endpoint is live. Yoco will send POST requests here.",
    webhookUrl: "https://api.rezaholdings.co.za/api/payments/yoco/webhook"
  });
});

router.post("/yoco/webhook", (req, res) => {
  try {
    const event = req.body || {};
    const id = extractOrderOrCheckoutId(event);

    if (!id) {
      return res.status(200).json({ success: true, ignored: true, reason: "No order/checkout id found" });
    }

    const updates = {
      yocoWebhookLastEvent: event,
      yocoWebhookReceivedAt: new Date().toISOString()
    };

    if (eventLooksPaid(event)) {
      updates.paymentStatus = "Paid";
      updates.status = "Paid";
      updates.yocoPaymentId = event?.payload?.paymentId || event?.paymentId || event?.payload?.id || null;
    }

    const order = updateOrder(id, updates) || updateOrder(event?.payload?.metadata?.orderId, updates);

    res.json({
      success: true,
      updated: Boolean(order),
      order,
      id
    });
  } catch (error) {
    console.error("Yoco webhook error:", error);
    res.status(200).json({ success: false, message: error.message });
  }
});

module.exports = router;
JS

# ======================================================
# 2. Mount route in current backend server.js
# ======================================================
python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
text = p.read_text()

if 'const paymentRoutes = require("./routes/payments");' not in text:
    # put after existing require lines
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("const ") and "require(" in line:
            insert_at = i + 1
    lines.insert(insert_at, 'const paymentRoutes = require("./routes/payments");')
    text = "\n".join(lines)

if 'app.use("/api/payments", paymentRoutes);' not in text:
    markers = [
        'app.use((req, res) => {',
        'app.use((req, res)',
        'app.listen('
    ]

    inserted = False
    for marker in markers:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx] + 'app.use("/api/payments", paymentRoutes);\n\n' + text[idx:]
            inserted = True
            break

    if not inserted:
        text += '\napp.use("/api/payments", paymentRoutes);\n'

# Add browser-test GET diagnostics/webhook only if not there
if 'app.get("/api/payments/yoco/webhook"' not in text:
    marker = 'app.use("/api/payments", paymentRoutes);'
    text = text.replace(
        marker,
        '''app.get("/api/payments/yoco/webhook", (req, res) => {
  res.json({
    success: true,
    message: "Yoco webhook endpoint is live. Browser GET is only for testing.",
    webhookUrl: "https://api.rezaholdings.co.za/api/payments/yoco/webhook"
  });
});

''' + marker
    )

p.write_text(text)
print("server.js mounted /api/payments.")
PY

# ======================================================
# 3. Patch current V11 checkout in frontend/js/app.js
# ======================================================
python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/js/app.js")
text = p.read_text()

new_checkout = '''async function checkout(e){
  e.preventDefault();

  let c = cart();
  if(!c.length) return toast("Cart is empty");

  let customer = Object.fromEntries(new FormData(e.target).entries());
  let total = c.reduce((sum,item)=>sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1), 0);

  const orderId = "REZA-" + new Date().toISOString().slice(0,10).replaceAll("-","") + "-" + Math.floor(1000 + Math.random() * 9000);

  const order = {
    id: orderId,
    orderNumber: orderId,
    customer,
    items: c,
    subtotal: total,
    total,
    paymentMethod: "Yoco",
    paymentStatus: "Pending Payment",
    deliveryStatus: "New Order",
    createdAt: new Date().toISOString()
  };

  try{
    let d = await api("/api/payments/yoco/create-checkout", {
      method:"POST",
      headers:{"Content-Type":"application/json"},
      body:JSON.stringify({ order })
    });

    if(d.success && d.redirectUrl){
      localStorage.setItem("reza_last_order", JSON.stringify(d.order || order));
      location.href = d.redirectUrl;
      return;
    }

    toast(d.message || "Yoco checkout failed");
  }catch(err){
    console.error(err);
    toast("Yoco checkout error");
    alert("Yoco checkout error. Check backend logs / diagnostics.");
  }
}'''

# Replace current checkout function safely
text2 = re.sub(
    r'async function checkout\(e\)\{.*?\}document\.addEventListener\("DOMContentLoaded",boot\);',
    new_checkout + '\ndocument.addEventListener("DOMContentLoaded",boot);',
    text,
    count=1,
    flags=re.S
)

if text2 == text:
    print("Could not replace checkout function automatically. Appending override instead.")
    text += "\n\n" + new_checkout + "\nwindow.checkout = checkout;\n"
else:
    text = text2

p.write_text(text)
print("frontend/js/app.js checkout now uses /api/payments/yoco/create-checkout.")
PY

# ======================================================
# 4. Add payment result pages if missing
# ======================================================
cat > frontend/payment-success.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Payment Successful | Reza Holdings</title>
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <main class="page-hero">
    <div class="container">
      <div class="kicker">Payment Successful</div>
      <h1>Thank you</h1>
      <p class="lead">Your payment was completed. Reza Holdings will contact you shortly.</p>
      <a class="btn primary" href="index.html">Back Home</a>
    </div>
  </main>
  <script>
    ["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"].forEach(k => localStorage.removeItem(k));
  </script>
</body>
</html>
HTML

cat > frontend/payment-cancelled.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Payment Cancelled | Reza Holdings</title>
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <main class="page-hero">
    <div class="container">
      <div class="kicker">Payment Cancelled</div>
      <h1>Payment was cancelled</h1>
      <p class="lead">Your order was created, but payment was not completed.</p>
      <a class="btn primary" href="checkout.html">Back to Checkout</a>
    </div>
  </main>
</body>
</html>
HTML

cat > frontend/payment-failed.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Payment Failed | Reza Holdings</title>
  <link rel="stylesheet" href="css/app.css">
  <link rel="stylesheet" href="reza-style.css">
</head>
<body>
  <main class="page-hero">
    <div class="container">
      <div class="kicker">Payment Failed</div>
      <h1>Payment failed</h1>
      <p class="lead">Please try again or contact Reza Holdings for help.</p>
      <a class="btn primary" href="checkout.html">Try Again</a>
    </div>
  </main>
</body>
</html>
HTML

git add .
git commit -m "Restore Yoco payment checkout routes to V11"
git push

echo "DONE. Redeploy backend and frontend."
