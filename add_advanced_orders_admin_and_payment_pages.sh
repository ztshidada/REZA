#!/bin/bash
set -e

echo "Adding advanced orders admin + premium payment pages..."
echo "No products will be reset."

mkdir -p admin/css admin/js frontend

# ======================================================
# 1. Backend order management routes
# ======================================================
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

block = r'''
// ======================================================
// REZA ADVANCED ADMIN ORDER MANAGEMENT
// ======================================================
const REZA_ADMIN_ORDERS_FILE = path.join(DATA_DIR, "orders.json");

function rezaAdminEnsureOrdersFile() {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(REZA_ADMIN_ORDERS_FILE)) {
    fs.writeFileSync(REZA_ADMIN_ORDERS_FILE, JSON.stringify([], null, 2));
  }
}

function rezaAdminReadOrders() {
  try {
    rezaAdminEnsureOrdersFile();
    const data = JSON.parse(fs.readFileSync(REZA_ADMIN_ORDERS_FILE, "utf8"));
    return Array.isArray(data) ? data : [];
  } catch {
    return [];
  }
}

function rezaAdminWriteOrders(orders) {
  rezaAdminEnsureOrdersFile();
  fs.writeFileSync(REZA_ADMIN_ORDERS_FILE, JSON.stringify(orders, null, 2));
}

function rezaAdminFindOrderIndex(orders, id) {
  return orders.findIndex(o =>
    String(o.id || "") === String(id) ||
    String(o.orderNumber || "") === String(id)
  );
}

app.get("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  res.json({ success: true, order: orders[index] });
});

app.patch("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const existing = orders[index];
  const incoming = req.body || {};

  orders[index] = {
    ...existing,
    ...incoming,
    id: existing.id || existing.orderNumber || incoming.id,
    orderNumber: existing.orderNumber || existing.id || incoming.orderNumber,
    customer: {
      ...(existing.customer || {}),
      ...(incoming.customer || {})
    },
    items: Array.isArray(incoming.items) ? incoming.items : existing.items,
    updatedAt: new Date().toISOString()
  };

  rezaAdminWriteOrders(orders);
  res.json({ success: true, message: "Order updated", order: orders[index] });
});

app.put("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const incoming = req.body || {};
  orders[index] = {
    ...incoming,
    id: incoming.id || incoming.orderNumber || req.params.id,
    orderNumber: incoming.orderNumber || incoming.id || req.params.id,
    updatedAt: new Date().toISOString()
  };

  rezaAdminWriteOrders(orders);
  res.json({ success: true, message: "Order replaced", order: orders[index] });
});

app.delete("/api/orders/:id", (req, res) => {
  const orders = rezaAdminReadOrders();
  const index = rezaAdminFindOrderIndex(orders, req.params.id);

  if (index === -1) {
    return res.status(404).json({ success: false, message: "Order not found" });
  }

  const deleted = orders.splice(index, 1)[0];
  rezaAdminWriteOrders(orders);

  res.json({ success: true, message: "Order deleted", order: deleted });
});
// ======================================================
// END REZA ADVANCED ADMIN ORDER MANAGEMENT
// ======================================================
'''

if "REZA ADVANCED ADMIN ORDER MANAGEMENT" not in text:
    marker = 'app.use((req, res) => {'
    if marker in text:
        text = text.replace(marker, block + "\n\n" + marker, 1)
    else:
        text += "\n\n" + block

p.write_text(text)
print("Backend advanced order routes added.")
PY

