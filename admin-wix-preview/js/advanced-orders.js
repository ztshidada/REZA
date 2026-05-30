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
