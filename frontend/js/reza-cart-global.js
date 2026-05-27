(function () {
  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items"];

  function readAnyCart() {
    for (const key of CART_KEYS) {
      try {
        const value = JSON.parse(localStorage.getItem(key) || "[]");
        if (Array.isArray(value) && value.length) return value;
      } catch {}
    }
    return [];
  }

  function saveEverywhere(cart) {
    localStorage.setItem("reza_cart", JSON.stringify(cart));
    localStorage.setItem("rezaCart", JSON.stringify(cart));
    localStorage.setItem("cart", JSON.stringify(cart));
    localStorage.setItem("reza_cart_items", JSON.stringify(cart));
    updateBagCount();
  }

  function updateBagCount() {
    const cart = readAnyCart();
    const count = cart.reduce((total, item) => total + Number(item.qty || item.quantity || 1), 0);

    document.querySelectorAll(
      ".cart-count,.cart-badge,.bag-count,[data-cart-count],#cartCount,#cart-count,#bagCount"
    ).forEach(el => {
      el.textContent = count;
    });

    document.querySelectorAll('a[href*="cart"], .cart-link, .bag-link').forEach(link => {
      link.setAttribute("href", "cart.html");
      link.setAttribute("data-count", count);
    });

    document.body.setAttribute("data-cart-count", count);
  }

  window.RezaCart = {
    read: readAnyCart,
    save: saveEverywhere,
    count: updateBagCount
  };

  window.addToCart = function (product) {
    const cart = readAnyCart();
    const id = product.id || product.name;
    const existing = cart.find(item => String(item.id || item.name) === String(id));

    if (existing) {
      existing.qty = Number(existing.qty || existing.quantity || 1) + 1;
      existing.quantity = existing.qty;
    } else {
      cart.push({
        id,
        name: product.name || "Reza Product",
        price: Number(product.price || 0),
        image: product.image || "",
        category: product.category || "",
        productType: product.productType || "",
        qty: 1,
        quantity: 1
      });
    }

    saveEverywhere(cart);

    const toast = document.createElement("div");
    toast.className = "reza-cart-toast";
    toast.textContent = "Added to bag";
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 1600);
  };

  document.addEventListener("DOMContentLoaded", updateBagCount);
  window.addEventListener("load", updateBagCount);
  window.addEventListener("storage", updateBagCount);
})();
