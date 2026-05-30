
document.addEventListener("DOMContentLoaded", async () => {
  const best = document.querySelector("[data-home-products]");
  if (!best) return;

  const products = (await getLiveProducts())
    .filter(p => p.badge !== "Coming Soon")
    .slice(0, 4);

  if (!products.length) {
    best.innerHTML = `
      <div class="form-card" style="grid-column:1/-1;text-align:center">
        <h2>No featured products yet</h2>
        <p>Add products from Admin > Products.</p>
      </div>
    `;
    return;
  }

  best.innerHTML = products.map(productCard).join("");
});