# ======================================================
# 2. Premium payment pages CSS
# ======================================================
cat > frontend/payment-page.css <<'CSS'
:root{
  --ink:#241812;
  --muted:#6f6258;
  --gold:#d6a33f;
  --gold2:#f5df9c;
  --cream:#fff8ec;
  --paper:#fffdf8;
}
*{box-sizing:border-box}
body{
  margin:0;
  min-height:100vh;
  font-family:Inter,Arial,sans-serif;
  color:var(--ink);
  background:
    radial-gradient(circle at 20% 20%,rgba(245,223,156,.45),transparent 30%),
    radial-gradient(circle at 80% 10%,rgba(255,200,180,.35),transparent 34%),
    linear-gradient(135deg,#fffdf8,#fff3dd);
  display:grid;
  place-items:center;
  padding:24px;
}
.card{
  width:min(920px,100%);
  background:rgba(255,255,255,.76);
  border:1px solid rgba(214,163,63,.22);
  border-radius:36px;
  padding:clamp(26px,5vw,58px);
  box-shadow:0 30px 100px rgba(36,24,18,.14);
  position:relative;
  overflow:hidden;
}
.card:before{
  content:"";
  position:absolute;
  inset:auto -20% -45% auto;
  width:520px;
  height:520px;
  border-radius:50%;
  background:linear-gradient(135deg,rgba(214,163,63,.18),rgba(255,255,255,.05));
}
.logo{
  display:flex;
  align-items:center;
  gap:14px;
  font-weight:900;
  margin-bottom:34px;
}
.mark{
  width:58px;
  height:58px;
  display:grid;
  place-items:center;
  border-radius:18px;
  background:#0d0b08;
  color:var(--gold2);
  font-family:Georgia,serif;
  font-size:32px;
}
.kicker{
  color:#9f741e;
  text-transform:uppercase;
  letter-spacing:.2em;
  font-weight:1000;
  font-size:13px;
}
h1{
  font-family:Georgia,serif;
  font-size:clamp(44px,9vw,92px);
  line-height:.92;
  margin:12px 0 18px;
}
p{
  color:var(--muted);
  font-size:18px;
  line-height:1.7;
  max-width:720px;
}
.order{
  display:inline-flex;
  margin:16px 0;
  padding:12px 18px;
  border-radius:999px;
  background:#fff3d0;
  color:#7a5312;
  font-weight:1000;
}
.actions{
  display:flex;
  flex-wrap:wrap;
  gap:12px;
  margin-top:26px;
}
.btn{
  display:inline-flex;
  align-items:center;
  justify-content:center;
  padding:15px 22px;
  border-radius:999px;
  text-decoration:none;
  font-weight:1000;
}
.primary{background:linear-gradient(135deg,#f3d06a,#c89226);color:#241812}
.dark{background:#241812;color:white}
.ghost{border:1px solid rgba(36,24,18,.18);color:#241812;background:white}
@media(max-width:620px){
  body{padding:14px}
  .card{border-radius:26px}
  .actions{flex-direction:column}
  .btn{width:100%}
}
CSS

# ======================================================
# 3. Premium payment pages
# ======================================================
cat > frontend/payment-success.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Payment Successful | Reza Holdings</title>
  <link rel="stylesheet" href="payment-page.css">
</head>
<body>
  <main class="card">
    <div class="logo"><div class="mark">R</div><div><b>Reza Holdings</b><br><span>Champagne Luxury</span></div></div>
    <div class="kicker">Payment Successful</div>
    <h1>Thank you.</h1>
    <p>Your payment was completed successfully. Reza Holdings has received your order and our team will contact you shortly.</p>
    <div class="order" id="orderNo">Order received</div>
    <div class="actions">
      <a class="btn primary" href="index.html">Back Home</a>
      <a class="btn dark" href="shop.html">Continue Shopping</a>
      <a class="btn ghost" id="wa" href="#">WhatsApp Reza</a>
    </div>
  </main>
  <script>
    const params = new URLSearchParams(location.search);
    const order = params.get("order") || params.get("orderId") || "";
    if(order) document.getElementById("orderNo").textContent = order;
    document.getElementById("wa").href = "https://wa.me/27793773550?text=" + encodeURIComponent("Hi Reza, my payment was successful. Order: " + order);
    ["reza_cart","rezaCart","cart","reza_cart_items","reza_v11_cart"].forEach(k=>localStorage.removeItem(k));
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
  <link rel="stylesheet" href="payment-page.css">
</head>
<body>
  <main class="card">
    <div class="logo"><div class="mark">R</div><div><b>Reza Holdings</b><br><span>Champagne Luxury</span></div></div>
    <div class="kicker">Payment Cancelled</div>
    <h1>No stress.</h1>
    <p>Your order was created, but the Yoco payment was cancelled. You can go back to checkout or contact Reza on WhatsApp for assistance.</p>
    <div class="order" id="orderNo">Payment not completed</div>
    <div class="actions">
      <a class="btn primary" href="checkout.html">Back to Checkout</a>
      <a class="btn dark" id="wa" href="#">WhatsApp Reza</a>
      <a class="btn ghost" href="shop.html">Keep Shopping</a>
    </div>
  </main>
  <script>
    const params = new URLSearchParams(location.search);
    const order = params.get("order") || params.get("orderId") || "";
    if(order) document.getElementById("orderNo").textContent = order;
    document.getElementById("wa").href = "https://wa.me/27793773550?text=" + encodeURIComponent("Hi Reza, I cancelled payment by mistake. Please assist me. Order: " + order);
  </script>
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
  <link rel="stylesheet" href="payment-page.css">
</head>
<body>
  <main class="card">
    <div class="logo"><div class="mark">R</div><div><b>Reza Holdings</b><br><span>Champagne Luxury</span></div></div>
    <div class="kicker">Payment Failed</div>
    <h1>Try again.</h1>
    <p>The payment did not go through. Your order can still be completed. Try again or contact Reza on WhatsApp.</p>
    <div class="order" id="orderNo">Payment failed</div>
    <div class="actions">
      <a class="btn primary" href="checkout.html">Try Again</a>
      <a class="btn dark" id="wa" href="#">WhatsApp Reza</a>
      <a class="btn ghost" href="index.html">Back Home</a>
    </div>
  </main>
  <script>
    const params = new URLSearchParams(location.search);
    const order = params.get("order") || params.get("orderId") || "";
    if(order) document.getElementById("orderNo").textContent = order;
    document.getElementById("wa").href = "https://wa.me/27793773550?text=" + encodeURIComponent("Hi Reza, my payment failed. Please assist me. Order: " + order);
  </script>
</body>
</html>
HTML

cat > frontend/thank-you.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Thank You | Reza Holdings</title>
  <link rel="stylesheet" href="payment-page.css">
</head>
<body>
  <main class="card">
    <div class="logo"><div class="mark">R</div><div><b>Reza Holdings</b><br><span>Champagne Luxury</span></div></div>
    <div class="kicker">Order Received</div>
    <h1>Thank you.</h1>
    <p>Your order has been received. Reza Holdings will contact you shortly with delivery or collection details.</p>
    <div class="order" id="orderNo">Order received</div>
    <div class="actions">
      <a class="btn primary" href="index.html">Back Home</a>
      <a class="btn dark" id="wa" href="#">WhatsApp Reza</a>
      <a class="btn ghost" href="shop.html">Continue Shopping</a>
    </div>
  </main>
  <script>
    const params = new URLSearchParams(location.search);
    const order = params.get("order") || params.get("orderId") || "";
    if(order) document.getElementById("orderNo").textContent = order;
    document.getElementById("wa").href = "https://wa.me/27793773550?text=" + encodeURIComponent("Hi Reza, I placed an order. Order: " + order);
  </script>
</body>
</html>
HTML

# ======================================================
# 4. Advanced admin CSS
# ======================================================
cat > admin/css/advanced-orders.css <<'CSS'
:root{
  --ink:#241812;
  --muted:#6f6258;
  --gold:#d6a33f;
  --gold2:#f6df9b;
  --cream:#fff8ec;
  --line:rgba(36,24,18,.12);
  --card:rgba(255,255,255,.78);
}
*{box-sizing:border-box}
body{
  margin:0;
  font-family:Inter,Arial,sans-serif;
  background:
    radial-gradient(circle at 80% 10%,rgba(255,200,180,.35),transparent 30%),
    linear-gradient(135deg,#fffdf8,#fff2db);
  color:var(--ink);
}
.admin-shell{display:grid;grid-template-columns:290px 1fr;min-height:100vh}
.sidebar{
  padding:32px 24px;
  border-right:1px solid var(--line);
  background:rgba(255,255,255,.42);
  position:sticky;
  top:0;
  height:100vh;
}
.brand{display:flex;align-items:center;gap:14px;margin-bottom:34px}
.logo{
  width:58px;height:58px;border-radius:18px;background:#111;color:var(--gold2);
  display:grid;place-items:center;font-family:Georgia,serif;font-size:32px;
}
.brand h2{margin:0;font-family:Georgia,serif;font-size:30px}
.brand span{color:#9f741e;font-weight:900;font-size:12px;letter-spacing:.18em}
.nav a{
  display:flex;align-items:center;gap:10px;
  padding:15px 18px;margin:8px 0;border-radius:999px;
  color:var(--ink);text-decoration:none;font-weight:900;
}
.nav a.active,.nav a:hover{background:#241812;color:white}
.main{padding:34px}
.top{
  display:flex;justify-content:space-between;gap:18px;align-items:center;margin-bottom:24px
}
.kicker{color:#9f741e;text-transform:uppercase;letter-spacing:.2em;font-weight:1000;font-size:12px}
h1{font-family:Georgia,serif;font-size:clamp(48px,7vw,92px);line-height:.9;margin:8px 0}
.btn{
  border:0;border-radius:999px;padding:14px 18px;font-weight:1000;cursor:pointer;text-decoration:none;
  display:inline-flex;align-items:center;justify-content:center;gap:8px
}
.btn.primary{background:linear-gradient(135deg,#f3d06a,#c89226);color:#241812}
.btn.dark{background:#241812;color:white}
.btn.ghost{background:white;border:1px solid var(--line);color:#241812}
.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px;margin:20px 0}
.metric{
  background:var(--card);border:1px solid var(--line);border-radius:26px;padding:22px;
  box-shadow:0 18px 50px rgba(36,24,18,.06)
}
.metric span{color:var(--muted);font-weight:800}
.metric strong{display:block;font-family:Georgia,serif;font-size:42px;margin-top:8px}
.panel{
  background:var(--card);border:1px solid var(--line);border-radius:30px;padding:20px;
  box-shadow:0 18px 50px rgba(36,24,18,.08)
}
.tools{display:grid;grid-template-columns:1.4fr 1fr 1fr auto;gap:10px;margin-bottom:16px}
input,select,textarea{
  width:100%;border:1px solid var(--line);border-radius:18px;padding:14px 16px;background:white;
  font:inherit;outline:none
}
textarea{min-height:110px}
.table-wrap{overflow:auto}
table{width:100%;border-collapse:collapse;min-width:1100px}
th,td{padding:14px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}
th{font-size:12px;text-transform:uppercase;letter-spacing:.12em;color:#8b6a28}
.badge{display:inline-flex;padding:7px 10px;border-radius:999px;font-weight:1000;font-size:12px;background:#fff3d0;color:#7a5312}
.badge.paid{background:#dcfce7;color:#166534}
.badge.pending{background:#fef3c7;color:#92400e}
.badge.cancelled,.badge.failed{background:#fee2e2;color:#991b1b}
.row-actions{display:flex;gap:8px;flex-wrap:wrap}
.icon-btn{border:0;border-radius:999px;padding:9px 12px;font-weight:900;cursor:pointer;background:#fff;border:1px solid var(--line)}
.modal{
  position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;place-items:center;padding:20px;z-index:999
}
.modal.show{display:grid}
.dialog{
  width:min(920px,100%);max-height:92vh;overflow:auto;background:#fffdf8;border-radius:30px;padding:24px;
  box-shadow:0 30px 100px rgba(0,0,0,.25)
}
.form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.full{grid-column:1/-1}
.dialog-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px}
.close{border:0;background:#241812;color:#fff;border-radius:50%;width:40px;height:40px;font-size:22px}
@media(max-width:900px){
  .admin-shell{grid-template-columns:1fr}
  .sidebar{position:relative;height:auto}
  .cards{grid-template-columns:repeat(2,minmax(0,1fr))}
  .tools{grid-template-columns:1fr}
  .form-grid{grid-template-columns:1fr}
}
@media(max-width:560px){
  .main{padding:20px}
  .cards{grid-template-columns:1fr}
}
CSS

# ======================================================
# 5. Advanced admin orders JS
# ======================================================
cat > admin/js/advanced-orders.js <<'JS'
const API_BASE = localStorage.getItem("REZA_API_BASE") || (
  location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za"
);

let allOrders = [];
let editingId = null;

const $ = (s) => document.querySelector(s);

function money(v){
  return "R " + Number(v || 0).toLocaleString("en-ZA", { maximumFractionDigits: 2 });
}

function orderId(o){
  return o.orderNumber || o.id || "";
}

function customerName(o){
  return o.customer?.fullName || o.customer?.name || o.customer?.customerName || "Customer";
}

function customerPhone(o){
  return o.customer?.phone || o.customer?.whatsapp || o.phone || "";
}

function customerAddress(o){
  return o.customer?.address || o.customer?.deliveryAddress || o.address || "";
}

function itemsText(o){
  const items = Array.isArray(o.items) ? o.items : [];
  if(!items.length) return "No items";
  return items.map(i => `${Number(i.qty || i.quantity || 1)} x ${i.name || "Product"}`).join(", ");
}

function badgeClass(status){
  const s = String(status || "").toLowerCase();
  if(s.includes("paid")) return "paid";
  if(s.includes("cancel")) return "cancelled";
  if(s.includes("fail")) return "failed";
  return "pending";
}

async function api(path, options = {}){
  const res = await fetch(API_BASE + path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    }
  });

  const data = await res.json().catch(() => ({}));
  if(!res.ok) throw new Error(data.message || "API error");
  return data;
}

async function loadOrders(){
  const data = await api("/api/orders");
  allOrders = data.orders || [];
  render();
}

function renderMetrics(list){
  const paid = list.filter(o => String(o.paymentStatus || "").toLowerCase().includes("paid"));
  const pending = list.filter(o => !String(o.paymentStatus || "").toLowerCase().includes("paid"));
  const revenue = paid.reduce((s,o)=>s + Number(o.total || 0), 0);

  $("#mTotal").textContent = list.length;
  $("#mPaid").textContent = paid.length;
  $("#mPending").textContent = pending.length;
  $("#mRevenue").textContent = money(revenue);
}

function filteredOrders(){
  const q = $("#search").value.toLowerCase().trim();
  const pay = $("#paymentFilter").value;
  const delivery = $("#deliveryFilter").value;

  return allOrders.filter(o => {
    const blob = JSON.stringify(o).toLowerCase();
    if(q && !blob.includes(q)) return false;
    if(pay && String(o.paymentStatus || "") !== pay) return false;
    if(delivery && String(o.deliveryStatus || o.status || "") !== delivery) return false;
    return true;
  });
}

function render(){
  const list = filteredOrders();
  renderMetrics(list);

  $("#ordersBody").innerHTML = list.map(o => {
    const id = orderId(o);
    const pay = o.paymentStatus || "Pending";
    const del = o.deliveryStatus || o.status || "New Order";
    const phone = customerPhone(o);
    const wa = phone ? `https://wa.me/${String(phone).replace(/[^0-9]/g,"")}?text=${encodeURIComponent("Hi, regarding your Reza order " + id)}` : "#";

    return `
      <tr>
        <td><b>${id}</b><br><small>${new Date(o.createdAt || Date.now()).toLocaleString()}</small></td>
        <td><b>${customerName(o)}</b><br>${phone}<br><small>${customerAddress(o)}</small></td>
        <td>${itemsText(o)}</td>
        <td><b>${money(o.total || o.subtotal || 0)}</b></td>
        <td><span class="badge ${badgeClass(pay)}">${pay}</span></td>
        <td><span class="badge">${del}</span></td>
        <td class="row-actions">
          <button class="icon-btn" onclick='openEdit(${JSON.stringify(id)})'>Edit</button>
          <a class="icon-btn" href="${wa}" target="_blank">WhatsApp</a>
          <button class="icon-btn" onclick='markPaid(${JSON.stringify(id)})'>Paid</button>
          <button class="icon-btn" onclick='deleteOrder(${JSON.stringify(id)})'>Delete</button>
        </td>
      </tr>
    `;
  }).join("") || `<tr><td colspan="7">No orders found.</td></tr>`;
}

function openAdd(){
  editingId = null;
  $("#modalTitle").textContent = "Add Manual Order";
  $("#orderForm").reset();
  $("#orderId").value = "REZA-MANUAL-" + Date.now();
  $("#paymentStatus").value = "Pending Payment";
  $("#deliveryStatus").value = "New Order";
  $("#itemsJson").value = JSON.stringify([{ name:"Product", price:0, qty:1 }], null, 2);
  $(".modal").classList.add("show");
}

function openEdit(id){
  const o = allOrders.find(x => orderId(x) === id);
  if(!o) return alert("Order not found");

  editingId = id;
  $("#modalTitle").textContent = "Edit Order";
  $("#orderId").value = orderId(o);
  $("#customerName").value = customerName(o);
  $("#customerPhone").value = customerPhone(o);
  $("#customerEmail").value = o.customer?.email || "";
  $("#customerAddress").value = customerAddress(o);
  $("#paymentStatus").value = o.paymentStatus || "Pending Payment";
  $("#deliveryStatus").value = o.deliveryStatus || o.status || "New Order";
  $("#total").value = Number(o.total || o.subtotal || 0);
  $("#notes").value = o.notes || o.customer?.notes || "";
  $("#itemsJson").value = JSON.stringify(o.items || [], null, 2);
  $(".modal").classList.add("show");
}

function closeModal(){
  $(".modal").classList.remove("show");
}

async function saveOrder(e){
  e.preventDefault();

  let items = [];
  try{
    items = JSON.parse($("#itemsJson").value || "[]");
    if(!Array.isArray(items)) throw new Error("Items must be an array");
  }catch(err){
    return alert("Items JSON is not valid.");
  }

  const id = $("#orderId").value.trim() || editingId || ("REZA-MANUAL-" + Date.now());
  const order = {
    id,
    orderNumber: id,
    customer: {
      name: $("#customerName").value,
      fullName: $("#customerName").value,
      phone: $("#customerPhone").value,
      email: $("#customerEmail").value,
      address: $("#customerAddress").value,
      notes: $("#notes").value
    },
    items,
    total: Number($("#total").value || 0),
    subtotal: Number($("#total").value || 0),
    paymentStatus: $("#paymentStatus").value,
    deliveryStatus: $("#deliveryStatus").value,
    status: $("#deliveryStatus").value,
    notes: $("#notes").value
  };

  if(editingId){
    await api("/api/orders/" + encodeURIComponent(editingId), {
      method:"PATCH",
      body:JSON.stringify(order)
    });
  } else {
    const created = await api("/api/orders", {
      method:"POST",
      body:JSON.stringify({
        customer: order.customer,
        items: order.items
      })
    });

    const createdId = created.order?.orderNumber || created.order?.id;
    await api("/api/orders/" + encodeURIComponent(createdId), {
      method:"PATCH",
      body:JSON.stringify(order)
    });
  }

  closeModal();
  await loadOrders();
}

async function markPaid(id){
  if(!confirm("Mark this order as paid?")) return;
  await api("/api/orders/" + encodeURIComponent(id), {
    method:"PATCH",
    body:JSON.stringify({ paymentStatus:"Paid", status:"Paid" })
  });
  await loadOrders();
}

async function deleteOrder(id){
  if(!confirm("Delete this order?")) return;
  await api("/api/orders/" + encodeURIComponent(id), { method:"DELETE" });
  await loadOrders();
}

$("#search").addEventListener("input", render);
$("#paymentFilter").addEventListener("change", render);
$("#deliveryFilter").addEventListener("change", render);
$("#refreshBtn").addEventListener("click", loadOrders);
$("#addBtn").addEventListener("click", openAdd);
$("#closeBtn").addEventListener("click", closeModal);
$("#orderForm").addEventListener("submit", saveOrder);

loadOrders().catch(err => {
  console.error(err);
  alert("Could not load orders: " + err.message);
});
JS

# ======================================================
# 6. Advanced admin orders page
# ======================================================
cat > admin/orders.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Orders | Reza Admin</title>
  <link rel="stylesheet" href="css/advanced-orders.css">
</head>
<body>
  <div class="admin-shell">
    <aside class="sidebar">
      <div class="brand">
        <div class="logo">R</div>
        <div>
          <h2>Reza Admin</h2>
          <span>CHAMPAGNE LUXURY</span>
        </div>
      </div>

      <nav class="nav">
        <a href="dashboard.html">Dashboard</a>
        <a href="products.html">Products</a>
        <a href="media.html">Media</a>
        <a class="active" href="orders.html">Orders</a>
        <a href="advanced.html">Advanced</a>
        <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
        <a href="login.html">Logout</a>
      </nav>
    </aside>

    <main class="main">
      <div class="top">
        <div>
          <div class="kicker">Reza Holdings</div>
          <h1>Orders</h1>
        </div>
        <button class="btn primary" id="addBtn">+ Add Manual Order</button>
      </div>

      <section class="cards">
        <div class="metric"><span>Total Orders</span><strong id="mTotal">0</strong></div>
        <div class="metric"><span>Paid</span><strong id="mPaid">0</strong></div>
        <div class="metric"><span>Pending</span><strong id="mPending">0</strong></div>
        <div class="metric"><span>Paid Revenue</span><strong id="mRevenue">R 0</strong></div>
      </section>

      <section class="panel">
        <div class="tools">
          <input id="search" placeholder="Search order, customer, phone, product, address...">
          <select id="paymentFilter">
            <option value="">All payment statuses</option>
            <option>Paid</option>
            <option>Pending Payment</option>
            <option>Pending</option>
            <option>Payment Cancelled</option>
            <option>Payment Failed</option>
          </select>
          <select id="deliveryFilter">
            <option value="">All delivery statuses</option>
            <option>New Order</option>
            <option>Processing</option>
            <option>Ready for Collection</option>
            <option>Out for Delivery</option>
            <option>Delivered</option>
            <option>Cancelled</option>
          </select>
          <button class="btn dark" id="refreshBtn">Refresh</button>
        </div>

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Order</th>
                <th>Customer / Address</th>
                <th>Items</th>
                <th>Total</th>
                <th>Payment</th>
                <th>Delivery</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody id="ordersBody"></tbody>
          </table>
        </div>
      </section>
    </main>
  </div>

  <div class="modal">
    <div class="dialog">
      <div class="dialog-head">
        <h2 id="modalTitle">Edit Order</h2>
        <button class="close" id="closeBtn" type="button">×</button>
      </div>

      <form id="orderForm">
        <div class="form-grid">
          <input id="orderId" placeholder="Order number">
          <input id="total" type="number" step="0.01" placeholder="Total amount">

          <input id="customerName" placeholder="Customer name">
          <input id="customerPhone" placeholder="Customer phone / WhatsApp">

          <input id="customerEmail" placeholder="Customer email">
          <input id="customerAddress" placeholder="Delivery / collection address">

          <select id="paymentStatus">
            <option>Pending Payment</option>
            <option>Pending</option>
            <option>Paid</option>
            <option>Payment Cancelled</option>
            <option>Payment Failed</option>
            <option>Refunded</option>
          </select>

          <select id="deliveryStatus">
            <option>New Order</option>
            <option>Processing</option>
            <option>Ready for Collection</option>
            <option>Out for Delivery</option>
            <option>Delivered</option>
            <option>Cancelled</option>
          </select>

          <textarea id="itemsJson" class="full" placeholder='Items JSON e.g. [{"name":"Product","price":200,"qty":1}]'></textarea>
          <textarea id="notes" class="full" placeholder="Order notes"></textarea>
        </div>

        <br>
        <button class="btn primary" type="submit">Save Order</button>
      </form>
    </div>
  </div>

  <script src="js/advanced-orders.js"></script>
</body>
</html>
HTML

# ======================================================
# 7. Small advanced admin landing page
# ======================================================
cat > admin/advanced.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Advanced Admin | Reza</title>
  <link rel="stylesheet" href="css/advanced-orders.css">
</head>
<body>
  <div class="admin-shell">
    <aside class="sidebar">
      <div class="brand">
        <div class="logo">R</div>
        <div>
          <h2>Reza Admin</h2>
          <span>ADVANCED</span>
        </div>
      </div>
      <nav class="nav">
        <a href="dashboard.html">Dashboard</a>
        <a href="products.html">Products</a>
        <a href="media.html">Media</a>
        <a href="orders.html">Orders</a>
        <a class="active" href="advanced.html">Advanced</a>
        <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
      </nav>
    </aside>
    <main class="main">
      <div class="kicker">Control Center</div>
      <h1>Advanced Admin</h1>
      <section class="cards">
        <a class="metric" href="orders.html" style="text-decoration:none;color:inherit"><span>Manage</span><strong>Orders</strong></a>
        <a class="metric" href="products.html" style="text-decoration:none;color:inherit"><span>Manage</span><strong>Products</strong></a>
        <a class="metric" href="media.html" style="text-decoration:none;color:inherit"><span>Manage</span><strong>Media</strong></a>
        <a class="metric" href="dashboard.html" style="text-decoration:none;color:inherit"><span>View</span><strong>Dashboard</strong></a>
      </section>
    </main>
  </div>
</body>
</html>
HTML

# ======================================================
# 8. Commit and push
# ======================================================
git add .
git commit -m "Add premium payment pages and advanced order admin"
git push

echo "DONE. Redeploy backend, frontend and admin."
