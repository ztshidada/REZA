window.REZA_API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

async function rezaFetch(path) {
  const res = await fetch(window.REZA_API_BASE + path + "?t=" + Date.now());
  return await res.json();
}

function money(v) {
  return "R " + Number(v || 0).toLocaleString("en-ZA", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

function normaliseImage(src) {
  if (!src) return "assets/images/reza-card-bg.svg";
  if (src.startsWith("data:image")) return src;
  if (src.startsWith("http")) return src;
  if (src.startsWith("/")) return window.REZA_API_BASE + src;
  return src;
}

async function applyLiveMedia() {
  try {
    const data = await rezaFetch("/api/media");
    if (!data.success || !data.media) return;

    const img = normaliseImage(data.media.heroImage);

    document.querySelectorAll(".hero, .page-hero").forEach(el => {
      el.style.backgroundImage =
        `linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)), url("${img}")`;
      el.style.backgroundSize = "cover";
      el.style.backgroundPosition = "center";
    });
  } catch (e) {
    console.warn("Media not loaded", e);
  }
}

async function applyLiveProducts() {
  try {
    const data = await rezaFetch("/api/products");
    if (!data.success || !Array.isArray(data.products)) return;

    const products = data.products.filter(p => p.showOnline !== false);

    const grids = [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid"),
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products")
    ].filter(Boolean);

    if (!grids.length) return;

    const html = products.map(p => `
      <article class="product-card" data-id="${p.id}">
        <div class="product-img">
          ${p.badge ? `<span class="badge">${p.badge}</span>` : ""}
          <img src="${normaliseImage(p.image)}" alt="${p.name}" style="width:100%;height:260px;object-fit:cover;border-radius:22px;">
        </div>
        <div class="product-info">
          <h3>${p.name}</h3>
          <p class="price">${money(p.price)}</p>
          <p>${p.description || ""}</p>
          <button class="btn primary" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>
        </div>
      </article>
    `).join("");

    grids.forEach(grid => {
      grid.innerHTML = html || `<p>No products found.</p>`;
    });
  } catch (e) {
    console.warn("Products not loaded", e);
  }
}

window.addToCart = function(product) {
  const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
  const existing = cart.find(item => item.id === product.id);

  if (existing) {
    existing.qty += 1;
  } else {
    cart.push({ ...product, qty: 1 });
  }

  localStorage.setItem("reza_cart", JSON.stringify(cart));
  alert("Added to cart");
};

document.addEventListener("DOMContentLoaded", () => {
  applyLiveMedia();
  applyLiveProducts();
});
