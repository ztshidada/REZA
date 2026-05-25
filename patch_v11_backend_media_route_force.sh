#!/bin/bash
set -e

echo "🔥 Forcing backend /api/media route before Route not found..."

python3 - <<'PY'
from pathlib import Path
import re

p = Path("backend/src/server.js")
text = p.read_text()

# Make sure fs/path are imported
if 'const fs = require("fs");' not in text and "const fs = require('fs');" not in text:
    text = 'const fs = require("fs");\n' + text

if 'const path = require("path");' not in text and "const path = require('path');" not in text:
    text = 'const path = require("path");\n' + text

# Increase JSON body limit for uploaded base64 images
text = text.replace("app.use(express.json());", 'app.use(express.json({ limit: "80mb" }));')
text = text.replace("app.use(express.urlencoded({ extended: true }));", 'app.use(express.urlencoded({ extended: true, limit: "80mb" }));')

media_code = r'''
// ================================
// REZA MEDIA ROUTES - FORCED LIVE
// ================================
const REZA_MEDIA_FILE_FINAL = path.join(__dirname, "../data/media.json");

function rezaDefaultMediaFinal() {
  return {
    heroImage: "assets/images/reza-soft-beauty-bg.svg",
    heroTitle: "Champagne Luxury",
    updatedAt: new Date().toISOString()
  };
}

function rezaReadMediaFinal() {
  try {
    fs.mkdirSync(path.dirname(REZA_MEDIA_FILE_FINAL), { recursive: true });

    if (!fs.existsSync(REZA_MEDIA_FILE_FINAL)) {
      const defaults = rezaDefaultMediaFinal();
      fs.writeFileSync(REZA_MEDIA_FILE_FINAL, JSON.stringify(defaults, null, 2));
      return defaults;
    }

    return JSON.parse(fs.readFileSync(REZA_MEDIA_FILE_FINAL, "utf8"));
  } catch (error) {
    return {
      ...rezaDefaultMediaFinal(),
      error: error.message
    };
  }
}

app.get("/api/media", (req, res) => {
  res.json({
    success: true,
    media: rezaReadMediaFinal()
  });
});

app.post("/api/media", (req, res) => {
  try {
    const current = rezaReadMediaFinal();

    const next = {
      ...current,
      heroImage: req.body.heroImage || current.heroImage,
      heroTitle: req.body.heroTitle || current.heroTitle || "Champagne Luxury",
      updatedAt: new Date().toISOString()
    };

    fs.mkdirSync(path.dirname(REZA_MEDIA_FILE_FINAL), { recursive: true });
    fs.writeFileSync(REZA_MEDIA_FILE_FINAL, JSON.stringify(next, null, 2));

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

# Remove old forced block if it exists
text = re.sub(
    r'\n// ================================\n// REZA MEDIA ROUTES - FORCED LIVE[\s\S]*?\n// END REZA MEDIA ROUTES - FORCED LIVE\n',
    '\n',
    text
)

media_code_wrapped = media_code + "\n// END REZA MEDIA ROUTES - FORCED LIVE\n"

# Put media routes BEFORE any route-not-found / 404 handler
markers = [
    'app.use((req, res) => res.status(404)',
    'app.use((req, res) => {',
    'app.get("*"',
    "app.get('*'",
    'app.listen('
]

inserted = False
for marker in markers:
    idx = text.find(marker)
    if idx != -1:
        text = text[:idx] + media_code_wrapped + "\n" + text[idx:]
        inserted = True
        break

if not inserted:
    text += "\n" + media_code_wrapped

p.write_text(text)
print("✅ /api/media route inserted before 404.")
PY

git add .
git commit -m "Force backend media route before 404 handler"
git push
