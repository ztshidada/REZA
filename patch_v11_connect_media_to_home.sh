#!/bin/bash
set -e

echo "🔗 Connecting Admin Media background to frontend homepage..."

# 1. Make sure backend has media API routes
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

media_code = r'''
// ================================
// REZA MEDIA SETTINGS API
// ================================
const mediaFile = path.join(__dirname, "../data/media.json");

function readMediaSettings() {
  try {
    if (!fs.existsSync(mediaFile)) {
      return {
        heroImage: "assets/images/reza-soft-beauty-bg.svg",
        heroTitle: "Champagne Luxury"
      };
    }
    return JSON.parse(fs.readFileSync(mediaFile, "utf8"));
  } catch (error) {
    return {
      heroImage: "assets/images/reza-soft-beauty-bg.svg",
      heroTitle: "Champagne Luxury"
    };
  }
}

app.get("/api/media", (req, res) => {
  res.json({
    success: true,
    media: readMediaSettings()
  });
});

app.post("/api/media", express.json({ limit: "25mb" }), (req, res) => {
  try {
    const current = readMediaSettings();
    const next = {
      ...current,
      ...req.body,
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(mediaFile), { recursive: true });
    fs.writeFileSync(mediaFile, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media settings saved",
      media: next
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});
'''

if 'app.get("/api/media"' not in text:
    marker = 'app.get("/api/health"'
    idx = text.find(marker)
    if idx != -1:
      text = text[:idx] + media_code + "\n\n" + text[idx:]
    else:
      text += "\n\n" + media_code

p.write_text(text)
print("✅ Backend media API checked.")
PY

# 2. Force frontend CSS to use dynamic CSS variable
cat >> frontend/css/app.css <<'CSS'

/* V11.4 — Dynamic admin-controlled homepage background */
:root {
  --reza-live-hero-bg: url("../assets/images/reza-soft-beauty-bg.svg");
}

.hero {
  background:
    linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)),
    var(--reza-live-hero-bg) !important;
  background-size: cover !important;
  background-position: center !important;
}

.page-hero {
  background:
    linear-gradient(135deg, rgba(255,250,242,.78), rgba(243,223,206,.56)),
    var(--reza-live-hero-bg) !important;
  background-size: cover !important;
  background-position: center !important;
}

CSS

# 3. Make frontend fetch saved media from live API
cat >> frontend/js/app.js <<'JS'

// ================================
// V11.4 — LOAD ADMIN MEDIA ON FRONTEND
// ================================
(function(){
  const API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function normaliseImage(src){
    if(!src) return null;
    if(src.startsWith("data:image")) return src;
    if(src.startsWith("http")) return src;
    if(src.startsWith("/")) return API_BASE + src;
    return src;
  }

  async function loadLiveMedia(){
    try {
      const res = await fetch(API_BASE + "/api/media?time=" + Date.now());
      const data = await res.json();
      const media = data.media || data;

      const hero = normaliseImage(media.heroImage || media.heroBackground || media.backgroundImage);

      if(hero){
        document.documentElement.style.setProperty("--reza-live-hero-bg", `url("${hero}")`);
      }

      if(media.heroTitle){
        document.documentElement.style.setProperty("--reza-hero-title", `"${media.heroTitle}"`);
      }
    } catch (error) {
      console.warn("Could not load live media settings", error);
    }
  }

  document.addEventListener("DOMContentLoaded", loadLiveMedia);
})();
JS

# 4. Make admin media page definitely save to backend
cat > admin/js/media-fix.js <<'JS'
const API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

function fileToDataUrl(file){
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const saveBtn = [...document.querySelectorAll("button")].find(btn =>
    btn.textContent.trim().toLowerCase() === "save"
  );

  const fileInput = document.querySelector('input[type="file"]');
  const titleInput = document.querySelector('input[type="text"]');

  if(!saveBtn || !fileInput) return;

  saveBtn.addEventListener("click", async (event) => {
    event.preventDefault();

    try {
      saveBtn.textContent = "Saving...";

      let heroImage = null;
      if(fileInput.files && fileInput.files[0]){
        heroImage = await fileToDataUrl(fileInput.files[0]);
      }

      const payload = {
        heroTitle: titleInput ? titleInput.value : "Champagne Luxury"
      };

      if(heroImage){
        payload.heroImage = heroImage;
      }

      const res = await fetch(API_BASE + "/api/media", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const data = await res.json();

      if(!data.success){
        alert(data.message || "Could not save media.");
        saveBtn.textContent = "Save";
        return;
      }

      alert("Media saved. Refresh the customer homepage.");
      saveBtn.textContent = "Save";
    } catch (error) {
      console.error(error);
      alert("Could not connect to backend API.");
      saveBtn.textContent = "Save";
    }
  });
});
JS

# 5. Inject media-fix.js into media.html if missing
python3 - <<'PY'
from pathlib import Path

p = Path("admin/media.html")
text = p.read_text()

if 'js/media-fix.js' not in text:
    text = text.replace("</body>", '  <script src="js/media-fix.js"></script>\n</body>')

p.write_text(text)
print("✅ Admin media save fix injected.")
PY

git add .
git commit -m "Connect admin media background to frontend homepage"
git push

echo "✅ Done. Redeploy backend, admin, and frontend."
