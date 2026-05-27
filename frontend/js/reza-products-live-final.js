(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", { maximumFractionDigits: 0 });
  }

  function img(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function isComingSoon(p) {
    return p.status === "comingSoon" ||
           p.category === "Coming Soon" ||
           p.productType === "Coming Soon";
  }

  function isVisibleSale(p) {
    return p.showOnline !== false && !isComingSoon(p);
  }

  function card(p, coming = false) {
    return `
      <article class="reza-live-card">
        <div class="reza-live-img">
          <span>${coming ? "Coming Soon" : (p.productType || p.badge || "Product")}</span>
          <img src="${img(p.image)}" alt="${p.name}" loading="lazy">
        </div>
        <div class="reza-live-body">
          <p class="type">${p.category || ""}</p>
          <h3>${p.name || "Reza Product"}</h3>
          <p class="price">${coming ? "Coming Soon" : money(p.price)}</p>
          <p>${p.description || ""}</p>
          ${
            coming
              ? `<button type="button" class="muted">Coming Soon</button>`
              : `<button type="button" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Bag</button>`
          }
        </div>
      </article>
    `;
  }

  function allSaleGrids() {
    return [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid")
    ].filter(Boolean).filter(grid => {
      return grid.id !== "featuredProducts" &&
             !grid.classList.contains("featured-products") &&
             !grid.closest("[data-home-featured]");
    });
  }

  function featuredGrids() {
    return [
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")
    ].filter(Boolean);
  }

  function comingGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid"),
      document.querySelector("[data-coming-soon-products]")
    ].filter(Boolean);
  }

  async function load() {
    let products = [];
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      products = Array.isArray(data.products) ? data.products : [];
    } catch (error) {
      console.warn("Product load failed", error);
      return;
    }

    const sale = products.filter(isVisibleSale);
    const coming = products.filter(isComingSoon);

    const selectedFeatured = sale.filter(p => p.showFeatured === true).slice(0, 3);
    const featured = selectedFeatured.length ? selectedFeatured : sale.slice(0, 3);

    allSaleGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = sale.map(p => card(p, false)).join("") || `<p class="reza-empty">No products yet.</p>`;
    });

    featuredGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = featured.map(p => card(p, false)).join("") || `<p class="reza-empty">No featured products selected.</p>`;
    });

    comingGrids().forEach(grid => {
      grid.classList.add("reza-live-grid");
      grid.innerHTML = coming.map(p => card(p, true)).join("") || `<p class="reza-empty">No coming soon products yet.</p>`;
    });
  }

  document.addEventListener("DOMContentLoaded", load);
  window.addEventListener("load", load);
})();
