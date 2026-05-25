const API_BASE=localStorage.getItem("REZA_API_BASE")||"http://localhost:10000",DEFAULT_HERO="https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=1900&auto=format&fit=crop";function money(v){return"R "+Number(v||0).toLocaleString("en-ZA",{minimumFractionDigits:2,maximumFractionDigits:2}).replace(".",",")}function img(v){return v||"https://images.unsplash.com/photo-1612817288484-6f916006741a?q=80&w=1200&auto=format&fit=crop"}async function api(p,o={}){let r=await fetch(API_BASE+p,{cache:"no-store",...o});return r.json()}async function products(){try{let d=await api("/api/products");if(d.success)return d.products.filter(p=>p.showOnline!==false)}catch(e){console.warn(e)}return[]}async function media(){try{let d=await api("/api/media");if(d.success)return d.media}catch{}return{heroImage:DEFAULT_HERO}}function cart(){try{return JSON.parse(localStorage.getItem("reza_v11_cart")||"[]")}catch{return[]}}function saveCart(c){localStorage.setItem("reza_v11_cart",JSON.stringify(c));count()}function count(){let n=cart().reduce((s,i)=>s+Number(i.qty||1),0);document.querySelectorAll("[data-count]").forEach(e=>e.textContent=n)}function toast(m){let e=document.querySelector(".toast")||document.body.appendChild(document.createElement("div"));e.className="toast";e.textContent=m;e.classList.add("show");setTimeout(()=>e.classList.remove("show"),1700)}async function addToCart(id){let p=(await products()).find(x=>String(x.id)===String(id));if(!p)return toast("Product not found");let c=cart(),f=c.find(i=>String(i.id)===String(id));if(f)f.qty++;else c.push({id:p.id,name:p.name,price:Number(p.price||0),image:p.image,qty:1});saveCart(c);toast(p.name+" added")}function productCard(p){return`<article class="product"><div class="product-img"><span class="badge">${p.badge||p.category||"Reza"}</span><img src="${img(p.image)}" alt="${p.name}"></div><div class="product-body"><h3>${p.name}</h3><div class="price">${money(p.price)}</div><p>${p.description||""}</p><div class="product-actions"><a class="btn ghost" href="product.html?id=${encodeURIComponent(p.id)}">View</a><button class="btn primary" onclick="addToCart('${p.id}')">Add</button></div></div></article>`}async function boot(){count();let m=await media();document.documentElement.style.setProperty("--hero",`url("${m.heroImage||DEFAULT_HERO}")`);renderHome();renderShop();renderDetail();renderCart();renderCheckout()}async function renderHome(){let el=document.querySelector("[data-featured]");if(!el)return;let ps=(await products()).slice(0,3);el.innerHTML=ps.length?ps.map(productCard).join(""):`<div class="glass empty">No products yet. Add products from admin.</div>`}async function renderShop(){let el=document.querySelector("[data-shop]");if(!el)return;let ps=await products(),search=document.querySelector("[data-search]"),cat=document.querySelector("[data-category]");cat.innerHTML=["All",...new Set(ps.map(p=>p.category).filter(Boolean))].map(c=>`<option>${c}</option>`).join("");function draw(){let q=(search.value||"").toLowerCase(),c=cat.value,list=ps.filter(p=>(c==="All"||p.category===c)&&`${p.name} ${p.category} ${p.description}`.toLowerCase().includes(q));el.innerHTML=list.length?list.map(productCard).join(""):`<div class="glass empty">No products found.</div>`}search.oninput=draw;cat.onchange=draw;draw()}async function renderDetail(){let el=document.querySelector("[data-detail]");if(!el)return;let id=new URLSearchParams(location.search).get("id"),p=(await products()).find(x=>String(x.id)===String(id));if(!p){el.innerHTML=`<div class="glass empty">Product not found.</div>`;return}el.innerHTML=`<div class="hero-grid" style="min-height:auto;padding:36px 0"><div class="hero-card"><div class="hero-card-inner"><img src="${img(p.image)}"></div></div><div><div class="kicker">${p.category||"Product"}</div><h1>${p.name}</h1><p class="lead">${p.description||""}</p><div class="price" style="font-size:2rem">${money(p.price)}</div><div class="glass" style="padding:22px;color:#7e6f61;line-height:1.6"><b>Benefits</b><ul>${(p.benefits||[]).map(b=>`<li>${b}</li>`).join("")||"<li>Premium daily care</li>"}</ul><b>How to use</b><p>${p.howToUse||"Use as directed."}</p></div><br><button class="btn primary" onclick="addToCart('${p.id}')">Add to Cart</button></div></div>`}function renderCart(){let page=document.querySelector("[data-cart-page]");if(!page)return;let c=cart(),list=document.querySelector("[data-cart-list]"),sub=document.querySelector("[data-subtotal]"),tot=document.querySelector("[data-total]"),total=c.reduce((s,i)=>s+Number(i.price)*Number(i.qty),0);list.innerHTML=c.length?c.map(i=>`<div class="cart-item glass"><img src="${img(i.image)}"><div><h3>${i.name}</h3><div class="price">${money(i.price)}</div></div><div class="qty"><button onclick="qty('${i.id}',-1)">−</button><b>${i.qty}</b><button onclick="qty('${i.id}',1)">+</button></div><b class="line">${money(i.price*i.qty)}</b><button class="remove" onclick="removeItem('${i.id}')">Remove</button></div>`).join(""):`<div class="glass empty"><h2>Your cart is empty</h2><p>Add products before checkout.</p><a class="btn primary" href="shop.html">Shop Products</a></div>`;sub.textContent=money(total);tot.textContent=money(total);count()}function qty(id,d){let c=cart(),item=c.find(i=>String(i.id)===String(id));if(!item)return;item.qty+=d;saveCart(c.filter(i=>i.qty>0));renderCart()}function removeItem(id){saveCart(cart().filter(i=>String(i.id)!==String(id)));renderCart()}function renderCheckout(){let el=document.querySelector("[data-summary]");if(!el)return;let c=cart(),total=c.reduce((s,i)=>s+Number(i.price)*Number(i.qty),0);el.innerHTML=(c.map(i=>`<div class="row"><span>${i.qty} × ${i.name}</span><strong>${money(i.price*i.qty)}</strong></div>`).join("")||"<p>No cart items.</p>")+`<div class="row total"><span>Total</span><strong>${money(total)}</strong></div>`}async function checkout(e){e.preventDefault();let c=cart();if(!c.length)return toast("Cart is empty");let customer=Object.fromEntries(new FormData(e.target).entries());try{let d=await api("/api/orders",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({customer,items:c})});if(d.success){localStorage.removeItem("reza_v11_cart");alert("Order created: "+d.order.orderNumber);location.href="index.html"}else toast("Order failed")}catch(err){toast("API error")}}document.addEventListener("DOMContentLoaded",boot);

