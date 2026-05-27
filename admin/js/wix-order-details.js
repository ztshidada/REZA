const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
const id = new URLSearchParams(location.search).get("id");
let order = null;

function orderId(){ return order.orderNumber || order.id || id; }
function money(v){ return "R " + Number(v||0).toLocaleString("en-ZA",{minimumFractionDigits:2,maximumFractionDigits:2}); }
function customer(){ return order.customer || {}; }
function imgOf(i){ return i.image || i.imageUrl || i.photo || "assets/images/reza-card-bg.svg"; }
function payStatus(){
  const s = String(order.paymentStatus || "").toLowerCase();
  return s.includes("paid") ? "Paid" : "Unpaid";
}
function fulfillStatus(){
  const s = String(order.deliveryStatus || order.status || "").toLowerCase();
  return (s.includes("fulfilled") || s.includes("delivered")) ? "Fulfilled" : "Unfulfilled";
}

async function api(path, method="GET", body=null){
  const r = await fetch(API + path, {method,headers:{"Content-Type":"application/json"},body:body?JSON.stringify(body):null});
  const d = await r.json().catch(()=>({}));
  if(!r.ok) throw new Error(d.message || "API error");
  return d;
}

async function load(){
  const d = await api("/api/orders/" + encodeURIComponent(id));
  order = d.order;
  render();
}

function render(){
  const oid = orderId();
  const c = customer();
  const items = order.items || [];
  const payment = payStatus();
  const fulfil = fulfillStatus();

  document.getElementById("title").textContent = "Order " + oid;
  document.getElementById("placed").textContent = "Placed on " + new Date(order.createdAt || Date.now()).toLocaleString();
  document.getElementById("paymentTag").textContent = payment.toUpperCase();
  document.getElementById("paymentTag").className = "tag " + payment.toLowerCase();
  document.getElementById("fulfillTag").textContent = fulfil.toUpperCase();
  document.getElementById("fulfillTag").className = "tag " + fulfil.toLowerCase();
  document.getElementById("itemsTitle").textContent = `Items (${items.length})`;

  document.getElementById("items").innerHTML = items.map(i=>{
    const qty = Number(i.qty || i.quantity || 1);
    const price = Number(i.price || 0);
    return `
      <div class="item">
        <img src="${imgOf(i)}" onerror="this.src='assets/images/reza-card-bg.svg'">
        <div><b>${i.name || "Product"}</b><br><span style="color:#64748b">SKU: ${i.sku || i.id || "-"}</span></div>
        <div style="text-align:right">${money(price)} × ${qty}<br><b>${money(price*qty)}</b></div>
      </div>
    `;
  }).join("");

  const subtotal = Number(order.subtotal || order.total || 0);
  const delivery = Number(order.shipping || order.delivery || 0);
  const total = Number(order.total || subtotal + delivery);

  document.getElementById("paymentInfo").innerHTML = `
    <div class="row"><span>Items</span><b>${money(subtotal)}</b></div>
    <div class="row"><span>Shipping</span><b>${money(delivery)}</b></div>
    <div class="row"><span>Tax</span><b>R 0.00</b></div>
    <div class="row" style="border-top:1px solid #dfe5ee;margin-top:8px;padding-top:16px"><b>Total</b><b>${money(total)}</b></div>
    <div class="row"><b>Amount due</b><b>${payment==="Paid" ? "R 0.00" : money(total)}</b></div>
  `;

  const phone = c.phone || c.whatsapp || "";
  const wa = "https://wa.me/" + String(phone).replace(/[^0-9]/g,"") + "?text=" + encodeURIComponent("Hi, regarding your Reza order " + oid);

  document.getElementById("customerInfo").innerHTML = `
    <b>Contact info</b><br>
    ${c.name || c.fullName || "Customer"}<br>
    ${c.email || ""}<br>
    ${phone ? `<a href="${wa}" target="_blank">${phone}</a>` : ""}<br><br>
    <b>Shipping address</b><br>
    ${c.address || c.deliveryAddress || order.address || "No address"}<br><br>
    <b>Billing address</b><br>
    Same as shipping
  `;

  document.getElementById("extraInfo").innerHTML = `
    <b>Payment method:</b> ${order.paymentMethod || "Yoco"}<br>
    <b>Yoco checkout:</b> ${order.yocoCheckoutId || "-"}<br>
    <b>Notes:</b><br>${order.notes || c.notes || "No notes"}
  `;
}

async function markPaid(){
  await api("/api/orders/" + encodeURIComponent(orderId()), "PATCH", {paymentStatus:"Paid",status:"Paid"});
  await load();
}
async function markFulfilled(){
  await api("/api/orders/" + encodeURIComponent(orderId()), "PATCH", {deliveryStatus:"Fulfilled",status:"Fulfilled"});
  await load();
}
async function cancelOrder(){
  if(!confirm("Cancel this order?")) return;
  await api("/api/orders/" + encodeURIComponent(orderId()), "PATCH", {deliveryStatus:"Cancelled",status:"Cancelled",paymentStatus:order.paymentStatus || "Unpaid"});
  await load();
}
function openEdit(){
  const c = customer();
  document.getElementById("eName").value = c.name || c.fullName || "";
  document.getElementById("ePhone").value = c.phone || "";
  document.getElementById("eEmail").value = c.email || "";
  document.getElementById("eAddress").value = c.address || c.deliveryAddress || "";
  document.getElementById("eTotal").value = order.total || order.subtotal || 0;
  document.getElementById("ePayment").value = order.paymentStatus || "Unpaid";
  document.getElementById("eFulfillment").value = order.deliveryStatus || order.status || "Unfulfilled";
  document.getElementById("eItems").value = JSON.stringify(order.items || [], null, 2);
  document.getElementById("editModal").classList.add("show");
}
function closeEdit(){ document.getElementById("editModal").classList.remove("show"); }

document.getElementById("editForm").addEventListener("submit", async e=>{
  e.preventDefault();
  let items;
  try{ items = JSON.parse(document.getElementById("eItems").value); }catch{ return alert("Items JSON is wrong"); }
  await api("/api/orders/" + encodeURIComponent(orderId()), "PATCH", {
    customer:{
      name:document.getElementById("eName").value,
      fullName:document.getElementById("eName").value,
      phone:document.getElementById("ePhone").value,
      email:document.getElementById("eEmail").value,
      address:document.getElementById("eAddress").value
    },
    total:Number(document.getElementById("eTotal").value||0),
    subtotal:Number(document.getElementById("eTotal").value||0),
    paymentStatus:document.getElementById("ePayment").value,
    deliveryStatus:document.getElementById("eFulfillment").value,
    status:document.getElementById("eFulfillment").value,
    items
  });
  closeEdit();
  await load();
});

load().catch(err=>alert(err.message));
