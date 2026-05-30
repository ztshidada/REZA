#!/usr/bin/env bash
set -e

echo "== Creating offline Wix-style admin preview =="

rm -rf admin-wix-preview
cp -R admin admin-wix-preview

mkdir -p admin-wix-preview/css admin-wix-preview/js

cat > admin-wix-preview/css/admin-wix-preview.css <<'CSS'
:root{
  --wx-bg:#f7f8fb;
  --wx-panel:#ffffff;
  --wx-ink:#162033;
  --wx-muted:#64748b;
  --wx-line:#e5e7eb;
  --wx-blue:#116dff;
  --wx-green:#0f9f6e;
  --wx-red:#d92d20;
  --wx-shadow:0 18px 45px rgba(15,23,42,.08);
}

*{ box-sizing:border-box; }

body{
  margin:0 !important;
  font-family:Inter,-apple-system,BlinkMacSystemFont,"Segoe UI",Arial,sans-serif !important;
  background:var(--wx-bg) !important;
  color:var(--wx-ink) !important;
}

.app,.layout,.admin-shell,.shell{
  display:grid !important;
  grid-template-columns:260px minmax(0,1fr) !important;
  min-height:100vh !important;
  background:transparent !important;
}

.side,.sidebar{
  position:sticky !important;
  top:0 !important;
  height:100vh !important;
  padding:18px 14px !important;
  background:#fff !important;
  border-right:1px solid var(--wx-line) !important;
  overflow:auto !important;
}

.side h1,.brand,.sidebar .brand{
  font-size:20px !important;
  line-height:1.1 !important;
  font-weight:900 !important;
  margin:0 0 18px !important;
  color:var(--wx-ink) !important;
  letter-spacing:-.03em !important;
}

.side p{
  margin:-8px 0 18px !important;
  font-size:12px !important;
  font-weight:800 !important;
  color:var(--wx-muted) !important;
}

.nav{ display:block !important; }

.side a,.nav a,.sidebar a{
  display:flex !important;
  align-items:center !important;
  gap:10px !important;
  min-height:42px !important;
  padding:11px 13px !important;
  margin:3px 0 !important;
  border-radius:12px !important;
  color:#334155 !important;
  text-decoration:none !important;
  font-size:14px !important;
  font-weight:750 !important;
  background:transparent !important;
  border:1px solid transparent !important;
}

.side a:hover,.nav a:hover,.sidebar a:hover{
  background:#f2f6ff !important;
  color:var(--wx-blue) !important;
}

.side a.active,.nav a.active,.sidebar a.active{
  background:#eaf2ff !important;
  color:var(--wx-blue) !important;
  border-color:#cfe0ff !important;
}

.main{
  padding:0 !important;
  overflow:auto !important;
  min-width:0 !important;
}

.main::before{
  content:"Reza Admin";
  position:sticky;
  top:0;
  z-index:20;
  display:flex;
  align-items:center;
  height:64px;
  padding:0 28px;
  background:rgba(255,255,255,.88);
  border-bottom:1px solid var(--wx-line);
  backdrop-filter:blur(16px);
  font-weight:900;
  color:var(--wx-ink);
}

.main > h1,.main .big,.top h1,.head h1,.title h1{
  font-size:34px !important;
  line-height:1.08 !important;
  letter-spacing:-.04em !important;
  color:var(--wx-ink) !important;
  margin:28px 28px 8px !important;
}

.top,.head,.title,.wx-admin-title{
  display:flex !important;
  justify-content:space-between !important;
  align-items:flex-start !important;
  gap:16px !important;
  padding:28px 28px 8px !important;
  margin:0 !important;
}

.top h1,.head h1,.title h1{ margin:0 !important; }

.top p,.head p,.title p{
  color:var(--wx-muted) !important;
  margin:6px 0 0 !important;
}

.card,.panel,.box,.wx-card{
  background:var(--wx-panel) !important;
  border:1px solid var(--wx-line) !important;
  border-radius:18px !important;
  box-shadow:var(--wx-shadow) !important;
  padding:22px !important;
  margin:20px 28px !important;
  max-width:none !important;
}

.grid,.form,.form-grid{
  display:grid !important;
  grid-template-columns:repeat(2,minmax(0,1fr)) !important;
  gap:14px !important;
}

.full,.wide{ grid-column:1/-1 !important; }

