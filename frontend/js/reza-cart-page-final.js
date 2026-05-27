(function () {
  function money(value) {
    const n = Number(value || 0);
    return "R " + n.toLocaleString("en-ZA", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  }

  function readCart() {
    if (window.RezaCart) return window.RezaCart.read();
    try { return JSON.parse(localStorage.getItem("reza_cart") || "[]"); }
    catch { return []; }
  }

  function saveCart(cart) {
    if (window.RezaCart) window.RezaCart.save(cart);
    else localStorage.setItem("reza_cart", JSON.stringify(cart));
  }

  function image(src) {
    return src || "assets/images/reza-card-bg.svg";
  }

  function getItemsBox() {
    return document.querySelector("#cartItems") ||
           document.querySelector(".cart-items") ||
           document.querySelector("#cartList") ||
           document.querySelector(".cart-list") ||
           document.querySelector("main");
  }

  function getSummaryBox() {
    return document.querySelector("#orderSummary") ||
           document.querySelector(".order-summary") ||
           document.querySelector(".summary");
  }

  function render() {
    const cart = readCart();
    const itemsBox = getItemsBox();
    const summaryBox = getSummaryBox();

    const subtotal = cart.reduce((sum, item) => {
      return sum + Number(item.price || 0) * Number(item.qty || item.quantity || 1);
    }, 0);

    if (!itemsBox) return;

    if (!cart.length) {
      itemsBox.innerHTML = `
        <section class="reza-cart-empty-box">
          <h1>Your cart is empty</h1>
          <p>Add products before checkout.</p>
          <a href="shop.html">Shop Products</a>
        </section>
      `;
    } else {
      itemsBox.innerHTML = `
        <section class="reza-cart-wrap">
          <div class="reza-cart-items">
            ${cart.map((item, index) => {
              const qty = Number(item.qty || item.quantity || 1);
              return `
                <article class="reza-cart-item">
                  <img src="${image(item.image)}" alt="${item.name || "Product"}">
                  <div>
                    <h3>${item.name || "Product"}</h3>
                    <p>${money(item.price || 0)}</p>
                  </div>
                  <div class="reza-cart-qty">
                    <button data-minus="${index}">−</button>
                    <strong>${qty}</strong>
                    <button data-plus="${index}">+</button>
                  </div>
                  <strong>${money(Number(item.price || 0) * qty)}</strong>
                  <button class="reza-cart-remove" data-remove="${index}">Remove</button>
                </article>
              `;
            }).join("")}
          </div>

          <aside class="reza-cart-summary-final">
            <h2>Summary</h2>
            <div><span>Subtotal</span><strong>${money(subtotal)}</strong></div>
            <div><span>Delivery</span><strong>Calculated after order</strong></div>
            <hr>
            <div class="total"><span>Total</span><strong>${money(subtotal)}</strong></div>
            <button>Checkout</button>
          </aside>
        </section>
      `;
    }

    if (summaryBox) {
      summaryBox.innerHTML = "";
    }

    document.querySelectorAll("[data-minus]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.minus);
        cart[i].qty = Math.max(1, Number(cart[i].qty || cart[i].quantity || 1) - 1);
        cart[i].quantity = cart[i].qty;
        saveCart(cart);
        render();
      };
    });

    document.querySelectorAll("[data-plus]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.plus);
        cart[i].qty = Number(cart[i].qty || cart[i].quantity || 1) + 1;
        cart[i].quantity = cart[i].qty;
        saveCart(cart);
        render();
      };
    });

    document.querySelectorAll("[data-remove]").forEach(btn => {
      btn.onclick = () => {
        const i = Number(btn.dataset.remove);
        cart.splice(i, 1);
        saveCart(cart);
        render();
      };
    });
  }

  document.addEventListener("DOMContentLoaded", render);
  window.addEventListener("load", render);
})();
