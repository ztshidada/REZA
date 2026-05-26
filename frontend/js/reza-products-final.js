(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function img(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function addToCart(product) {
    const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
    const existing = cart.find(item => item.id === product.id);

    if (existing) existing.qty += 1;
    else cart.push({ ...product, qty: 1 });

    localStorage.setItem("reza_cart", JSON.stringify(cart));

    const count = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count]").forEach(el => {
      el.textContent = count;
    });

    alert("Added to cart");
  }

  window.addToCart = addToCart;

  function productCard(product, mode) {
    const isComing = mode === "coming";
    const badge = isComing ? "Coming Soon" : (product.badge || "On Sale");

    return `
      <article class="reza-final-product-card">
        <div class="reza-final-product-image-wrap">
          <span class="reza-final-badge">${badge}</span>
          <img
            src="${img(product.image)}"
            alt="${product.name || "Reza product"}"
            loading="lazy"
            class="reza-final-product-image"
          >
        </div>

        <div class="reza-final-product-body">
          <p class="reza-final-product-type">${product.productType || product.category || ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-final-price">${isComing ? "Coming Soon" : money(product.price)}</p>
          <p class="reza-final-description">${product.description || ""}</p>

          ${
            isComing
              ? `<button class="reza-final-btn muted" type="button">Coming Soon</button>`
              : `<button class="reza-final-btn" type="button" onclick='addToCart(${JSON.stringify(product).replace(/'/g, "&apos;")})'>Add to Cart</button>`
          }
        </div>
      </article>
    `;
  }

  function findSaleGrids() {
    return [
      document.querySelector("#productsGrid"),
      document.querySelector("#productGrid"),
      document.querySelector(".products-grid"),
      document.querySelector(".product-grid"),
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products")
    ].filter(Boolean);
  }

  function findComingSoonGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid")
    ].filter(Boolean);
  }

  async function renderProducts() {
    try {
      const response = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await response.json();

      if (!data.success || !Array.isArray(data.products)) return;

      const all = data.products;

      const saleProducts = all.filter(product => {
        return product.status !== "comingSoon" &&
               product.category !== "Coming Soon" &&
               product.showOnline !== false;
      });

      const comingProducts = all.filter(product => {
        return product.status === "comingSoon" ||
               product.category === "Coming Soon" ||
               product.productType === "Coming Soon";
      });

      const saleGrids = findSaleGrids();
      const comingGrids = findComingSoonGrids();

      saleGrids.forEach(grid => {
        grid.classList.add("reza-final-products-grid");

        const isHomeFeatured =
          grid.id === "featuredProducts" ||
          grid.classList.contains("featured-products");

        const productsToShow = isHomeFeatured ? saleProducts.slice(0, 3) : saleProducts;

        grid.innerHTML = productsToShow.length
          ? productsToShow.map(product => productCard(product, "sale")).join("")
          : `<p class="reza-final-empty">No products available yet.</p>`;
      });

      comingGrids.forEach(grid => {
        grid.classList.add("reza-final-products-grid");

        grid.innerHTML = comingProducts.length
          ? comingProducts.map(product => productCard(product, "coming")).join("")
          : `<p class="reza-final-empty">No coming soon products yet.</p>`;
      });

    } catch (error) {
      console.warn("Reza product render failed:", error);
    }
  }

  document.addEventListener("DOMContentLoaded", renderProducts);
  window.addEventListener("load", renderProducts);
})();
