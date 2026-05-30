const API = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";
let orders = [];

function idOf(o){ return o.orderNumber || o.id || ""; }
function payOf(o){
  const s = String(o.paymentStatus || "").toLowerCase();
  if(s.includes("paid")) return "Paid";
  if(s.includes("cancel")) return "Unpaid";
  return "Unpaid";
}
function fulfillOf(o){
  const s = String(o.deliveryStatus || o.status || "").toLowerCase();
  if(s.includes("fulfilled") || s.includes("delivered")) return "Fulfilled";
  return "Unfulfilled";
}
function money(v){ return "ZAR " + Number(v||0).toLocaleString("en-ZA",{minimumFractionDigits:2,maximumFractionDigits:2}); }
function nameOf(o){ return o.customer?.fullName || o.customer?.name || "Customer"; }
function itemCount(o){ return (o.items || []).reduce((s,i)=>s + Number(i.qty || i.quantity || 1),0); }

async function loadOrders(){
  const r = await fetch(API + "/api/orders");
  const d = await r.json();
  orders = d.orders || [];
  render();
}

function render(){
  const q = document.getElementById("search").value.toLowerCase();
  const f = document.getElementById("filter").value;
  const list = orders.filter(o=>{
    const blob = JSON.stringify(o).toLowerCase();
    if(q && !blob.includes(q)) return false;
    if(f && !(payOf(o)===f || fulfillOf(o)===f || String(o.paymentStatus).includes(f))) return false;
    return true;
  });

  document.getElementById("ordersBody").innerHTML = list.map(o=>{
    const id = idOf(o);
    const pay = payOf(o);
    const ful = fulfillOf(o);
    return `
      <tr>
        <td><input type="checkbox"></td>
        <td><a class="orderlink" href="order-details.html?id=${encodeURIComponent(id)}">${id}</a><br><span class="tag new">NEW</span></td>
        <td>${new Date(o.createdAt || Date.now()).toLocaleString()}</td>
        <td>${nameOf(o)}</td>
        <td><span class="tag ${pay.toLowerCase()}">${pay}</span></td>
        <td><span class="tag ${ful.toLowerCase()}">${ful}</span></td>
        <td>${money(o.total || o.subtotal || 0)}</td>
        <td>${itemCount(o)}</td>
        <td><a class="btn" href="order-details.html?id=${encodeURIComponent(id)}">Open</a></td>
      </tr>
    `;
  }).join("") || `<tr><td colspan="9">No orders found.</td></tr>`;
}

function openManual(){ document.getElementById("modal").classList.add("show"); }
function closeManual(){ document.getElementById("modal").classList.remove("show"); }

document.getElementById("search").addEventListener("input", render);
document.getElementById("filter").addEventListener("change", render);

document.getElementById("manualForm").addEventListener("submit", async e=>{
  e.preventDefault();
  let items;
  try{ items = JSON.parse(document.getElementById("mItems").value); }catch{ return alert("Items JSON is wrong"); }

  const customer = {
    name: document.getElementById("mName").value,
    fullName: document.getElementById("mName").value,
    phone: document.getElementById("mPhone").value,
    email: document.getElementById("mEmail").value,
    address: document.getElementById("mAddress").value
  };

  const r = await fetch(API + "/api/orders", {
    method:"POST",
    headers:{"Content-Type":"application/json"},
    body:JSON.stringify({customer,items,total:Number(document.getElementById("mTotal").value||0)})
  });

  const d = await r.json();
  if(!d.success) return alert(d.message || "Failed");
  closeManual();
  await loadOrders();
});

loadOrders();
