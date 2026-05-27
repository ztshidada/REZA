(function () {
  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];

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
    CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));
    updateCartCount(cart);
  }

  function money(value) {
    const n = Number(value || 0);
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function updateCartCount(cart = readCart()) {
    const count = cart.reduce((sum, item) => sum + Number(item.qty || item.quantity || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],[data-count],.bag-count,#cartCount").forEach(el => {
      el.textContent = count;
    });
  }

  function imageUrl(src) {
    if (!src) return "assets/images/reza-card-bg.svg";
    return src;
  }

  function findCartContainer() {
    return (
      document.querySelector("#cartItems") ||
      document.querySelector(".cart-items") ||
      document.querySelector("#cartList") ||
      document.querySelector(".cart-list")
    );
  }

  function findSummaryContainer() {
    return (
      document.querySelector("#orderSummary") ||
      document.querySelector(".order-summary") ||
      document.querySelector(".summary")
    );
  }

  function renderCart() {
    const cart = readCart();
    updateCartCount(cart);

    const itemBox = findCartContainer();
    const summaryBox = findSummaryContainer();

    const subtotal = cart.reduce((sum, item) => {
      return sum + (Number(item.price || 0) * Number(item.qty || item.quantity || 1));
    }, 0);

    if (!cart.length) {
      document.body.classList.add("reza-cart-empty-state");
      if (itemBox) {
        itemBox.innerHTML = `
          <div class="reza-cart-empty">
            <h1>Your cart is empty</h1>
            <p>Add products before checkout.</p>
            <a href="shop.html">Shop Products</a>
          </div>
        `;
      }
    } else {
      document.body.classList.remove("reza-cart-empty-state");
      if (itemBox) {
        itemBox.innerHTML = cart.map((item, index) => {
          const qty = Number(item.qty || item.quantity || 1);
          return `
            <div class="reza-cart-row">
              <img src="${imageUrl(item.image)}" alt="${item.name || "Product"}">
              <div>
                <h3>${item.name || "Product"}</h3>
                <p>${money(item.price || 0)}</p>
              </div>
              <div class="reza-cart-controls">
                <button type="button" data-minus="${index}">−</button>
                <strong>${qty}</strong>
                <button type="button" data-plus="${index}">+</button>
              </div>
              <strong>${money(Number(item.price || 0) * qty)}</strong>
              <button type="button" data-remove="${index}" class="reza-remove">Remove</button>
            </div>
          `;
        }).join("");

        itemBox.querySelectorAll("[data-minus]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.minus);
            cart[i].qty = Math.max(1, Number(cart[i].qty || cart[i].quantity || 1) - 1);
            cart[i].quantity = cart[i].qty;
            saveCart(cart);
            renderCart();
          };
        });

        itemBox.querySelectorAll("[data-plus]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.plus);
            cart[i].qty = Number(cart[i].qty || cart[i].quantity || 1) + 1;
            cart[i].quantity = cart[i].qty;
            saveCart(cart);
            renderCart();
          };
        });

        itemBox.querySelectorAll("[data-remove]").forEach(btn => {
          btn.onclick = () => {
            const i = Number(btn.dataset.remove);
            cart.splice(i, 1);
            saveCart(cart);
            renderCart();
          };
        });
      }
    }

    if (summaryBox) {
      summaryBox.innerHTML = `
        <h2>Summary</h2>
        <div class="reza-summary-line"><span>Subtotal</span><strong>${money(subtotal)}</strong></div>
        <div class="reza-summary-line"><span>Delivery</span><strong>Calculated after order</strong></div>
        <hr>
        <div class="reza-summary-line total"><span>Total</span><strong>${money(subtotal)}</strong></div>
        <a href="checkout.html" class="reza-checkout-btn">Checkout</a>
      `;
    }
  }

  document.addEventListener("DOMContentLoaded", renderCart);
  window.addEventListener("load", renderCart);
})();
