
document.addEventListener("DOMContentLoaded", async () => {
  const params = new URLSearchParams(location.search);
  const id = params.get("id");
  const mount = document.querySelector("[data-product-detail]");
  if (!mount) return;

  const product = await getLiveProductById(id);

  if (!product) {
    mount.innerHTML = `<div class="container"><h1>Product not found</h1><a class="btn dark" href="shop.html">Back to shop</a></div>`;
    return;
  }

  mount.innerHTML = `
    <div class="container product-detail-grid">
      <div class="product-detail-image">
        <img src="${productImageSrc(product.image)}" alt="${product.name}">
      </div>
      <div class="product-detail-info">
        <div class="kicker">${product.category || "Reza Product"}</div>
        <h1>${product.name}</h1>
        <div class="price big">${formatMoney(product.price)}</div>
        <p>${product.description || ""}</p>

        <h3>Benefits</h3>
        <ul>
          ${(product.benefits || []).map(b => `<li>${b}</li>`).join("")}
        </ul>

        <h3>How to use</h3>
        <p>${product.howToUse || "Use as directed on the package."}</p>

        <button class="btn dark" onclick="addToCart('${product.id}')">Add to Cart</button>
      </div>
    </div>
  `;
});
