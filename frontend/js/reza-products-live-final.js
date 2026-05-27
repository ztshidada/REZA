(function () {
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function formatMoney(value) {
    return "R " + Number(value || 0).toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  function findProductContainer() {
    const selectors = [
      "#productsGrid",
      "#productGrid",
      "#featuredProducts",
      ".products-grid",
      ".product-grid",
      ".featured-products",
      ".luxury-products",
      ".products"
    ];

    for (const selector of selectors) {
      const el = document.querySelector(selector);
      if (el) return el;
    }

    const allSections = [...document.querySelectorAll("section, div")];
    const luxurySection = allSections.find(el =>
      el.innerText &&
      el.innerText.toLowerCase().includes("luxury picks")
    );

    if (luxurySection) {
      let grid = luxurySection.querySelector(".reza-live-products-grid");
      if (!grid) {
        grid = document.createElement("div");
        grid.className = "reza-live-products-grid";
        luxurySection.appendChild(grid);
      }
      return grid;
    }

    return null;
  }

  function productCard(p) {
    return `
      <article class="reza-live-card">
        <div class="reza-live-img-wrap">
          ${p.badge ? `<span class="reza-live-badge">${p.badge}</span>` : ""}
          <img src="${imageUrl(p.image)}" alt="${p.name}">
        </div>

        <div class="reza-live-info">
          <p class="reza-live-cat">${p.category || "Reza Holdings"}</p>
          <h3>${p.name || "Product"}</h3>
          <p class="reza-live-price">${formatMoney(p.price)}</p>
          <p class="reza-live-desc">${p.description || ""}</p>

          <button class="reza-live-btn" type="button"
            data-product='${JSON.stringify(p).replace(/'/g, "&apos;")}'>
            Add to Cart
          </button>
        </div>
      </article>
    `;
  }

  async function loadProducts() {
    const container = findProductContainer();

    if (!container) {
      console.warn("Reza products container not found.");
      return;
    }

    container.classList.add("reza-live-products-grid");
    container.innerHTML = `<div class="reza-live-loading">Loading products...</div>`;

    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();

      if (!data.success || !Array.isArray(data.products)) {
        container.innerHTML = `<div class="reza-live-empty">Products could not load.</div>`;
        return;
      }

      const products = data.products.filter(p => p.showOnline !== false);

      if (!products.length) {
        container.innerHTML = `<div class="reza-live-empty">No products found.</div>`;
        return;
      }

      container.innerHTML = products.map(productCard).join("");

      container.querySelectorAll(".reza-live-btn").forEach(btn => {
        btn.addEventListener("click", () => {
          const product = JSON.parse(btn.dataset.product.replace(/&apos;/g, "'"));
          const cart = JSON.parse(localStorage.getItem("reza_cart") || "[]");
          const existing = cart.find(item => item.id === product.id);

          if (existing) existing.qty += 1;
          else cart.push({ ...product, qty: 1 });

          localStorage.setItem("reza_cart", JSON.stringify(cart));

          const badge = document.querySelector(".cart-count, #cartCount, .cart-badge");
          if (badge) badge.textContent = cart.reduce((sum, item) => sum + Number(item.qty || 1), 0);

          alert("Added to cart");
        });
      });

      console.log("✅ Reza live products rendered:", products.length);
    } catch (error) {
      console.error(error);
      container.innerHTML = `<div class="reza-live-empty">Could not connect to products API.</div>`;
    }
  }

  document.addEventListener("DOMContentLoaded", loadProducts);
  window.addEventListener("load", loadProducts);
})();
