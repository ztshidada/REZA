
function safeText(value, fallback = "") {
  return value == null ? fallback : String(value);
}

function productCard(product) {
  const available = Number(product.stock || 0) > 0;
  const badge = product.badge || product.category || "Reza";
  const description = product.description || "Premium Reza health, beauty and wellness product.";

  return `
    <article class="product-card reza-safe-reveal">
      <div class="product-image">
        <span class="badge">${safeText(badge)}</span>
        <img src="${productImageSrc(product.image)}" alt="${safeText(product.name)}" loading="lazy">
      </div>
      <div class="product-body">
        <h3>${safeText(product.name, "Reza Product")}</h3>
        <div class="price">${formatMoney(product.price)}</div>
        <p>${safeText(description)}</p>
        <div class="card-actions">
          <a class="btn dark" href="product.html?id=${encodeURIComponent(product.id)}">View Product</a>
          <button class="btn ${available ? "" : "outline"}" ${available ? "" : "disabled"} onclick="addToCart('${product.id}')">
            ${available ? "Add to Cart" : "Coming Soon"}
          </button>
        </div>
      </div>
    </article>
  `;
}

let LIVE_PRODUCTS = [];

async function renderProducts() {
  const mount = document.querySelector("[data-products]");
  if (!mount) return;

  LIVE_PRODUCTS = await getLiveProducts();

  const params = new URLSearchParams(location.search);
  const selectedCategory = params.get("category") || "All";
  const search = (document.querySelector("[data-search]")?.value || "").trim().toLowerCase();

  let products = LIVE_PRODUCTS;

  if (selectedCategory !== "All") {
    products = products.filter(p => p.category === selectedCategory);
  }

  if (search) {
    products = products.filter(p => `${p.name || ""} ${p.category || ""} ${p.description || ""}`.toLowerCase().includes(search));
  }

  if (!products.length) {
    mount.innerHTML = `
      <div class="form-card" style="grid-column:1/-1;text-align:center">
        <h2>No products found</h2>
        <p>Products added in Admin will appear here after saving.</p>
      </div>
    `;
    return;
  }

  mount.innerHTML = products.map(productCard).join("");
}

async function renderCategories() {
  const select = document.querySelector("[data-category]");
  if (!select) return;

  const products = await getLiveProducts();
  const categories = ["All", ...new Set(products.map(p => p.category).filter(Boolean))];
  const params = new URLSearchParams(location.search);
  const selected = params.get("category") || "All";

  select.innerHTML = categories.map(cat => `<option value="${cat}" ${cat === selected ? "selected" : ""}>${cat}</option>`).join("");

  select.addEventListener("change", () => {
    const value = select.value;
    location.href = value === "All" ? "shop.html" : `shop.html?category=${encodeURIComponent(value)}`;
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  await renderCategories();
  await renderProducts();

  const search = document.querySelector("[data-search]");
  if (search) search.addEventListener("input", renderProducts);
});