input,select,textarea,.input{
  width:100% !important;
  min-height:44px !important;
  padding:11px 13px !important;
  border:1px solid #cbd5e1 !important;
  border-radius:10px !important;
  background:#fff !important;
  color:var(--wx-ink) !important;
  font-size:15px !important;
  outline:none !important;
  box-shadow:none !important;
}

input:focus,select:focus,textarea:focus,.input:focus{
  border-color:var(--wx-blue) !important;
  box-shadow:0 0 0 3px rgba(17,109,255,.14) !important;
}

textarea{ min-height:110px !important; }

.btn,button,.icon-btn{
  border:0 !important;
  border-radius:999px !important;
  padding:11px 18px !important;
  min-height:42px !important;
  font-weight:850 !important;
  cursor:pointer !important;
  background:#eef2f7 !important;
  color:#1e293b !important;
  display:inline-flex !important;
  align-items:center !important;
  justify-content:center !important;
  gap:8px !important;
}

.primary,.btn.primary,.btn.blue,button.primary{
  background:var(--wx-blue) !important;
  color:white !important;
}

.danger{
  background:var(--wx-red) !important;
  color:white !important;
}

.ghost,.light{
  background:white !important;
  color:#1e293b !important;
  border:1px solid var(--wx-line) !important;
}

.toolbar,.tools{
  display:grid !important;
  grid-template-columns:220px minmax(240px,1fr) auto !important;
  gap:12px !important;
  align-items:center !important;
  margin-bottom:18px !important;
}

.tablewrap,.table-wrap{
  overflow:auto !important;
  border:1px solid var(--wx-line) !important;
  border-radius:16px !important;
  background:white !important;
}

table{
  width:100% !important;
  border-collapse:separate !important;
  border-spacing:0 !important;
  background:white !important;
  margin:0 !important;
}

th{
  background:#f8fafc !important;
  color:#475569 !important;
  font-size:12px !important;
  font-weight:900 !important;
  border-bottom:1px solid var(--wx-line) !important;
}

th,td{
  padding:14px 16px !important;
  text-align:left !important;
  vertical-align:middle !important;
  border-bottom:1px solid var(--wx-line) !important;
}

td{
  color:#1e293b !important;
  font-size:14px !important;
}

tr:hover td{
  background:#f8fbff !important;
}

.badge,.status,.pill{
  display:inline-flex !important;
  align-items:center !important;
  min-height:26px !important;
  padding:5px 10px !important;
  border-radius:999px !important;
  background:#ecfdf5 !important;
  color:#047857 !important;
  font-weight:900 !important;
  font-size:12px !important;
}

.preview,.thumb,.logoPreview{
  border-radius:14px !important;
  background:#f8fafc !important;
  border:1px solid var(--wx-line) !important;
  object-fit:cover !important;
}

.wx-mobile-bottom{ display:none; }

@media(max-width:900px){
  .app,.layout,.admin-shell,.shell{
    display:block !important;
  }

  .side,.sidebar{
    height:auto !important;
    position:sticky !important;
    top:0 !important;
    z-index:30 !important;
    padding:12px !important;
    border-right:0 !important;
    border-bottom:1px solid var(--wx-line) !important;
    overflow-x:auto !important;
    background:rgba(255,255,255,.94) !important;
    backdrop-filter:blur(14px);
  }

  .side h1,.brand{
    margin:0 0 10px !important;
  }

  .side p{ display:none !important; }

  .nav{
    display:flex !important;
    gap:8px !important;
    overflow-x:auto !important;
    white-space:nowrap !important;
  }

  .side a,.nav a,.sidebar a{
    display:inline-flex !important;
    margin:0 !important;
    min-height:38px !important;
    padding:9px 12px !important;
    font-size:13px !important;
  }

  .main::before{
    height:54px;
    padding:0 16px;
  }

  .main > h1,.main .big,.top h1,.head h1,.title h1{
    font-size:30px !important;
    margin:18px 16px 6px !important;
  }

  .top,.head,.title{
    display:grid !important;
    grid-template-columns:1fr !important;
    padding:18px 16px 4px !important;
  }

  .card,.panel,.box,.wx-card{
    margin:16px !important;
    padding:16px !important;
    border-radius:16px !important;
  }

  .grid,.form,.form-grid,.toolbar,.tools{
    grid-template-columns:1fr !important;
  }

  input,select,textarea,.input{
    font-size:16px !important;
  }

  .tablewrap,.table-wrap{
    overflow:visible !important;
    border:0 !important;
    background:transparent !important;
  }

  table,thead,tbody,tr,td{
    display:block !important;
    width:100% !important;
  }

  thead{ display:none !important; }

  tr{
    background:white !important;
    border:1px solid var(--wx-line) !important;
    border-radius:16px !important;
    box-shadow:0 12px 28px rgba(15,23,42,.07) !important;
    padding:10px !important;
    margin:0 0 12px !important;
  }

  td{
    display:grid !important;
    grid-template-columns:112px 1fr !important;
    gap:10px !important;
    border:0 !important;
    padding:8px 4px !important;
  }

  td::before{
    content:attr(data-label);
    color:var(--wx-muted);
    font-size:12px;
    font-weight:900;
  }

  .actions,.row-actions{
    display:grid !important;
    grid-template-columns:1fr 1fr !important;
    gap:8px !important;
  }

  .btn,button{ width:100%; }

  body{ padding-bottom:76px !important; }

  .wx-mobile-bottom{
    position:fixed;
    left:12px;
    right:12px;
    bottom:12px;
    z-index:10000;
    display:grid;
    grid-template-columns:repeat(4,1fr);
    gap:8px;
    padding:8px;
    background:rgba(255,255,255,.92);
    backdrop-filter:blur(18px);
    border:1px solid var(--wx-line);
    border-radius:22px;
    box-shadow:0 18px 50px rgba(15,23,42,.18);
  }

  .wx-mobile-bottom a{
    text-decoration:none;
    color:#475569;
    font-size:11px;
    font-weight:900;
    display:grid;
    place-items:center;
    gap:3px;
    padding:8px 4px;
    border-radius:16px;
  }

  .wx-mobile-bottom a.active{
    background:#eaf2ff;
    color:var(--wx-blue);
  }
}
CSS

