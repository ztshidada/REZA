(function () {
  const API_BASE = location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];

  function readCart() {
    for (const key of CART_KEYS) {
      try {
        const data = JSON.parse(localStorage.getItem(key) || "[]");
        if (Array.isArray(data) && data.length) return data;
      } catch {}
    }
    return [];
  }

  function saveCart(cart) {
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    updateCartCount();
  }

  function updateCartCount() {
    const cart = readCart();
    const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);

    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],.bag-count").forEach(el => {
      el.textContent = count;
    });

    const cartLinks = document.querySelectorAll('a[href*="cart"], .cart-link, .bag-link');
    cartLinks.forEach(el => {
      if (!el.querySelector(".cart-count") && !el.querySelector(".bag-count")) {
        el.setAttribute("data-count", count);
      }
    });
  }

  function money(value) {
    const n = Number(value || 0);
    if (!n) return "Price coming soon";
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return API_BASE + src;
    return src;
  }

  window.addToCart = function(product) {
    const cart = readCart();
    const existing = cart.find(item => item.id === product.id);

    if (existing) {
      existing.qty = Number(existing.qty || existing.quantity || 1) + 1;
      existing.quantity = existing.qty;
    } else {
      cart.push({
        id: product.id,
        name: product.name,
        price: Number(product.price || 0),
        image: product.image || "",
        category: product.category || "",
        productType: product.productType || "",
        qty: 1,
        quantity: 1
      });
    }

    saveCart(cart);
    alert("Added to cart");
  };

  function productCard(product, mode) {
    const coming = mode === "coming";
    const badge = coming ? "Coming Soon" : (product.badge || product.productType || "On Sale");

    return `
      <article class="reza-master-card">
        <div class="reza-master-imgbox">
          <span>${badge}</span>
          <img src="${imageUrl(product.image)}" alt="${product.name}" loading="lazy">
        </div>
        <div class="reza-master-body">
          <p class="reza-master-type">${product.category || ""}</p>
          <h3>${product.name || "Reza Product"}</h3>
          <p class="reza-master-price">${coming ? "Coming Soon" : money(product.price)}</p>
          <p>${product.description || ""}</p>
          ${
            coming
              ? `<button type="button" class="reza-master-btn muted">Coming Soon</button>`
              : `<button type="button" class="reza-master-btn" onclick='addToCart(${JSON.stringify(product).replace(/'/g, "&apos;")})'>Add to Cart</button>`
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
      document.querySelector(".product-grid")
    ].filter(Boolean);
  }

  function findFeaturedGrids() {
    return [
      document.querySelector("#featuredProducts"),
      document.querySelector(".featured-products"),
      document.querySelector("[data-featured-products]")
    ].filter(Boolean);
  }

  function findComingGrids() {
    return [
      document.querySelector("#comingSoonGrid"),
      document.querySelector("#comingSoonProducts"),
      document.querySelector(".coming-soon-grid"),
      document.querySelector("[data-coming-soon-products]")
    ].filter(Boolean);
  }

  async function loadProducts() {
    updateCartCount();

    let products = [];
    try {
      const res = await fetch(API_BASE + "/api/products?t=" + Date.now());
      const data = await res.json();
      products = Array.isArray(data.products) ? data.products : [];
    } catch (error) {
      console.warn("Products failed to load", error);
      return;
    }

    const visibleSale = products.filter(p =>
      p.showOnline !== false &&
      p.status !== "comingSoon" &&
      p.category !== "Coming Soon" &&
      p.productType !== "Coming Soon"
    );

    const comingSoon = products.filter(p =>
      p.status === "comingSoon" ||
      p.category === "Coming Soon" ||
      p.productType === "Coming Soon"
    );

    const featuredSelected = visibleSale.filter(p => p.showFeatured === true).slice(0, 3);
    const featuredFallback = visibleSale.slice(0, 3);
    const featured = featuredSelected.length ? featuredSelected : featuredFallback;

    findSaleGrids().forEach(grid => {
      if (grid.id === "featuredProducts" || grid.classList.contains("featured-products")) return;
      grid.classList.add("reza-master-grid");
      grid.innerHTML = visibleSale.length
        ? visibleSale.map(p => productCard(p, "sale")).join("")
        : `<p class="reza-empty">No products available yet.</p>`;
    });

    findFeaturedGrids().forEach(grid => {
      grid.classList.add("reza-master-grid");
      grid.innerHTML = featured.length
        ? featured.map(p => productCard(p, "sale")).join("")
        : `<p class="reza-empty">No featured products selected yet.</p>`;
    });

    findComingGrids().forEach(grid => {
      grid.classList.add("reza-master-grid");
      grid.innerHTML = comingSoon.length
        ? comingSoon.map(p => productCard(p, "coming")).join("")
        : `<p class="reza-empty">No coming soon products yet.</p>`;
    });
  }

  document.addEventListener("DOMContentLoaded", loadProducts);
  window.addEventListener("load", loadProducts);
})();
