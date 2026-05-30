const ADMIN_EMAIL = "admin@reza.co.za";
const ADMIN_PASSWORD = "reza2026";

function isAdmin() {
  return localStorage.getItem("reza_admin_logged_in") === "yes";
}

function requireAdmin() {
  if (!isAdmin() && !location.pathname.endsWith("login.html")) {
    location.href = "login.html";
  }
}

function adminLogout() {
  localStorage.removeItem("reza_admin_logged_in");
  location.href = "login.html";
}

function adminShell(active) {
  document.body.insertAdjacentHTML("afterbegin", `
    <div class="admin-layout">
      <aside class="sidebar">
        <div class="logo">Reza <span>Admin</span></div>
        <p style="color:rgba(255,255,255,.65)">Management panel</p>
        <a class="${active === "dashboard" ? "active" : ""}" href="dashboard.html">Dashboard</a>
        <a class="${active === "products" ? "active" : ""}" href="products.html">Products</a>
        <a class="${active === "shipping" ? "active" : ""}" href="shipping.html">Shipping</a>
        <a class="${active === "media" ? "active" : ""}" href="media.html">Media</a>
        <a class="${active === "payments" ? "active" : ""}" href="payments.html">Payments</a>
        <a class="${active === "orders" ? "active" : ""}" href="orders.html">Orders</a>
        <a href="../index.html">View Website</a>
        <a href="#" onclick="adminLogout()">Logout</a>
      </aside>
      <main class="admin-main" data-admin-main></main>
    </div>`);
}

function getOrders() {
  return JSON.parse(localStorage.getItem("reza_orders") || "[]");
}

function saveOrders(orders) {
  localStorage.setItem("reza_orders", JSON.stringify(orders));
}


function getBackendApiBase() {
  return localStorage.getItem("reza_api_base") || "https://api.rezaholdings.co.za";
}

async function backendLogin(email = ADMIN_EMAIL, password = ADMIN_PASSWORD) {
  const res = await fetch(`${getBackendApiBase()}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password })
  });

  const data = await res.json();
  if (!res.ok || !data.token) throw new Error(data.message || "Backend login failed");

  localStorage.setItem("reza_admin_token", data.token);
  return data.token;
}

async function getBackendToken() {
  const existing = localStorage.getItem("reza_admin_token");
  if (existing) return existing;
  return backendLogin();
}

async function backendFetch(path, options = {}) {
  const token = await getBackendToken();
  const res = await fetch(`${getBackendApiBase()}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
      Authorization: `Bearer ${token}`
    }
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok || data.success === false) throw new Error(data.message || data.error || `Backend error ${res.status}`);
  return data;
}
