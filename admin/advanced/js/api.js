const REZA_API_BASE = localStorage.getItem("reza_api_base") || "https://api.rezaholdings.co.za";

async function apiGet(path) {
  const res = await fetch(`${REZA_API_BASE}${path}`);
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json();
}

async function apiPost(path, body, token = localStorage.getItem("reza_admin_token")) {
  const res = await fetch(`${REZA_API_BASE}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify(body)
  });
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json();
}
