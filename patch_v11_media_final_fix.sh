#!/bin/bash
set -e

echo "🔥 Applying FINAL V11 media/homepage connection fix..."

# 1. Fix backend media API and CORS
python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

# make sure fs/path exist
if "const fs = require(\"fs\")" not in text and "const fs = require('fs')" not in text:
    text = "const fs = require(\"fs\");\n" + text

if "const path = require(\"path\")" not in text and "const path = require('path')" not in text:
    text = "const path = require(\"path\");\n" + text

# add open CORS early
cors_code = '''
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (req.method === "OPTIONS") return res.sendStatus(200);
  next();
});
'''

if 'Access-Control-Allow-Origin' not in text:
    marker = "app.use(express.json"
    idx = text.find(marker)
    if idx != -1:
        text = text[:idx] + cors_code + "\n" + text[idx:]
    else:
        # after app is created
        marker2 = "const app = express"
        idx2 = text.find(marker2)
        endline = text.find("\n", idx2)
        text = text[:endline+1] + cors_code + "\n" + text[endline+1:]

media_code = r'''
// ================================
// REZA MEDIA API - FINAL
// ================================
const rezaMediaFile = path.join(__dirname, "../data/media.json");

function getDefaultMedia() {
  return {
    heroImage: "assets/images/reza-soft-beauty-bg.svg",
    heroTitle: "Champagne Luxury",
    updatedAt: new Date().toISOString()
  };
}

function readRezaMedia() {
  try {
    fs.mkdirSync(path.dirname(rezaMediaFile), { recursive: true });

    if (!fs.existsSync(rezaMediaFile)) {
      const defaults = getDefaultMedia();
      fs.writeFileSync(rezaMediaFile, JSON.stringify(defaults, null, 2));
      return defaults;
    }

    const raw = fs.readFileSync(rezaMediaFile, "utf8");
    return JSON.parse(raw || "{}");
  } catch (error) {
    return getDefaultMedia();
  }
}

app.get("/api/media", (req, res) => {
  res.json({
    success: true,
    media: readRezaMedia()
  });
});

app.post("/api/media", express.json({ limit: "60mb" }), (req, res) => {
  try {
    const current = readRezaMedia();

    const next = {
      ...current,
      ...req.body,
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(rezaMediaFile), { recursive: true });
    fs.writeFileSync(rezaMediaFile, JSON.stringify(next, null, 2));

    res.json({
      success: true,
      message: "Media saved successfully",
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

# remove old duplicate media blocks by only adding if final marker missing
if "REZA MEDIA API - FINAL" not in text:
    marker = 'app.get("/api/health"'
    idx = text.find(marker)
    if idx != -1:
        text = text[:idx] + media_code + "\n\n" + text[idx:]
    else:
        text += "\n\n" + media_code

p.write_text(text)
print("✅ Backend media API fixed.")
PY

# 2. Rewrite admin media save script
cat > admin/js/media-fix.js <<'JS'
const MEDIA_API_BASE =
  location.hostname.includes("localhost")
    ? "http://localhost:10000"
    : "https://api.rezaholdings.co.za";

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error("Could not read file"));
    reader.readAsDataURL(file);
  });
}

document.addEventListener("DOMContentLoaded", () => {
  const saveButton = [...document.querySelectorAll("button")].find(btn =>
    btn.textContent.trim().toLowerCase() === "save"
  );

  const fileInput = document.querySelector('input[type="file"]');
  const titleInput = document.querySelector('input[type="text"]');

  if (!saveButton) {
    console.warn("Save button not found.");
    return;
  }

  saveButton.addEventListener("click", async (event) => {
    event.preventDefault();

    try {
      saveButton.disabled = true;
      saveButton.textContent = "Saving...";

      const payload = {
        heroTitle: titleInput ? titleInput.value.trim() : "Champagne Luxury"
      };

      if (fileInput && fileInput.files && fileInput.files[0]) {
        payload.heroImage = await readFileAsDataUrl(fileInput.files[0]);
      }

      const response = await fetch(MEDIA_API_BASE + "/api/media", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (!data.success) {
        alert(data.message || "Media save failed.");
        return;
      }

      alert("Saved successfully. Now hard refresh the homepage.");
    } catch (error) {
      console.error(error);
      alert("Media save failed. Open Console to see the error.");
    } finally {
      saveButton.disabled = false;
      saveButton.textContent = "Save";
    }
  });
});
JS

# 3. Make sure media-fix is loaded
python3 - <<'PY'
from pathlib import Path

p = Path("admin/media.html")
text = p.read_text()

if "js/media-fix.js" not in text:
    text = text.replace("</body>", '<script src="js/media-fix.js"></script>\n</body>')

p.write_text(text)
print("✅ Admin media-fix injected.")
PY

# 4. Frontend: apply saved image directly to hero
cat >> frontend/js/app.js <<'JS'

// ================================
// V11 FINAL - APPLY ADMIN HERO IMAGE
// ================================
(function(){
  const MEDIA_API_BASE =
    location.hostname.includes("localhost")
      ? "http://localhost:10000"
      : "https://api.rezaholdings.co.za";

  function normalizeHeroImage(src) {
    if (!src) return null;
    if (src.startsWith("data:image")) return src;
    if (src.startsWith("http")) return src;
    if (src.startsWith("/")) return MEDIA_API_BASE + src;
    return src;
  }

  async function applyAdminHeroImage() {
    try {
      const response = await fetch(MEDIA_API_BASE + "/api/media?t=" + Date.now());
      const data = await response.json();

      if (!data.success || !data.media) return;

      const heroImage = normalizeHeroImage(data.media.heroImage);

      if (!heroImage) return;

      document.querySelectorAll(".hero, .page-hero").forEach(section => {
        section.style.backgroundImage =
          `linear-gradient(90deg, rgba(255,250,242,.88), rgba(255,250,242,.58), rgba(255,250,242,.18)), url("${heroImage}")`;
        section.style.backgroundSize = "cover";
        section.style.backgroundPosition = "center";
      });

      console.log("✅ Reza admin hero image applied.");
    } catch (error) {
      console.warn("Could not load admin media image", error);
    }
  }

  document.addEventListener("DOMContentLoaded", applyAdminHeroImage);
})();
JS

git add .
git commit -m "Final fix admin media image connection to homepage"
git push

echo "✅ Patch pushed. Redeploy backend, admin, and frontend."