// ================================
// REZA V11.1 — ALIVE MOTION
// ================================
(function(){
  function rotateHeroWords(){
    const h1 = document.querySelector(".hero h1");
    if(!h1 || h1.dataset.aliveReady) return;

    h1.dataset.aliveReady = "1";
    h1.innerHTML = '<span class="alive-word" data-alive-word>Glow.</span><br><span>Bloom.</span><br><span>Become.</span>';

    const words = ["Glow.", "Radiate.", "Bloom.", "Shine.", "Elevate.", "Become."];
    let i = 0;

    setInterval(() => {
      const el = document.querySelector("[data-alive-word]");
      if(!el) return;
      i = (i + 1) % words.length;
      el.classList.remove("alive-word");
      void el.offsetWidth;
      el.textContent = words[i];
      el.classList.add("alive-word");
    }, 2200);
  }

  function addCursorGlow(){
    document.addEventListener("mousemove", (event) => {
      document.querySelectorAll(".product, .form-card, .summary").forEach(card => {
        const rect = card.getBoundingClientRect();
        if(event.clientX >= rect.left && event.clientX <= rect.right && event.clientY >= rect.top && event.clientY <= rect.bottom){
          const x = ((event.clientX - rect.left) / rect.width) * 100;
          const y = ((event.clientY - rect.top) / rect.height) * 100;
          card.style.setProperty("--mx", x + "%");
          card.style.setProperty("--my", y + "%");
        }
      });
    });
  }

  function addHeroChips(){
    const lead = document.querySelector(".hero .lead");
    if(!lead || document.querySelector(".reza-floating-strip")) return;
    lead.insertAdjacentHTML("afterend", `
      <div class="reza-floating-strip">
        <span class="reza-chip">Luxury Beauty</span>
        <span class="reza-chip">Soft Wellness</span>
        <span class="reza-chip">Premium Care</span>
      </div>
    `);
  }

  document.addEventListener("DOMContentLoaded", () => {
    rotateHeroWords();
    addCursorGlow();
    addHeroChips();
  });
})();

