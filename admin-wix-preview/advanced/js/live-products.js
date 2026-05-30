
const REZA_API_BASE = "https://api.rezaholdings.co.za";

function productImageSrc(value) {
  if (!value) return "assets/images/product-placeholder.svg";
  if (String(value).startsWith("data:image/")) return value;
  if (String(value).startsWith("http")) return value;
  if (String(value).startsWith("../")) return value.replace("../", "");
  return value;
}

async function getLiveProducts() {
  try {
    const res = await fetch(`${REZA_API_BASE}/api/products`, { cache: "no-store" });
    const data = await res.json();

    if (data.success && Array.isArray(data.products)) {
      localStorage.setItem("reza_products_cache", JSON.stringify(data.products));
      return data.products.filter(p => p.showOnline !== false);
    }
  } catch (error) {
    console.warn("Could not load backend products:", error.message);
  }

  try {
    return JSON.parse(localStorage.getItem("reza_products_cache") || "[]");
  } catch {
    return [];
  }
}

async function getLiveProductById(id) {
  try {
    const res = await fetch(`${REZA_API_BASE}/api/products/${encodeURIComponent(id)}`, { cache: "no-store" });
    const data = await res.json();
    if (data.success && data.product) return data.product;
  } catch (error) {
    console.warn("Could not load backend product:", error.message);
  }

  const products = await getLiveProducts();
  return products.find(p => p.id === id);
}
