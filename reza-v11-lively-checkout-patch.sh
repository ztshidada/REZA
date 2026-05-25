#!/bin/bash
set -e

echo "✨ Applying Reza V11.1 Alive + Wix Checkout Patch..."

if [ ! -d "frontend" ] || [ ! -d "admin" ] || [ ! -d "backend" ]; then
  echo "❌ Run this inside the reza-v11-champagne-luxury folder."
  exit 1
fi

cat >> frontend/css/app.css <<'CSS'

/* ================================
   REZA V11.1 — ALIVE LUXURY MOTION
   ================================ */

body {
  animation: rezaPageIn .7s cubic-bezier(.2,.9,.2,1) both;
}

@keyframes rezaPageIn {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: translateY(0); }
}

.hero {
  isolation: isolate;
}

.hero::before {
  content: "";
  position: absolute;
  inset: -20%;
  z-index: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 20% 20%, rgba(255,255,255,.35), transparent 6%),
    radial-gradient(circle at 80% 30%, rgba(232,201,141,.35), transparent 8%),
    radial-gradient(circle at 45% 75%, rgba(243,215,200,.34), transparent 7%);
  filter: blur(20px);
  opacity: .75;
  animation: rezaAurora 9s ease-in-out infinite alternate;
}

@keyframes rezaAurora {
  from { transform: translate3d(-18px,-8px,0) scale(1); }
  to { transform: translate3d(22px,12px,0) scale(1.06); }
}

.hero-grid {
  animation: rezaHeroRise .85s cubic-bezier(.2,.9,.2,1) both;
}