function renderWixCheckout(){
  const page = document.querySelector("[data-v11-checkout]");
  if(!page) return;

  const c = cart();
  const subtotal = c.reduce((s,i)=>s + Number(i.price || 0) * Number(i.qty || 1), 0);

  page.innerHTML = `
    <section class="page-hero">
      <div class="container">
        <div class="kicker">Secure Checkout</div>
        <h1>Checkout</h1>
        <p class="lead">A clean Wix-style checkout with customer details, delivery choices and order summary.</p>
      </div>
    </section>

    <section class="section">
      <div class="container checkout-shell">
        <form class="checkout-card" onsubmit="checkout(event)">
          <div class="checkout-card-head">
            <div>
              <h2 style="font-size:2rem">Customer Information</h2>
              <p style="color:#7e6f61;margin:8px 0 0">Enter delivery/contact details.</p>
            </div>
            <div class="checkout-step">1</div>
          </div>

          <div class="checkout-card-body">
            <div class="checkout-grid">
              <div>
                <label class="checkout-label">Full name</label>
                <input class="input" name="name" placeholder="Full name" required>
              </div>
              <div>
                <label class="checkout-label">Phone / WhatsApp</label>
                <input class="input" name="phone" placeholder="+27..." required>
              </div>
              <div class="wide">
                <label class="checkout-label">Email</label>
                <input class="input" type="email" name="email" placeholder="Email address">
              </div>
            </div>
          </div>

          <div class="checkout-card-head">
            <div>
              <h2 style="font-size:2rem">Delivery Address</h2>
              <p style="color:#7e6f61;margin:8px 0 0">Similar to Wix checkout fields.</p>
            </div>
            <div class="checkout-step">2</div>
          </div>

          <div class="checkout-card-body">
            <div class="checkout-grid">
              <div>
                <label class="checkout-label">Country / Region</label>
                <select name="country" class="input" required>
                  <option>South Africa</option>
                  <option>Botswana</option>
                  <option>Zimbabwe</option>
                  <option>Namibia</option>
                  <option>Eswatini</option>
                  <option>Zambia</option>
                </select>
              </div>
              <div>
                <label class="checkout-label">Province / Region</label>
                <input class="input" name="province" placeholder="Limpopo / Gauteng / etc." required>
              </div>
              <div class="wide">
                <label class="checkout-label">Street Address</label>
                <input class="input" name="address" placeholder="Street address" required>
              </div>
              <div>
                <label class="checkout-label">City</label>
                <input class="input" name="city" placeholder="City" required>
              </div>
              <div>
                <label class="checkout-label">ZIP / Postal Code</label>
                <input class="input" name="postalCode" placeholder="Postal code">
              </div>
              <div class="wide">
                <label class="checkout-label">Paxi Number / Nearest Mall</label>
                <input class="input" name="paxiMall" placeholder="Paxi number or nearest mall">
              </div>
            </div>
          </div>

          <div class="checkout-card-head">
            <div>
              <h2 style="font-size:2rem">Delivery Method</h2>
              <p style="color:#7e6f61;margin:8px 0 0">Choose how the order should be delivered.</p>
            </div>
            <div class="checkout-step">3</div>
          </div>

          <div class="checkout-card-body">
            <div class="delivery-options">
              <label class="delivery-option active">
                <input type="radio" name="deliveryMethod" value="Paxi / Pickup Point" checked>
                <div><strong>Paxi / Pickup Point</strong><span>Customer provides Paxi number or nearest mall. Delivery confirmed after order.</span></div>
              </label>

              <label class="delivery-option">
                <input type="radio" name="deliveryMethod" value="Courier Delivery">
                <div><strong>Courier Delivery</strong><span>Door-to-door delivery. Cost confirmed after address check.</span></div>
              </label>

              <label class="delivery-option">
                <input type="radio" name="deliveryMethod" value="Collection">
                <div><strong>Collection</strong><span>Customer collects from arranged Reza collection point.</span></div>
              </label>
            </div>

            <br>
            <label class="checkout-label">Order Notes</label>
            <textarea class="input" name="notes" rows="4" placeholder="Any extra notes for this order"></textarea>
            <br><br>
            <button class="btn primary full">Place Order</button>
          </div>
        </form>

        <aside class="summary wix-summary">
          <h2>Order Summary</h2>
          <div style="margin:18px 0">
            ${
              c.length ? c.map(i => `
                <div class="summary-product">
                  <img src="${img(i.image)}" alt="${i.name}">
                  <div><strong>${i.name}</strong><span>${i.qty} × ${money(i.price)}</span></div>
                  <b>${money(Number(i.price || 0) * Number(i.qty || 1))}</b>
                </div>
              `).join("") : `<div class="empty">No cart items.</div>`
            }
          </div>

          <div class="row"><span>Subtotal</span><strong>${money(subtotal)}</strong></div>
          <div class="row"><span>Delivery</span><strong>Calculated after order</strong></div>
          <div class="row total"><span>Total</span><strong>${money(subtotal)}</strong></div>
          <br>
          <div class="checkout-secure">🔒 Secure checkout. Your order details are sent to Reza admin for processing.</div>
        </aside>
      </div>
    </section>
  `;

  document.querySelectorAll(".delivery-option").forEach(label => {
    label.addEventListener("click", () => {
      document.querySelectorAll(".delivery-option").forEach(x => x.classList.remove("active"));
      label.classList.add("active");
    });
  });
}

