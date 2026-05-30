
/*
  Reza Final Live Sync
  This file must load LAST.
  It connects frontend/admin display to backend products + media.
*/

const REZA_API_BASE_FINAL = "https://api.rezaholdings.co.za";

/* ---------------------------
   Helpers
---------------------------- */
function rezaMoney(value) {
  if (typeof formatMoney === "function") return formatMoney(value);
  return "R " + Number(value || 0).toLocaleString("en-ZA", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).replace(".", ",");
}

function rezaCleanImage(value, fallback = "assets/images/product-placeholder.svg") {
  if (!value) return fallback;
  value = String(value);

  if (value.startsWith("data:image/")) return value;
  if (value.startsWith("http://") || value.startsWith("https://")) return value;
  if (value.startsWith("../")) return value.replace("../", "");
  if (value.startsWith("./")) return value.replace("./", "");

  return value;
}

function rezaGetCart() {
  try {
    if (typeof getCart === "function") return getCart();
  } catch {}

  try {
    return JSON.parse(localStorage.getItem("reza_cart") || "[]");
  } catch {
    return [];
  }
}

function rezaSaveCart(cart) {
  try {
    if (typeof saveCart === "function") {
      saveCart(cart);
      return;
    }
  } catch {}

  localStorage.setItem("reza_cart", JSON.stringify(cart));
}

function rezaUpdateCartCount() {
  try {
    if (typeof updateCartCount === "function") {
      updateCartCount();
      return;
    }
  } catch {}

  const count = rezaGetCart().reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);
  document.querySelectorAll("[data-cart-count], .cart-count").forEach(el => {
    el.textContent = count;
  });
}

/* ---------------------------
   Products API
---------------------------- */
async function rezaLoadProducts() {
  try {
    const res = await fetch(`${REZA_API_BASE_FINAL}/api/products`, { cache: "no-store" });
    const data = await res.json();

    if (data.success && Array.isArray(data.products)) {
      localStorage.setItem("reza_products_cache", JSON.stringify(data.products));
      return data.products.filter(p => p.showOnline !== false);
    }
  } catch (error) {
    console.warn("Reza products API failed:", error.message);
  }

  try {
    return JSON.parse(localStorage.getItem("reza_products_cache") || "[]");
  } catch {
    return [];
  }
}

async function rezaFindProduct(id) {
  const products = await rezaLoadProducts();
  return products.find(p => String(p.id) === String(id));
}

/* ---------------------------
   Add to cart override
---------------------------- */
window.addToCart = async function(productId, qty = 1) {
  const product = await rezaFindProduct(productId);

  if (!product) {
    alert("Product not found. Please refresh the page and try again.");
    return;
  }

  const cart = rezaGetCart().map(item => ({
    id: item.id,
    name: item.name || "Reza Product",
    price: Number(item.price || 0),
    image: item.image || "assets/images/product-placeholder.svg",
    qty: Number(item.qty || item.quantity || 1)
  }));

  const existing = cart.find(item => String(item.id) === String(product.id));

  if (existing) {
    existing.qty += Number(qty || 1);
  } else {
    cart.push({
      id: product.id,
      name: product.name,
      price: Number(product.price || 0),
      image: product.image || "assets/images/product-placeholder.svg",
      qty: Number(qty || 1)
    });
  }

  rezaSaveCart(cart);
  rezaUpdateCartCount();

  if (typeof showToast === "function") {
    showToast(`${product.name} added to cart`);
  } else {
    alert(`${product.name} added to cart`);
  }
};

/* ---------------------------
   Product cards
---------------------------- */
function rezaProductCard(product) {
  const img = rezaCleanImage(product.image);
  const badge = product.badge || product.category || "Reza";
  const desc = product.description || "Premium Reza health, beauty and wellness product.";

  return `
    <article class="product-card reza-live-card">
      <div class="product-image">
        <span class="badge">${badge}</span>
        <img src="${img}" alt="${product.name || "Reza Product"}" loading="lazy">
      </div>
      <div class="product-body">
        <h3>${product.name || "Reza Product"}</h3>
        <div class="price">${rezaMoney(product.price)}</div>
        <p>${desc}</p>
        <div class="card-actions">
          <a class="btn dark" href="product.html?id=${encodeURIComponent(product.id)}">View Product</a>
          <button class="btn glow-btn" type="button" onclick="addToCart('${product.id}')">Add to Cart</button>
        </div>
      </div>
    </article>
  `;
}

async function rezaRenderProductLists() {
  const products = await rezaLoadProducts();

  const shopMount =
    document.querySelector("[data-products]") ||
    document.querySelector("#productsGrid") ||
    document.querySelector(".products-grid");

  if (shopMount && location.pathname.includes("shop")) {
    const searchInput = document.querySelector("[data-search]");
    const categorySelect = document.querySelector("[data-category]");
    const search = (searchInput?.value || "").trim().toLowerCase();
    const category = categorySelect?.value || "All";

    let list = [...products];

    if (category && category !== "All") {
      list = list.filter(p => p.category === category);
    }

    if (search) {
      list = list.filter(p => `${p.name || ""} ${p.category || ""} ${p.description || ""}`.toLowerCase().includes(search));
    }

    if (!list.length) {
      shopMount.innerHTML = `
        <div class="form-card" style="grid-column:1/-1;text-align:center">
          <h2>No products found</h2>
          <p>Products added in Admin will appear here after saving.</p>
        </div>
      `;
    } else {
      shopMount.innerHTML = list.map(rezaProductCard).join("");
    }

    if (categorySelect && !categorySelect.dataset.rezaReady) {
      const categories = ["All", ...new Set(products.map(p => p.category).filter(Boolean))];
      categorySelect.innerHTML = categories.map(c => `<option value="${c}">${c}</option>`).join("");
      categorySelect.dataset.rezaReady = "1";
      categorySelect.addEventListener("change", rezaRenderProductLists);
    }

    if (searchInput && !searchInput.dataset.rezaReady) {
      searchInput.dataset.rezaReady = "1";
      searchInput.addEventListener("input", rezaRenderProductLists);
    }
  }

  const homeMount = document.querySelector("[data-home-products]");
  if (homeMount && !location.pathname.includes("shop")) {
    const featured = products.slice(0, 4);

    if (!featured.length) {
      homeMount.innerHTML = `
        <div class="form-card" style="grid-column:1/-1;text-align:center">
          <h2>No featured products yet</h2>
          <p>Add products from Admin &gt; Products.</p>
        </div>
      `;
    } else {
      homeMount.innerHTML = featured.map(rezaProductCard).join("");
    }
  }
}

