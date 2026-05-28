const CACHE_NAME = "reza-admin-pwa-v1";

const ADMIN_SHELL = [
  "/admin/login.html",
  "/admin/dashboard.html",
  "/admin/products.html",
  "/admin/orders.html",
  "/admin/order-details.html",
  "/admin/media.html",
  "/admin/css/admin.css",
  "/admin/css/wix-orders.css",
  "/admin/css/advanced-orders.css",
  "/admin/css/admin-mobile-pwa.css",
  "/admin/js/admin-pwa.js",
  "/admin/assets/images/favicon.svg"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ADMIN_SHELL))
      .catch(() => null)
  );
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.map(key => key !== CACHE_NAME ? caches.delete(key) : null))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  const url = new URL(event.request.url);

  if (url.pathname.startsWith("/api/") || url.hostname.includes("api.rezaholdings.co.za")) {
    return;
  }

  if (event.request.method !== "GET") return;

  event.respondWith(
    fetch(event.request)
      .then(response => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy)).catch(() => null);
        return response;
      })
      .catch(() => caches.match(event.request).then(cached => cached || caches.match("/admin/login.html")))
  );
});
