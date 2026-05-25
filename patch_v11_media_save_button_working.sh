#!/bin/bash
set -e

echo "🔧 Fixing Media Save button properly..."

# 1. Make backend media endpoint strong
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

if 'const fs = require("fs");' not in text and "const fs = require('fs');" not in text:
    text = 'const fs = require("fs");\n' + text

if 'const path = require("path");' not in text and "const path = require('path');" not in text:
    text = 'const path = require("path");\n' + text

media_code = r'''
// ================================
// WORKING REZA MEDIA API
// ================================
const rezaMediaPath = path.join(__dirname, "../data/media.json");

function readRezaMediaSafe() {
  try {
    fs.mkdirSync(path.dirname(rezaMediaPath), { recursive: true });
    if (!fs.existsSync(rezaMediaPath)) {
      const defaults = {
        heroImage: "assets/images/reza-soft-beauty-bg.svg",
        heroTitle: "Champagne Luxury",
        updatedAt: new Date().toISOString()
      };
      fs.writeFileSync(rezaMediaPath, JSON.stringify(defaults, null, 2));
      return defaults;
    }
    return JSON.parse(fs.readFileSync(rezaMediaPath, "utf8"));
  } catch (err) {
    return {
      heroImage: "assets/images/reza-soft-beauty-bg.svg",
      heroTitle: "Champagne Luxury",
      error: err.message
    };
  }
}

app.get("/api/media", (req, res) => {
  res.json({ success: true, media: readRezaMediaSafe() });
});

app.post("/api/media", express.json({ limit: "80mb" }), (req, res) => {
  try {
    const current = readRezaMediaSafe();
    const next = {
      ...current,
      heroImage: req.body.heroImage || current.heroImage,
      heroTitle: req.body.heroTitle || current.heroTitle || "Champagne Luxury",
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(rezaMediaPath), { recursive: true });
    fs.writeFileSync(rezaMediaPath, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media saved successfully",
      media: next
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message
    });
  }
});
'''

if "WORKING REZA MEDIA API" not in text:
    # Insert before common 404 handlers if found
    markers = [
        'app.use((req, res) =>',
        'app.get("*"',
        "app.get('*'",
        'app.listen('
    ]

    inserted = False
    for marker in markers:
        idx = text.find(marker)
        if idx != -1:
            text = text[:idx] + media_code + "\n\n" + text[idx:]
            inserted = True
            break

    if not inserted:
        text += "\n\n" + media_code + "\n"

p.write_text(text)
print("✅ Backend media API inserted/checked.")
PY

# 2. Replace Media page with working version
cat > admin/media.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Media | Reza Admin</title>
  <link rel="stylesheet" href="css/admin.css">