/* ---------------------------
   Cart page
---------------------------- */
function rezaRenderCartPage() {
  const cartMount =
    document.querySelector("[data-cart-items]") ||
    document.querySelector("#cartItems") ||
    document.querySelector(".cart-items");

  if (!cartMount) return;

  const cart = rezaGetCart().map(item => ({
    id: item.id,
    name: item.name || "Reza Product",
    price: Number(item.price || 0),
    image: item.image || "assets/images/product-placeholder.svg",
    qty: Number(item.qty || item.quantity || 1)
  }));

  if (!cart.length) {
    cartMount.innerHTML = `
      <div class="form-card" style="text-align:center">
        <h2>Your cart is empty</h2>
        <p>Add products to your cart before checkout.</p>
        <a class="btn dark" href="shop.html">Shop Products</a>
      </div>
    `;
  } else {
    cartMount.innerHTML = cart.map(item => `
      <div class="cart-item reza-cart-item">
        <img src="${rezaCleanImage(item.image)}" alt="${item.name}">
        <div>
          <h3>${item.name}</h3>
          <p>${rezaMoney(item.price)}</p>
        </div>
        <div class="qty-control">
          <button type="button" onclick="rezaChangeCartQty('${item.id}', -1)">−</button>
          <strong>${item.qty}</strong>
          <button type="button" onclick="rezaChangeCartQty('${item.id}', 1)">+</button>
        </div>
        <strong>${rezaMoney(item.price * item.qty)}</strong>
        <button class="cart-remove" type="button" onclick="rezaRemoveFromCart('${item.id}')">Remove</button>
      </div>
    `).join("");
  }

  const subtotal = cart.reduce((sum, item) => sum + item.price * item.qty, 0);

  document.querySelectorAll("[data-cart-subtotal], [data-subtotal], .cart-subtotal").forEach(el => {
    el.textContent = rezaMoney(subtotal);
  });

  document.querySelectorAll("[data-cart-total], [data-total], .cart-total").forEach(el => {
    el.textContent = rezaMoney(subtotal);
  });

  rezaSaveCart(cart);
  rezaUpdateCartCount();
}

window.rezaChangeCartQty = function(productId, delta) {
  const cart = rezaGetCart().map(item => ({
    id: item.id,
    name: item.name,
    price: Number(item.price || 0),
    image: item.image,
    qty: Number(item.qty || item.quantity || 1)
  }));

  const item = cart.find(p => String(p.id) === String(productId));
  if (!item) return;

  item.qty += Number(delta || 0);
  rezaSaveCart(cart.filter(p => p.qty > 0));
  rezaRenderCartPage();
};

window.rezaRemoveFromCart = function(productId) {
  const cart = rezaGetCart().filter(p => String(p.id) !== String(productId));
  rezaSaveCart(cart);
  rezaRenderCartPage();
};

/* ---------------------------
   Media / Backgrounds
---------------------------- */
async function rezaLoadMedia() {
  try {
    const res = await fetch(`${REZA_API_BASE_FINAL}/api/media`, { cache: "no-store" });
    const data = await res.json();

    if (data.success && data.media) {
      localStorage.setItem("reza_media_cache", JSON.stringify(data.media));
      return data.media;
    }
  } catch (error) {
    console.warn("Reza media API failed:", error.message);
  }

  try {
    return JSON.parse(localStorage.getItem("reza_media_cache") || "{}");
  } catch {
    return {};
  }
}

async function rezaApplyBackgrounds() {
  const media = await rezaLoadMedia();

  const bg1 = rezaCleanImage(media.background1, "assets/images/background-image-1.png");
  const bg2 = rezaCleanImage(media.background2, bg1);
  const bg3 = rezaCleanImage(media.background3, bg1);
  const logo = rezaCleanImage(media.logo, "assets/images/reza-logo.png");

  document.documentElement.style.setProperty("--reza-bg-1", `url("${bg1}")`);
  document.documentElement.style.setProperty("--reza-bg-2", `url("${bg2}")`);
  document.documentElement.style.setProperty("--reza-bg-3", `url("${bg3}")`);

  const bgStyle = `linear-gradient(90deg, rgba(7,48,32,.78), rgba(32,27,20,.42)), url("${bg1}")`;

  document.querySelectorAll(".hero, .page-hero, .checkout-hero, .landing-hero, .shop-hero, [data-hero]").forEach(el => {
    el.style.backgroundImage = bgStyle;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
  });

  document.querySelectorAll("img[data-reza-logo], img[src*='reza-logo'], .brand-logo img, .logo img").forEach(img => {
    img.src = logo;
  });

  document.body.classList.add("reza-media-loaded");
}

/* ---------------------------
   Boot
---------------------------- */
document.addEventListener("DOMContentLoaded", async () => {
  await rezaApplyBackgrounds();
  await rezaRenderProductLists();
  rezaRenderCartPage();
  rezaUpdateCartCount();
});
