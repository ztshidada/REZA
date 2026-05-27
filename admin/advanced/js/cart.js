function cartImageSrc(value) {
  if (!value) return "assets/images/product-placeholder.svg";
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  return value;
}

function renderCart() {
  const lines = document.querySelector("[data-cart-lines]");
  const summary = document.querySelector("[data-cart-summary]");
  if (!lines || !summary) return;

  const products = getStoredProducts();
  const cart = getCart();

  if (cart.length === 0) {
    lines.innerHTML = `<div class="form-card">Your cart is empty. <a href="shop.html">Go to shop</a>.</div>`;
    summary.innerHTML = "";
    return;
  }

  let total = 0;
  lines.innerHTML = cart.map(item => {
    const product = products.find(p => p.id === item.id);
    if (!product) return "";
    const lineTotal = product.price * item.qty;
    total += lineTotal;
    return `
      <div class="cart-line">
        <img src="${cartImageSrc(product.image)}" alt="${product.name}">
        <div>
          <strong>${product.name}</strong>
          <div class="price">${formatMoney(product.price)}</div>
          <div class="qty">
            <button onclick="changeQty('${item.id}', -1)">-</button>
            <span>${item.qty}</span>
            <button onclick="changeQty('${item.id}', 1)">+</button>
          </div>
        </div>
        <div>
          <strong>${formatMoney(lineTotal)}</strong><br>
          <button class="icon-btn" onclick="removeFromCart('${item.id}')" style="margin-top:10px">✕</button>
        </div>
      </div>`;
  }).join("");

  summary.innerHTML = `
    <h2>Order Summary</h2>
    <p style="display:flex;justify-content:space-between"><span>Subtotal</span><strong>${formatMoney(total)}</strong></p>
    <p style="display:flex;justify-content:space-between"><span>Delivery</span><strong>Calculated after order</strong></p>
    <hr>
    <p style="display:flex;justify-content:space-between;font-size:22px"><span>Total</span><strong>${formatMoney(total)}</strong></p>
    <a class="btn dark" style="width:100%;margin-top:16px" href="checkout.html">Checkout</a>
  `;
}

function changeQty(id, delta) {
  const cart = getCart().map(item => item.id === id ? { ...item, qty: Math.max(1, item.qty + delta) } : item);
  saveCart(cart);
  renderCart();
}

function removeFromCart(id) {
  saveCart(getCart().filter(item => item.id !== id));
  renderCart();
}

document.addEventListener("DOMContentLoaded", renderCart);
