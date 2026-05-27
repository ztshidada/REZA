function checkoutImageSrc(value) {
  if (!value) return "assets/images/product-placeholder.svg";
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  return value;
}

function orderNumber() {
  const now = new Date();
  const date = now.toISOString().slice(0,10).replaceAll("-", "");
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `REZA-${date}-${rand}`;
}

function cartTotal() {
  const products = getStoredProducts();
  return getCart().reduce((sum, item) => {
    const p = products.find(x => x.id === item.id);
    return sum + (p ? p.price * item.qty : 0);
  }, 0);
}

function cartQty() {
  return getCart().reduce((sum, item) => sum + Number(item.qty || 0), 0);
}

function cartItemsDetailed() {
  const products = getStoredProducts();
  return getCart().map(item => {
    const p = products.find(x => x.id === item.id);
    return { ...item, name: p?.name, price: p?.price, image: p?.image, total: (p?.price || 0) * item.qty };
  });
}

function getShippingSettingsForCheckout() {
  const fallback = {
    domestic: [
      { id: "collect", name: "Collect from your nearest stockist.", type: "flat", rate: 0 },
      { id: "paxi", name: "PAXI", type: "flat", rate: 110 },
      { id: "courier", name: "The Courier Guy", type: "flat", rate: 150 },
      { id: "pudo", name: "PUDO - Locker to Locker", type: "quantity", ranges: [
        { from: 0, to: 1, rate: 60 }, { from: 1, to: 3, rate: 80 }, { from: 3, to: 6, rate: 100 }, { from: 6, to: 10, rate: 150 }
      ]}
    ]
  };
  try { return JSON.parse(localStorage.getItem("reza_shipping_settings")) || fallback; } catch { return fallback; }
}

function shippingFeeFor(methodName) {
  const settings = getShippingSettingsForCheckout();
  const method = (settings.domestic || []).find(r => r.name === methodName || r.id === methodName);
  if (!method) return 0;
  const total = cartTotal();
  if (method.freeOver && total >= Number(method.freeOver)) return 0;
  if (method.type === "quantity") {
    const qty = cartQty();
    const range = (method.ranges || []).find(r => qty > Number(r.from) && qty <= Number(r.to)) || (method.ranges || []).at(-1);
    return Number(range?.rate || 0);
  }
  return Number(method.rate || 0);
}

function renderCheckoutSummary() {
  const total = cartTotal();
  document.querySelectorAll("[data-checkout-total]").forEach(el => el.textContent = formatMoney(total));

  const itemsMount = document.querySelector("[data-checkout-items]");
  if (!itemsMount) return;

  const items = cartItemsDetailed();
  if (!items.length) {
    itemsMount.innerHTML = `<p>Your cart is empty. <a href="shop.html">Go back to shop</a>.</p>`;
    return;
  }

  itemsMount.innerHTML = items.map(item => `
    <div class="cart-line" style="grid-template-columns:64px 1fr auto">
      <img src="${checkoutImageSrc(item.image)}" alt="${item.name}" style="width:64px;height:64px">
      <div>
        <strong>${item.name}</strong><br>
        <small>Qty: ${item.qty}</small>
      </div>
      <strong>${formatMoney(item.total)}</strong>
    </div>
  `).join("");
}

function refreshDeliveryOptions() {
  const select = document.querySelector("[name='deliveryMethod']");
  if (!select) return;
  const settings = getShippingSettingsForCheckout();
  select.innerHTML = '<option value="">Choose delivery method</option>' + (settings.domestic || []).map(r => `<option value="${r.name}">${r.name} ${shippingFeeFor(r.name) ? "- " + formatMoney(shippingFeeFor(r.name)) : "- Free"}</option>`).join("");
  select.addEventListener("change", () => {
    const fee = shippingFeeFor(select.value);
    const subtotal = cartTotal();
    document.querySelectorAll("[data-delivery-fee]").forEach(el => el.textContent = formatMoney(fee));
    document.querySelectorAll("[data-checkout-total-2]").forEach(el => el.textContent = formatMoney(subtotal + fee));
  });
}

function showCheckoutError(message) {
  const result = document.querySelector("[data-checkout-result]");
  if (result) {
    result.innerHTML = `<div class="form-card"><h2>Payment setup problem</h2><p>${message}</p><p>Check that the backend is running and YOCO_SECRET_KEY is set in backend/.env.</p></div>`;
  }
  alert(message);
}

async function createYocoCheckout(order) {
  const apiBase = localStorage.getItem("reza_api_base") || "https://api.rezaholdings.co.za";
  const res = await fetch(`${apiBase}/api/payments/yoco/create-checkout`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ order })
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.success) {
    throw new Error(data.message || `Yoco checkout failed (${res.status})`);
  }
  return data;
}

document.addEventListener("DOMContentLoaded", () => {
  renderCheckoutSummary();
  refreshDeliveryOptions();

  const form = document.querySelector("[data-checkout-form]");
  if (!form) return;

  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    if (getCart().length === 0) {
      alert("Your cart is empty.");
      return;
    }

    const data = Object.fromEntries(new FormData(form).entries());
    const shipping = shippingFeeFor(data.deliveryMethod);
    const order = {
      id: orderNumber(),
      customer: data,
      items: cartItemsDetailed(),
      subtotal: cartTotal(),
      shipping,
      total: cartTotal() + shipping,
      paymentMethod: data.paymentMethod,
      paymentStatus: data.paymentMethod === "Yoco" ? "Pending Payment" : "Manual Payment",
      deliveryStatus: "New Order",
      createdAt: new Date().toISOString()
    };

    const orders = JSON.parse(localStorage.getItem("reza_orders") || "[]");
    orders.unshift(order);
    localStorage.setItem("reza_orders", JSON.stringify(orders));
    localStorage.setItem("reza_last_order", JSON.stringify(order));

    if (data.paymentMethod === "Yoco") {
      const btn = form.querySelector("button[type='submit']");
      btn.disabled = true;
      btn.textContent = "Redirecting to Yoco...";

      try {
        const yoco = await createYocoCheckout(order);
        order.yocoCheckoutId = yoco.checkout.id;
        order.yocoRedirectUrl = yoco.redirectUrl;
        order.yocoProcessingMode = yoco.checkout.processingMode;
        localStorage.setItem("reza_last_order", JSON.stringify(order));

        const updatedOrders = JSON.parse(localStorage.getItem("reza_orders") || "[]").map(o => o.id === order.id ? order : o);
        localStorage.setItem("reza_orders", JSON.stringify(updatedOrders));

        window.location.href = yoco.redirectUrl;
        return;
      } catch (error) {
        btn.disabled = false;
        btn.textContent = "Continue";
        showCheckoutError(error.message || 'Yoco checkout failed. Check backend Terminal for details.');
        return;
      }
    }

    localStorage.removeItem("reza_cart");
    updateCartCount();
    location.href = `thank-you.html?order=${encodeURIComponent(order.id)}`;
  });
});