</head>
<body>
  <aside class="side">
    <h1>Reza <span>Admin</span></h1>
    <p>Champagne Luxury V11</p>
    <a href="dashboard.html">Dashboard</a>
    <a href="products.html">Products</a>
    <a class="active" href="media.html">Media</a>
    <a href="orders.html">Orders</a>
    <a href="https://rezaholdings.co.za" target="_blank">View Website</a>
    <a href="login.html">Logout</a>
  </aside>

  <main class="main">
    <div class="page-head">
      <div>
        <h1>Media</h1>
        <p>Change the homepage hero background image.</p>
      </div>
      <button id="saveMediaBtn" class="btn primary" type="button">Save</button>
    </div>

    <section class="card">
      <h2>Hero Background</h2>
      <p>Upload the image that must show on the homepage.</p>

      <img id="previewImage" src="" alt="Hero preview" style="width:100%;max-height:360px;object-fit:cover;border-radius:26px;margin:18px 0;background:#f4e4cf">

      <input id="heroFile" class="input" type="file" accept="image/*">
      <br><br>

      <input id="heroTitle" class="input" type="text" value="Champagne Luxury" placeholder="Hero title">

      <p id="mediaStatus" style="margin-top:16px;font-weight:900;color:#8a5b19"></p>

      <button id="testMediaBtn" class="btn ghost" type="button" style="margin-top:14px">Test API</button>
    </section>
  </main>

  <script>
    const API_BASE =
      location.hostname.includes("localhost")
        ? "http://localhost:10000"
        : "https://api.rezaholdings.co.za";

    const fileInput = document.getElementById("heroFile");
    const titleInput = document.getElementById("heroTitle");
    const saveBtn = document.getElementById("saveMediaBtn");
    const testBtn = document.getElementById("testMediaBtn");
    const preview = document.getElementById("previewImage");
    const statusEl = document.getElementById("mediaStatus");

    let selectedImageData = "";

    function setStatus(message) {
      statusEl.textContent = message;
    }

    function fileToDataUrl(file) {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = () => reject(new Error("Could not read image"));
        reader.readAsDataURL(file);
      });
    }

    async function loadCurrentMedia() {
      try {
        setStatus("Loading current media...");
        const res = await fetch(API_BASE + "/api/media?t=" + Date.now());
        const data = await res.json();

        if (data.success && data.media) {
          if (data.media.heroImage) {
            preview.src = data.media.heroImage.startsWith("data:image")
              ? data.media.heroImage
              : data.media.heroImage;
          }
          if (data.media.heroTitle) titleInput.value = data.media.heroTitle;
          setStatus("Ready.");
        } else {
          setStatus("Media API returned no data.");
        }
      } catch (err) {
        console.error(err);
        setStatus("Could not load media API.");
      }
    }

    fileInput.addEventListener("change", async () => {
      const file = fileInput.files && fileInput.files[0];
      if (!file) return;

      setStatus("Reading image...");
      selectedImageData = await fileToDataUrl(file);
      preview.src = selectedImageData;
      setStatus("Image ready. Click Save.");
    });

    saveBtn.addEventListener("click", async () => {
      try {
        saveBtn.disabled = true;
        saveBtn.textContent = "Saving...";
        setStatus("Saving to backend...");

        const payload = {
          heroTitle: titleInput.value.trim() || "Champagne Luxury"
        };

        if (selectedImageData) {
          payload.heroImage = selectedImageData;
        }

        const res = await fetch(API_BASE + "/api/media", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload)
        });

        const data = await res.json();

        if (!data.success) {
          setStatus(data.message || "Save failed.");
          alert(data.message || "Save failed.");
          return;
        }

        setStatus("Saved successfully. Now hard refresh the homepage.");
        alert("Saved successfully. Open the homepage and hard refresh.");
      } catch (err) {
        console.error(err);
        setStatus("Save failed. Check backend deploy or browser console.");
        alert("Save failed. Check backend deploy or browser console.");
      } finally {
        saveBtn.disabled = false;
        saveBtn.textContent = "Save";
      }
    });

    testBtn.addEventListener("click", async () => {
      try {
        setStatus("Testing API...");
        const res = await fetch(API_BASE + "/api/media?t=" + Date.now());
        const data = await res.json();
        console.log(data);
        alert("API works. Check console for response.");
        setStatus("API works.");
      } catch (err) {
        console.error(err);
        alert("API test failed.");
        setStatus("API test failed.");
      }
    });

    loadCurrentMedia();
  </script>
</body>
</html>
HTML

# 3. Make frontend apply media directly
cat >> frontend/js/app.js <<'JS'

// V11.5 - direct live homepage media loader
(function(){
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  async function applyLiveHeroBackground() {
    try {
      const res = await fetch(API_BASE + "/api/media?t=" + Date.now());
      const data = await res.json();
      if (!data.success || !data.media || !data.media.heroImage) return;

      const img = data.media.heroImage;

      document.querySelectorAll(".hero, .page-hero").forEach(el => {
        el.style.backgroundImage =
          `linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)), url("${img}")`;
        el.style.backgroundSize = "cover";
        el.style.backgroundPosition = "center";
      });
    } catch (err) {
      console.warn("Hero media not applied", err);
    }
  }

  document.addEventListener("DOMContentLoaded", applyLiveHeroBackground);
})();
JS

git add .
git commit -m "Make admin media save button work"
git push

echo "✅ Done. Redeploy backend, admin and frontend on Render."