document.addEventListener("DOMContentLoaded", renderWixCheckout);

// ================================
// REZA V11.2 — SPECIAL ANNOUNCEMENT POPUP
// ================================
(function(){
  const POPUP_ENABLED = true;

  // Change this text whenever you have a special.
  const special = {
    title: "Welcome to Reza",
    message: "Premium health, beauty and wellness products with a soft champagne luxury experience.",
    note: "Special announcements, promos and product drops can appear here.",
    buttonText: "Shop Products",
    buttonLink: "shop.html"
  };

  function shouldShowPopup(){
    if(!POPUP_ENABLED) return false;

    // Shows once per browser session.
    // To show every time, change sessionStorage to localStorage or remove this check.
    return !sessionStorage.getItem("reza_v11_popup_seen");
  }

  function showPopup(){
    if(!shouldShowPopup()) return;

    const el = document.createElement("div");
    el.className = "reza-popup-backdrop";
    el.innerHTML = `
      <div class="reza-popup">
        <button class="reza-popup-close" aria-label="Close popup">×</button>
        <div class="reza-popup-top">
          <div class="reza-popup-kicker">Reza Announcement</div>
          <h2>${special.title}</h2>
          <p>${special.message}</p>
          <div class="reza-popup-note">${special.note}</div>
        </div>
        <div class="reza-popup-actions">
          <a class="btn primary" href="${special.buttonLink}">${special.buttonText}</a>
          <button class="btn ghost" data-popup-later>Maybe Later</button>
        </div>
      </div>
    `;

    document.body.appendChild(el);

    setTimeout(() => el.classList.add("show"), 650);

    function close(){
      sessionStorage.setItem("reza_v11_popup_seen", "yes");
      el.classList.remove("show");
      setTimeout(() => el.remove(), 220);
    }

    el.querySelector(".reza-popup-close").addEventListener("click", close);
    el.querySelector("[data-popup-later]").addEventListener("click", close);
    el.addEventListener("click", (event) => {
      if(event.target === el) close();
    });
  }

  document.addEventListener("DOMContentLoaded", showPopup);
})();

