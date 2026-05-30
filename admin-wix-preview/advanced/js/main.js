function formatMoney(value) {
  return "R " + Number(value || 0).toLocaleString("en-ZA", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function getCart() {
  return JSON.parse(localStorage.getItem("reza_cart") || "[]");
}

function saveCart(cart) {
  localStorage.setItem("reza_cart", JSON.stringify(cart));
  updateCartCount();
}

function updateCartCount() {
  const count = getCart().reduce((sum, item) => sum + item.qty, 0);
  document.querySelectorAll("[data-cart-count]").forEach(el => el.textContent = count);
}


// Backend-aware cart helpers
async function findRezaProduct(productId) {
  // 1. Try backend/live products first
  try {
    if (typeof getLiveProductById === "function") {
      const liveProduct = await getLiveProductById(productId);
      if (liveProduct) return liveProduct;
    }
  } catch (error) {
    console.warn("Live product lookup failed:", error.message);
  }

  // 2. Try cached backend products
  try {
    const cached = JSON.parse(localStorage.getItem("reza_products_cache") || "[]");
    const cachedProduct = cached.find(p => p.id === productId);
    if (cachedProduct) return cachedProduct;
  } catch {}

  // 3. Fallback to old static products
  if (Array.isArray(window.PRODUCTS)) {
    const staticProduct = window.PRODUCTS.find(p => p.id === productId);
    if (staticProduct) return staticProduct;
  }

  if (Array.isArray(typeof PRODUCTS !== "undefined" ? PRODUCTS : [])) {
    const staticProduct = PRODUCTS.find(p => p.id === productId);
    if (staticProduct) return staticProduct;
  }

  return null;
}

async function addToCart(productId, qty = 1) {
  const product = await findRezaProduct(productId);

  if (!product) {
    alert("Product not found. Please refresh the page and try again.");
    return;
  }

  const cart = getCart();
  const existing = cart.find(item => item.id === productId);

  if (existing) {
    existing.qty = Number(existing.qty || 1) + Number(qty || 1);
  } else {
    cart.push({
      id: product.id,
      name: product.name,
      price: Number(product.price || 0),
      image: product.image || "assets/images/product-placeholder.svg",
      qty: Number(qty || 1)
    });
  }

  saveCart(cart);
  updateCartCount();

  if (typeof showToast === "function") {
    showToast(`${product.name} added to cart`);
  } else {
    alert(`${product.name} added to cart`);
  }
}


function renderHeader() {
  const header = document.querySelector("[data-header]");
  if (!header) return;
  header.innerHTML = `
    <div class="topbar">PREMIUM HEALTH • BEAUTY • WELLNESS PRODUCTS</div>
    <header class="header">
      <div class="container nav">
        <a class="logo" href="index.html"><img class="logo-img" src="assets/images/reza-logo.png" alt="Reza logo"><span>Holdings</span></a>
        <nav class="navlinks" id="rezaNavLinks">
          <a href="index.html">Home</a>
          <a href="shop.html">Shop</a>
          <a href="about.html">About</a>
          <a href="contact.html">Contact</a>
          <a href="policies.html">Policies</a>
        </nav>
        <div class="nav-actions">
          <a class="icon-btn" href="cart.html" aria-label="Cart">🛒<span class="cart-count" data-cart-count>0</span></a>
          <a class="btn dark" href="shop.html">Shop Now</a>
        </div>
      </div>
    </header>`;
}

function renderFooter() {
  const footer = document.querySelector("[data-footer]");
  if (!footer) return;
  footer.innerHTML = `
    <footer class="footer">
      <div class="container footer-grid">
        <div>
          <div class="logo"><img class="logo-img" src="assets/images/reza-logo.png" alt="Reza logo"><span>Holdings</span></div>
          <p>Premium health, beauty and wellness products made to support confidence, self-care and everyday wellness.</p>
        </div>
        <div>
          <h3>Shop</h3>
          <a href="shop.html">All Products</a>
          <a href="shop.html?category=Skincare">Skincare</a>
          <a href="shop.html?category=Combos">Combos</a>
          <a href="shop.html?category=Wellness">Wellness</a>
        </div>
        <div>
          <h3>Support</h3>
          <a href="contact.html">Contact</a>
          <a href="policies.html#shipping">Shipping Policy</a>
          <a href="policies.html#refund">Refund Policy</a>
          <a href="policies.html#privacy">Privacy Policy</a>
        </div>
        <div>
          <h3>Contact</h3>
          <p>WhatsApp: +27 79 377 3550</p>
          <p>Email: rezaofficeinc@gmail.com</p>
        </div>
      </div>
      <div class="container" style="border-top:1px solid rgba(255,255,255,.12);margin-top:32px;padding-top:20px;color:rgba(255,255,255,.65)">
        © ${new Date().getFullYear()} Reza Holdings. All rights reserved.
      </div>
    </footer>`;
}

function renderWhatsapp() {
  const wa = document.querySelector("[data-whatsapp]");
  if (!wa) return;
  wa.innerHTML = `<a class="whatsapp-float" href="https://wa.me/27793773550?text=Hi%20Reza%20Holdings%2C%20I%20want%20to%20order." target="_blank">WA</a>`;
}

document.addEventListener("DOMContentLoaded", () => {
  renderHeader();
  renderFooter();
  renderWhatsapp();
  updateCartCount();
  applyRezaMediaSettings();
});



function getRezaMediaSettings() {
  try {
    return JSON.parse(localStorage.getItem("reza_background_images") || "{}");
  } catch {
    return {};
  }
}

function mediaUrl(value, fallback) {
  if (!value) return fallback;
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  return value;
}

function applyRezaMediaSettings() {
  const media = getRezaMediaSettings();

  const logo = mediaUrl(media.logo, "assets/images/reza-logo.png");
  const bg1 = mediaUrl(media.bg1, "assets/images/background-image-1.png");
  const bg2 = mediaUrl(media.bg2, "assets/images/background-image-2.png");
  const bg3 = mediaUrl(media.bg3, "assets/images/background-image-3.png");

  document.querySelectorAll(".logo-img").forEach(img => {
    img.src = logo;
  });

  const mainBg = `linear-gradient(90deg, rgba(24,61,44,.82), rgba(36,29,25,.48)), url("${bg1}")`;
  const secondBg = `linear-gradient(90deg, rgba(24,61,44,.82), rgba(36,29,25,.48)), url("${bg2}")`;
  const thirdBg = `linear-gradient(90deg, rgba(24,61,44,.82), rgba(36,29,25,.48)), url("${bg3}")`;

  document.querySelectorAll(".hero, .checkout-bg, .thankyou-bg").forEach(el => {
    el.style.backgroundImage = mainBg;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
  });

  document.querySelectorAll(".page-hero, .bg-image-1").forEach(el => {
    el.style.backgroundImage = mainBg;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
  });

  document.querySelectorAll(".bg-image-2").forEach(el => {
    el.style.backgroundImage = secondBg;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
  });

  document.querySelectorAll(".bg-image-3").forEach(el => {
    el.style.backgroundImage = thirdBg;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
  });
}



