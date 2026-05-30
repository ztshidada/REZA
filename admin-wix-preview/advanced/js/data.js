const REZA_PRODUCTS = [
  {
    id: "tissue-oil-80",
    name: "Premium Tissue Oil",
    category: "Skincare",
    price: 80,
    stock: 30,
    badge: "Best Seller",
    image: "assets/images/product-placeholder.svg",
    description: "Premium skincare oil made to support soft, healthy-looking and glowing skin.",
    benefits: ["Supports glowing skin", "Helps improve the look of dry skin", "Suitable for daily skincare routines"],
    howToUse: "Apply a small amount onto clean skin and massage gently."
  },
  {
    id: "tissue-oil-10",
    name: "Premium Tissue Oil (10)",
    category: "Skincare",
    price: 500,
    stock: 12,
    badge: "Bulk Deal",
    image: "assets/images/product-placeholder.svg",
    description: "A bulk pack for resellers or customers who want more value.",
    benefits: ["Great reseller pack", "Better value", "Premium skincare support"],
    howToUse: "Use as part of your daily skincare routine."
  },
  {
    id: "anti-ageing-combo",
    name: "Reza Complete Anti-Ageing Skin Combo",
    category: "Combos",
    price: 480,
    stock: 15,
    badge: "Combo",
    image: "assets/images/combo-placeholder.svg",
    description: "A premium skincare combo designed for a renewed, restored and radiant skin routine.",
    benefits: ["Complete skincare routine", "Supports radiant-looking skin", "Premium combo value"],
    howToUse: "Use products according to the routine instructions provided with your order."
  },
  {
    id: "starter-pack-combo",
    name: "Reza Starter Pack Combo",
    category: "Combos",
    price: 1400,
    stock: 8,
    badge: "Premium Pack",
    image: "assets/images/combo-placeholder.svg",
    description: "A complete starter pack combo for customers who want the full Reza experience.",
    benefits: ["Best value pack", "Multiple products included", "Suitable for business/reseller starter orders"],
    howToUse: "Follow the included routine guide."
  },
  {
    id: "sea-moss",
    name: "Reza Sea Moss",
    category: "Wellness",
    price: 250,
    stock: 0,
    badge: "Coming Soon",
    image: "assets/images/wellness-placeholder.svg",
    description: "Wildcrafted Irish sea moss wellness support. Coming soon.",
    benefits: ["Wellness support", "Mineral-rich product", "Daily routine support"],
    howToUse: "Instructions will be available when product launches."
  },
  {
    id: "acne-care",
    name: "Reza Acne Care Collection",
    category: "Body Care",
    price: 350,
    stock: 0,
    badge: "Coming Soon",
    image: "assets/images/soap-placeholder.svg",
    description: "A luxury soap collection made for clearer, healthier-looking skin.",
    benefits: ["Beauty routine support", "Premium soap collection", "Gentle daily care"],
    howToUse: "Use during bath or shower routine."
  }
];

function getStoredProducts() {
  const saved = localStorage.getItem("reza_products");
  if (!saved) {
    localStorage.setItem("reza_products", JSON.stringify(REZA_PRODUCTS));
    return REZA_PRODUCTS;
  }
  try {
    return JSON.parse(saved);
  } catch {
    localStorage.setItem("reza_products", JSON.stringify(REZA_PRODUCTS));
    return REZA_PRODUCTS;
  }
}

function saveProducts(products) {
  localStorage.setItem("reza_products", JSON.stringify(products));
}