cat > admin-wix-preview/js/admin-wix-preview.js <<'JS'
(function(){
  function addTableLabels(){
    document.querySelectorAll("table").forEach(table => {
      const headers = Array.from(table.querySelectorAll("thead th")).map(th => th.textContent.trim() || "Action");

      table.querySelectorAll("tbody tr").forEach(row => {
        Array.from(row.children).forEach((cell, index) => {
          if(!cell.getAttribute("data-label")){
            cell.setAttribute("data-label", headers[index] || "");
          }
        });
      });
    });
  }

  function addBottomNav(){
    if(document.querySelector(".wx-mobile-bottom")) return;

    const nav = document.createElement("nav");
    nav.className = "wx-mobile-bottom";
    nav.innerHTML = `
      <a href="dashboard.html">🏠<span>Home</span></a>
      <a href="orders.html">🧾<span>Orders</span></a>
      <a href="products.html">🛍️<span>Products</span></a>
      <a href="media.html">🖼️<span>Media</span></a>
    `;
    document.body.appendChild(nav);

    const page = location.pathname.split("/").pop();
    document.querySelectorAll(".wx-mobile-bottom a").forEach(a => {
      if(a.getAttribute("href") === page) a.classList.add("active");
    });
  }

  addTableLabels();
  addBottomNav();

  const obs = new MutationObserver(() => addTableLabels());
  obs.observe(document.body, { childList:true, subtree:true });
})();
JS

python3 - <<'PY'
from pathlib import Path

root = Path("admin-wix-preview")
files = list(root.glob("*.html")) + list((root / "advanced").glob("*.html"))

for f in files:
    text = f.read_text(errors="ignore")

    if "admin-wix-preview.css" not in text:
        css = '  <link rel="stylesheet" href="../css/admin-wix-preview.css?v=1">\n' if "/advanced/" in str(f) else '  <link rel="stylesheet" href="css/admin-wix-preview.css?v=1">\n'
        text = text.replace("</head>", css + "</head>")

    if "admin-wix-preview.js" not in text:
        js = '<script src="../js/admin-wix-preview.js?v=1"></script>\n' if "/advanced/" in str(f) else '<script src="js/admin-wix-preview.js?v=1"></script>\n'
        text = text.replace("</body>", js + "</body>")

    f.write_text(text)

print(f"Created Wix preview styling for {len(files)} pages.")
PY

echo ""
echo "== Done =="
echo "Offline preview folder created: admin-wix-preview"
echo ""
echo "Run:"
echo "python3 -m http.server 5173"
echo ""
echo "Open:"
echo "http://localhost:5173/admin-wix-preview/login.html"
echo "http://localhost:5173/admin-wix-preview/dashboard.html"
echo "http://localhost:5173/admin-wix-preview/orders.html"
echo "http://localhost:5173/admin-wix-preview/products.html"
