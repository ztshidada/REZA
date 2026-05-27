(function(){
  const CART_KEYS = ["reza_cart", "rezaCart", "cart", "reza_cart_items", "reza_v11_cart"];

  function readCart(){
    for(const key of CART_KEYS){
      try{
        const value = JSON.parse(localStorage.getItem(key) || "[]");
        if(Array.isArray(value) && value.length) return value;
      }catch(e){}
    }
    return [];
  }

  function writeCart(cart){
    CART_KEYS.forEach(key => localStorage.setItem(key, JSON.stringify(cart)));
    updateCartCount();
  }

  function normaliseProduct(product){
    const id = product.id || product.sku || product.name?.toLowerCase().replace(/[^a-z0-9]+/g, "-") || ("product-" + Date.now());
    return {
      id,
      name: product.name || "Reza Product",
      price: Number(product.price || 0),
      image: product.image || "",
      category: product.category || "",
      productType: product.productType || "",
      qty: Number(product.qty || 1)
    };
  }

  window.addToCart = function(product){
    const cart = readCart();
    const item = normaliseProduct(product || {});
    const existing = cart.find(x => x.id === item.id);

    if(existing) existing.qty = Number(existing.qty || 1) + 1;
    else cart.push(item);

    writeCart(cart);
    showToast(`${item.name} added to cart`);
  };

  window.rezaRemoveCartItem = function(id){
    writeCart(readCart().filter(item => item.id !== id));
    renderCartPage();
  };

  window.rezaChangeCartQty = function(id, change){
    const cart = readCart();
    const item = cart.find(x => x.id === id);
    if(item){
      item.qty = Math.max(1, Number(item.qty || 1) + change);
      writeCart(cart);
      renderCartPage();
    }
  };

  function updateCartCount(){
    const count = readCart().reduce((sum,item)=>sum + Number(item.qty || 1), 0);
    document.querySelectorAll(".cart-count,.cart-badge,[data-cart-count],[data-count],#cartCount").forEach(el => {
      el.textContent = count;
    });
  }

  function money(v){
    const n = Number(v || 0);
    return "R " + n.toLocaleString("en-ZA", {minimumFractionDigits:0, maximumFractionDigits:0});
  }

  function showToast(message){
    let toast = document.querySelector(".reza-cart-toast");
    if(!toast){
      toast = document.createElement("div");
      toast.className = "reza-cart-toast";
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add("show");
    setTimeout(()=>toast.classList.remove("show"), 2200);
  }

  function findCartTarget(){
    return document.querySelector("#cartItems") ||
           document.querySelector("#cartList") ||
           document.querySelector(".cart-items") ||
           document.querySelector(".cart-list") ||
           document.querySelector("[data-cart-items]");
  }

  function renderCartPage(){
    const isCartPage = /cart\.html/i.test(location.pathname) || document.querySelector("[data-cart-page]");
    if(!isCartPage) {
      updateCartCount();
      return;
    }

    let target = findCartTarget();

    if(!target){
      const main = document.querySelector("main") || document.body;
      target = document.createElement("section");
      target.className = "reza-cart-page-box";
      target.setAttribute("data-cart-items", "true");
      main.appendChild(target);
    }

    const cart = readCart();
    const subtotal = cart.reduce((sum,item)=>sum + Number(item.price || 0) * Number(item.qty || 1), 0);

    if(!cart.length){
      target.innerHTML = `
        <div class="reza-empty-cart">
          <h2>Your cart is empty</h2>
          <p>Add products from the catalog and they will appear here.</p>
          <a href="shop.html">Shop Products</a>
        </div>
      `;
    } else {
      target.innerHTML = `
        <div class="reza-cart-table">
          ${cart.map(item => `
            <div class="reza-cart-row">
              <img src="${item.image || "assets/images/reza-card-bg.svg"}" alt="${item.name}">
              <div>
                <h3>${item.name}</h3>
                <p>${item.category || ""} ${item.productType ? "• " + item.productType : ""}</p>
                <strong>${money(item.price)}</strong>
              </div>
              <div class="reza-cart-qty">
                <button onclick="rezaChangeCartQty('${item.id}', -1)">−</button>
                <span>${item.qty || 1}</span>
                <button onclick="rezaChangeCartQty('${item.id}', 1)">+</button>
              </div>
              <button class="reza-cart-remove" onclick="rezaRemoveCartItem('${item.id}')">Remove</button>
            </div>
          `).join("")}
        </div>
        <div class="reza-cart-summary">
          <p>Subtotal <strong>${money(subtotal)}</strong></p>
          <p>Delivery <strong>Calculated after order</strong></p>
          <hr>
          <p class="total">Total <strong>${money(subtotal)}</strong></p>
          <a href="checkout.html">Checkout</a>
        </div>
      `;
    }

    document.querySelectorAll(".cart-subtotal,[data-cart-subtotal]").forEach(el => el.textContent = money(subtotal));
    document.querySelectorAll(".cart-total,[data-cart-total]").forEach(el => el.textContent = money(subtotal));
    updateCartCount();
  }

  document.addEventListener("DOMContentLoaded", () => {
    updateCartCount();
    renderCartPage();
  });
  window.addEventListener("storage", () => {
    updateCartCount();
    renderCartPage();
  });
})();
