const API = location.hostname.includes("localhost")
  ? "http://localhost:10000"
  : "https://api.rezaholdings.co.za";

const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];

function toggleMenu(){
  const nav = document.getElementById("mainNav");
  if(nav) nav.classList.toggle("open");
}

function img(src){
  if(!src) return "assets/images/reza-card-bg.svg";
  if(src.startsWith("data:image")) return src;
  if(src.startsWith("http")) return src;
  if(src.startsWith("/")) return API + src;
  return src;
}

function money(value){
  const n = Number(value || 0);
  if(!n) return "Price coming soon";
  return "R " + n.toLocaleString("en-ZA", { maximumFractionDigits: 0 });
}

function readCart(){
  for(const key of CART_KEYS){
    try{
      const data = JSON.parse(localStorage.getItem(key) || "[]");
      if(Array.isArray(data) && data.length) return data;
    }catch(e){}
  }
  return [];
}

function saveCart(cart){
  CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));
  updateCartCount();
}

function updateCartCount(){
  const cart = readCart();
  const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);

  document.querySelectorAll("#cartCount,[data-count],[data-cart-count],.cart-count,.cart-badge,.bag-count").forEach(el => {
    el.textContent = count;
  });

  document.body.setAttribute("data-cart-count", count);
}

function toast(message){
  let el = document.querySelector(".reza-toast");
  if(!el){
    el = document.createElement("div");
    el.className = "reza-toast";
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.classList.add("show");
  setTimeout(() => el.classList.remove("show"), 1800);
}

async function apiGet(path){
  const res = await fetch(API + path, { cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API error");
  return data;
}

async function apiPost(path, body){
  const res = await fetch(API + path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const data = await res.json().catch(() => ({}));
  if(!res.ok || data.success === false) throw new Error(data.message || "API error");
  return data;
}

async function getProducts(){
  const data = await apiGet("/api/products?t=" + Date.now());
  return Array.isArray(data.products) ? data.products : [];
}

function isComingSoon(p){
  return p.status === "comingSoon" ||
         p.status === "coming-soon" ||
         p.category === "Coming Soon" ||
         p.productType === "Coming Soon" ||
         p.comingSoon === true;
}

function isSaleProduct(p){
  return p.showOnline !== false && !isComingSoon(p);
}

function productCard(p, mode="sale"){
  const coming = mode === "coming";
  const payload = JSON.stringify(p).replace(/'/g, "&apos;");

  return `
    <article class="reza-product-card">
      <div class="reza-product-image">
        <span>${coming ? "Coming Soon" : (p.badge || p.productType || "Product")}</span>
        <img src="${img(p.image)}" alt="${p.name || "Reza product"}" loading="lazy">
      </div>
      <div class="reza-product-body">
        <p class="reza-product-type">${p.category || "Reza Holdings"}</p>
        <h3>${p.name || "Reza Product"}</h3>
        <p class="reza-product-price">${coming ? "Coming Soon" : money(p.price)}</p>
        <p>${p.description || ""}</p>
        ${
          coming
            ? `<button type="button" class="muted">Coming Soon</button>`
            : `<button type="button" onclick='addToCart(${payload})'>Add to Bag</button>`
        }
      </div>
    </article>
  `;
}

function addToCart(product){
  const cart = readCart();
  const id = product.id || product.name;
  const found = cart.find(item => String(item.id || item.name) === String(id));

  if(found){
    found.qty = Number(found.qty || found.quantity || 1) + 1;
    found.quantity = found.qty;
  } else {
    cart.push({
      id,
      name: product.name || "Reza Product",
      price: Number(product.price || 0),
      image: product.image || "",
      category: product.category || "",
      productType: product.productType || "",
      qty: 1,
      quantity: 1
    });
  }

  saveCart(cart);
  toast("Added to bag");
}

window.addToCart = addToCart;
window.toggleMenu = toggleMenu;

async function renderShop(){
  const grid = document.querySelector("[data-products-grid]");
  if(!grid) return;

  const search = document.querySelector("[data-search]");
  const category = document.querySelector("[data-category]");
  const all = await getProducts();
  const sale = all.filter(isSaleProduct);

  if(category){
    const cats = ["All", ...new Set(sale.map(p => p.category).filter(Boolean))];
    category.innerHTML = cats.map(c => `<option>${c}</option>`).join("");
  }

  function draw(){
    const q = (search?.value || "").toLowerCase();
    const c = category?.value || "All";

    const list = sale.filter(p => {
      const text = `${p.name || ""} ${p.category || ""} ${p.description || ""}`.toLowerCase();
      return (c === "All" || p.category === c) && text.includes(q);
    });

    grid.innerHTML = list.length
      ? list.map(p => productCard(p, "sale")).join("")
      : `<div class="reza-empty">No products found.</div>`;
  }

  if(search) search.oninput = draw;
  if(category) category.onchange = draw;
  draw();
}

async function renderFeatured(){
  const grid = document.querySelector("[data-featured-products]");
  if(!grid) return;

  const all = await getProducts();
  const sale = all.filter(isSaleProduct);
  const selected = sale.filter(p => p.showFeatured === true).slice(0, 3);
  const finalList = selected.length ? selected : sale.slice(0, 3);

  grid.innerHTML = finalList.length
    ? finalList.map(p => productCard(p, "sale")).join("")
    : `<div class="reza-empty">No featured products selected yet.</div>`;
}

async function renderComingSoon(){
  const grid = document.querySelector("[data-coming-soon-products]");
  if(!grid) return;

  const all = await getProducts();
  const coming = all.filter(isComingSoon);

  grid.innerHTML = coming.length
    ? coming.map(p => productCard(p, "coming")).join("")
    : `<div class="reza-empty">No coming soon products yet.</div>`;
}

async function renderProductDetail(){
  const box = document.querySelector("[data-product-detail]");
  if(!box) return;

  const id = new URLSearchParams(location.search).get("id");
  const products = await getProducts();
  const p = products.find(x => String(x.id) === String(id));

  if(!p){
    box.innerHTML = `<div class="reza-empty">Product not found.</div>`;
    return;
  }

  box.innerHTML = `
    <section class="reza-detail">
      <div class="reza-detail-image">
        <img src="${img(p.image)}" alt="${p.name}">
      </div>
      <div class="reza-detail-info">
        <p class="eyebrow">${p.category || "Reza Holdings"}</p>
        <h1>${p.name}</h1>
        <p>${p.description || ""}</p>
        <h2>${money(p.price)}</h2>
        <button onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Bag</button>
      </div>
    </section>
  `;
}

function renderCart(){
  const box = document.querySelector("[data-cart-items]");
  const summary = document.querySelector("[data-cart-summary]");
  if(!box && !summary) return;

  const cart = readCart();
  const total = cart.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  if(box){
    box.innerHTML = cart.length ? cart.map((item, index) => {
      const qty = Number(item.qty || item.quantity || 1);
      return `
        <article class="reza-cart-item">
          <img src="${img(item.image)}" alt="${item.name}">
          <div>
            <h3>${item.name}</h3>
            <p>${money(item.price)}</p>
          </div>
          <div class="reza-qty">
            <button onclick="changeQty(${index}, -1)">−</button>
            <strong>${qty}</strong>
            <button onclick="changeQty(${index}, 1)">+</button>
          </div>
          <strong>${money(Number(item.price || 0) * qty)}</strong>
          <button class="remove" onclick="removeCartItem(${index})">Remove</button>
        </article>
      `;
    }).join("") : `
      <div class="reza-cart-empty">
        <h1>Your cart is empty</h1>
        <p>Add products before checkout.</p>
        <a href="shop.html">Shop Products</a>
      </div>
    `;
  }

  if(summary){
    summary.innerHTML = `
      <h2>Summary</h2>
      <div><span>Subtotal</span><strong>${money(total)}</strong></div>
      <div><span>Delivery</span><strong>Calculated after order</strong></div>
      <hr>
      <div class="total"><span>Total</span><strong>${money(total)}</strong></div>
      <a href="checkout.html">Checkout</a>
    `;
  }

  updateCartCount();
}

function changeQty(index, amount){
  const cart = readCart();
  if(!cart[index]) return;
  cart[index].qty = Math.max(1, Number(cart[index].qty || cart[index].quantity || 1) + amount);
  cart[index].quantity = cart[index].qty;
  saveCart(cart);
  renderCart();
}

function removeCartItem(index){
  const cart = readCart();
  cart.splice(index, 1);
  saveCart(cart);
  renderCart();
}

window.changeQty = changeQty;
window.removeCartItem = removeCartItem;

function renderCheckout(){
  const page = document.querySelector("[data-checkout-page]");
  if(!page) return;

  const cart = readCart();
  const total = cart.reduce((sum, item) => {
    return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
  }, 0);

  page.innerHTML = `
    <section class="page-hero">
      <div class="container">
        <p class="eyebrow">SECURE CHECKOUT</p>
        <h1>Checkout</h1>
        <p>Wix-style checkout. Delivery is calculated after order.</p>
      </div>
    </section>

    <section class="reza-checkout-wrap">
      <form class="reza-checkout-form" onsubmit="placeOrder(event)">
        <h2>Customer Information</h2>
        <input name="name" placeholder="Full name" required>
        <input name="phone" placeholder="Phone / WhatsApp" required>
        <input name="email" type="email" placeholder="Email address">

        <h2>Delivery Details</h2>
        <select name="country">
          <option>South Africa</option>
          <option>Botswana</option>
          <option>Zimbabwe</option>
          <option>Namibia</option>
          <option>Eswatini</option>
        </select>
        <input name="province" placeholder="Province / Region">
        <input name="city" placeholder="City">
        <input name="address" placeholder="Street address / collection details">
        <input name="paxiMall" placeholder="Paxi number / nearest mall">
        <textarea name="notes" placeholder="Order notes"></textarea>

        <button type="submit">Place Order</button>
      </form>

      <aside class="reza-checkout-summary">
        <h2>Order Summary</h2>
        ${
          cart.length ? cart.map(item => {
            const qty = Number(item.qty || item.quantity || 1);
            return `<div class="checkout-line"><span>${qty} × ${item.name}</span><strong>${money(Number(item.price || 0) * qty)}</strong></div>`;
          }).join("") : `<p>No cart items.</p>`
        }
        <hr>
        <div class="checkout-line total"><span>Total</span><strong>${money(total)}</strong></div>
      </aside>
    </section>
  `;
}

async function placeOrder(event){
  event.preventDefault();

  const cart = readCart();
  if(!cart.length){
    toast("Cart is empty");
    return;
  }

  const customer = Object.fromEntries(new FormData(event.target).entries());

  try{
    const data = await apiPost("/api/orders", { customer, items: cart });
    localStorage.removeItem("reza_cart");
    localStorage.removeItem("rezaCart");
    localStorage.removeItem("cart");
    localStorage.removeItem("reza_cart_items");
    localStorage.removeItem("reza_v11_cart");
    updateCartCount();
    alert("Order created: " + data.order.orderNumber);
    location.href = "index.html";
  }catch(error){
    alert("Order failed: " + error.message);
  }
}

window.placeOrder = placeOrder;

async function loadBranding(){
  try{
    const data = await apiGet("/api/media?t=" + Date.now());
    if(data.media && data.media.logoImage){
      document.querySelectorAll(".logo").forEach(el => {
        el.innerHTML = `<img src="${img(data.media.logoImage)}" alt="Reza Logo">`;
      });
    }
    if(data.media && data.media.heroImage){
      const hero = document.querySelector(".hero-shopify");
      if(hero) hero.style.backgroundImage = `linear-gradient(90deg,rgba(255,248,238,.82),rgba(255,248,238,.22)), url("${img(data.media.heroImage)}")`;
    }
  }catch(e){}
}

async function popupOnce(){
  const path = location.pathname.toLowerCase();
  const isHome = path === "/" || path.endsWith("/index.html") || path.endsWith("/index");
  if(!isHome) return;

  const key = "reza_popup_seen_this_visit";
  if(sessionStorage.getItem(key) === "yes") return;

  try{
    const data = await apiGet("/api/popup?t=" + Date.now());
    const p = data.popup || {};
    if(!p.enabled) return;

    sessionStorage.setItem(key, "yes");

    const overlay = document.createElement("div");
    overlay.className = "reza-popup-overlay";
    overlay.innerHTML = `
      <div class="reza-popup-card">
        <button class="reza-popup-close" type="button">×</button>
        ${p.image ? `<img class="reza-popup-img" src="${img(p.image)}" alt="Special">` : ""}
        <p class="reza-popup-kicker">${p.category || "Specials"}</p>
        <h2>${p.title || "Special"}</h2>
        <p>${p.message || ""}</p>
        <a href="${p.buttonLink || "shop.html"}">${p.buttonText || "Shop Now"}</a>
      </div>
    `;
    document.body.appendChild(overlay);

    overlay.querySelector(".reza-popup-close").onclick = () => overlay.remove();
    overlay.onclick = e => {
      if(e.target === overlay) overlay.remove();
    };
  }catch(e){}
}

document.addEventListener("DOMContentLoaded", () => {
  updateCartCount();
  loadBranding();
  renderShop().catch(console.warn);
  renderFeatured().catch(console.warn);
  renderComingSoon().catch(console.warn);
  renderProductDetail().catch(console.warn);
  renderCart();
  renderCheckout();
  setTimeout(popupOnce, 600);
});
