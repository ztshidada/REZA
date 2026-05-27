(function () {
  const API_BASE = location.hostname.includes("localhost") ? "http://localhost:10000" : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  function productImage(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function card(product, mode) {
    const coming = mode === "coming";
    const safeProduct = {
      id: product.id,
      name: product.name,
      price: Number(product.price || 0),
      image: productImage(product.image),
      category: product.category || "",
      productType: product.productType || ""
    };
    return `
      <article class="reza-final-product-card">
        <div class="reza-final-product-image-wrap">
          <span class="reza-final-badge">${coming ? "Coming Soon" : (product.badge || product.category || "On Sale")}</span>
          <img class="reza-final-product-image" src="${productImage(product.image)}" alt="${product.name || "Reza product"}" loading="lazy">
        </div>
        <div class="reza-final-product-body">
          <p class="reza-final-product-type">${product.category || ""} ${product.productType ? "• " + product.productType : ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-final-price">${coming ? "Coming Soon" : money(product.price)}</p>
          <p class="reza-final-description">${product.description || ""}</p>
          ${
            coming
              ? `<button class="reza-final-btn muted" type="button">Coming Soon</button>`
              : `<button class="reza-final-btn" type="button" onclick='addToCart(${JSON.stringify(safeProduct).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  function grids(list) {
    return list.map(s => document.querySelector(s)).filter(Boolean);
  }

  async function render() {
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !Array.isArray(data.products)) return;

      const products = data.products;
      const sale = products.filter(p => p.showOnline !== false && p.status !== "comingSoon" && p.category !== "Coming Soon" && p.productType !== "Coming Soon");
      const coming = products.filter(p => p.status === "comingSoon" || p.category === "Coming Soon" || p.productType === "Coming Soon");

      const saleGrids = grids(["#productsGrid","#productGrid",".products-grid",".product-grid","#featuredProducts",".featured-products"]);
      const comingGrids = grids(["#comingSoonGrid","#comingSoonProducts",".coming-soon-grid"]);

      saleGrids.forEach(g => {
        g.classList.add("reza-final-products-grid");
        const isFeatured = g.id === "featuredProducts" || g.classList.contains("featured-products");
        const items = isFeatured ? sale.slice(0,3) : sale;
        g.innerHTML = items.map(p => card(p, "sale")).join("") || `<p class="reza-final-empty">No products available yet.</p>`;
      });

      comingGrids.forEach(g => {
        g.classList.add("reza-final-products-grid");
        g.innerHTML = coming.map(p => card(p, "coming")).join("") || `<p class="reza-final-empty">No coming soon products yet.</p>`;
      });
    } catch(e) { console.warn("Product render failed", e); }
  }

  document.addEventListener("DOMContentLoaded", render);
  window.addEventListener("load", render);
})();