@keyframes rezaHeroRise {
  from { opacity: 0; transform: translateY(38px) scale(.985); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.alive-word {
  display: inline-block;
  background: linear-gradient(135deg,#2a1d17 0%, #8a5b19 45%, #2a1d17 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  animation: rezaWordPop .75s cubic-bezier(.2,.9,.2,1) both;
}

@keyframes rezaWordPop {
  0% { opacity: 0; transform: translateY(20px) rotateX(45deg) scale(.92); filter: blur(8px); }
  60% { opacity: 1; transform: translateY(-4px) rotateX(0) scale(1.04); filter: blur(0); }
  100% { opacity: 1; transform: translateY(0) scale(1); }
}

.hero-card {
  animation: rezaFloatCard 5.5s ease-in-out infinite;
  transform-origin: center;
}

@keyframes rezaFloatCard {
  0%,100% { translate: 0 0; rotate: 1.5deg; }
  50% { translate: 0 -14px; rotate: -.8deg; }
}

.product,
.form-card,
.summary {
  position: relative;
  overflow: hidden;
}

.product::after,
.form-card::after,
.summary::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: radial-gradient(circle at var(--mx,50%) var(--my,20%), rgba(255,255,255,.45), transparent 28%);
  opacity: 0;
  transition: .25s ease;
}

.product:hover::after,
.form-card:hover::after,
.summary:hover::after {
  opacity: 1;
}

.product-img img {
  transition: transform .55s cubic-bezier(.2,.9,.2,1), filter .35s ease;
}

.product:hover .product-img img {
  transform: scale(1.08) rotate(.35deg);
  filter: saturate(1.06) contrast(1.03);
}

.btn::before {
  content: "";
  position: absolute;
  top: 0;
  left: -130%;
  width: 70%;
  height: 100%;
  background: linear-gradient(90deg,transparent,rgba(255,255,255,.48),transparent);
  transform: skewX(-20deg);
  transition: left .65s ease;
}

.btn:hover::before {
  left: 145%;
}

.primary {
  animation: rezaButtonGlow 3.2s ease-in-out infinite;
}

@keyframes rezaButtonGlow {
  0%,100% { box-shadow: 0 18px 42px rgba(201,148,61,.20), 0 0 0 rgba(201,148,61,0); }
  50% { box-shadow: 0 20px 50px rgba(201,148,61,.28), 0 0 28px rgba(255,212,122,.42); }
}

.reza-floating-strip {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 28px;
}

.reza-chip {
  padding: 10px 14px;
  border-radius: 999px;
  background: rgba(255,255,255,.64);
  border: 1px solid rgba(255,255,255,.8);
  color: #6c5848;
  font-weight: 900;
  box-shadow: 0 10px 25px rgba(74,52,43,.08);
  animation: rezaChipFloat 4.5s ease-in-out infinite;
}

.reza-chip:nth-child(2) { animation-delay: .4s; }
.reza-chip:nth-child(3) { animation-delay: .8s; }

@keyframes rezaChipFloat {
  0%,100% { translate: 0 0; }
  50% { translate: 0 -8px; }
}

/* WIX-LIKE CHECKOUT */

.checkout-shell {
  display: grid;
  grid-template-columns: minmax(0,1.35fr) 440px;
  gap: 30px;
  align-items: start;
}

.checkout-card {
  background: rgba(255,255,255,.76);
  border: 1px solid rgba(255,255,255,.85);
  box-shadow: 0 24px 70px rgba(74,52,43,.13);
  border-radius: 32px;
  overflow: hidden;
}

.checkout-card-head {
  padding: 24px 28px;
  border-bottom: 1px solid rgba(74,52,43,.10);
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: center;
}

.checkout-step {
  width: 34px;
  height: 34px;
  border-radius: 999px;
  display: grid;
  place-items: center;
  background: #2a1d17;
  color: #fffaf2;
  font-weight: 1000;
}

.checkout-card-body {
  padding: 28px;
}

.checkout-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.checkout-grid .wide {
  grid-column: 1/-1;
}

.checkout-label {
  display: block;
  font-size: .82rem;
  text-transform: uppercase;
  letter-spacing: .12em;
  font-weight: 950;
  color: #8a735f;
  margin: 0 0 8px;
}

.delivery-options {
  display: grid;
  gap: 12px;
}

.delivery-option {
  border: 1px solid rgba(74,52,43,.13);
  border-radius: 22px;
  padding: 16px;
  display: flex;
  gap: 14px;
  align-items: flex-start;
  background: rgba(255,255,255,.58);
  cursor: pointer;
  transition: .2s ease;
}

.delivery-option:hover,
.delivery-option.active {
  border-color: rgba(201,148,61,.75);
  transform: translateY(-2px);
  box-shadow: 0 14px 35px rgba(201,148,61,.12);
}

.delivery-option input {
  margin-top: 5px;
}

.delivery-option strong {
  display: block;
  color: #2a1d17;
}

.delivery-option span {
  display: block;
  color: #7e6f61;
  font-size: .92rem;
  margin-top: 4px;
  line-height: 1.4;
}

.wix-summary {
  position: sticky;
  top: 112px;
}

.summary-product {
  display: grid;
  grid-template-columns: 62px 1fr auto;
  gap: 14px;
  align-items: center;
  padding: 14px 0;
  border-bottom: 1px solid rgba(74,52,43,.10);
}

.summary-product img {
  width: 62px;
  height: 62px;
  border-radius: 16px;
  object-fit: cover;
}

.checkout-secure {
  padding: 15px;
  border-radius: 20px;
  background: linear-gradient(135deg,#fff6df,#ffe8d9);
  color: #744f19;
  font-weight: 850;
  line-height: 1.45;
}

@media(max-width:980px) {
  .checkout-shell { grid-template-columns: 1fr; }
  .wix-summary { position: static; }
}

@media(max-width:650px) {
  .checkout-grid { grid-template-columns: 1fr; }
}
CSS

cat >> frontend/js/app.js <<'JS'

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
JS

cat > frontend/checkout.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Checkout | Reza Holdings</title>
  <link rel="stylesheet" href="css/app.css">
</head>
<body>
  <div class="announce">Soft luxury • Health • Beauty • Wellness</div>
  <header class="header">
    <div class="container nav">
      <a class="brand" href="index.html"><div class="brand-mark">R</div><div class="brand-text"><strong>Reza Holdings</strong><span>Champagne Luxury</span></div></a>
      <nav class="links">
        <a href="index.html">Home</a>
        <a class="active" href="shop.html">Shop</a>
        <a href="about.html">About</a>
        <a href="contact.html">Contact</a>
        <a href="policies.html">Policies</a>
      </nav>
      <div class="actions"><a class="cart" href="cart.html">🛒<span data-count>0</span></a><a class="btn primary" href="shop.html">Shop</a></div>
    </div>
  </header>

  <main data-v11-checkout></main>

  <footer class="footer"><div class="container">Reza Holdings • +27 79 377 3550 • rezaofficeinc@gmail.com</div></footer>
  <script src="js/app.js"></script>
</body>
</html>
HTML

echo "✅ V11.1 Alive + Wix Checkout patch applied."
