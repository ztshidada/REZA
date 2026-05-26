(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function money(v) {
    const n = Number(v || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function normaliseImage(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function productCard(p, comingSoon = false) {
    return `
      <article class="product-card">
        <div class="product-img">
          ${p.badge ? `<span class="badge">${p.badge}</span>` : ""}
          <img src="${normaliseImage(p.image)}" alt="${p.name}" loading="lazy">
        </div>
        <div class="product-info">
          <h3>${p.name}</h3>
          <p class="price">${comingSoon ? "Coming Soon" : money(p.price)}</p>
          <p>${p.description || ""}</p>
          ${
            comingSoon
              ? `<button class="btn secondary" type="button">Coming Soon</button>`
              : `<button class="btn primary" type="button" onclick='addToCart(${JSON.stringify(p).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  async function loadProducts() {
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !Array.isArray(data.products)) return;

      const saleProducts = data.products.filter(p => p.status !== "comingSoon" && p.showOnline !== false);
      const comingSoonProducts = data.products.filter(p => p.status === "comingSoon" || p.category === "Coming Soon");

      const saleGrids = [
        document.querySelector("#productsGrid"),
        document.querySelector("#productGrid"),
        document.querySelector(".products-grid"),
        document.querySelector(".product-grid"),
        document.querySelector("#featuredProducts")
      ].filter(Boolean);

      const comingGrids = [
        document.querySelector("#comingSoonGrid"),
        document.querySelector(".coming-soon-grid"),
        document.querySelector("#comingSoonProducts")
      ].filter(Boolean);

      if (saleGrids.length) {
        const html = saleProducts.map(p => productCard(p, false)).join("");
        saleGrids.forEach(grid => grid.innerHTML = html || "<p>No sale products found.</p>");
      }

      if (comingGrids.length) {
        const html = comingSoonProducts.map(p => productCard(p, true)).join("");
        comingGrids.forEach(grid => grid.innerHTML = html || "<p>No coming soon products found.</p>");
      }
    } catch (err) {
      console.warn("Could not load products", err);
    }
  }

  window.addToCart = window.addToCart || function(product) {
    const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
    const existing = cart.find(item => item.id === product.id);

    if (existing) existing.qty += 1;
    else cart.push({ ...product, qty: 1 });

    localStorage.setItem("reza_cart", JSON.stringify(cart));
    alert("Added to cart");
  };

  document.addEventListener("DOMContentLoaded", loadProducts);
})();
