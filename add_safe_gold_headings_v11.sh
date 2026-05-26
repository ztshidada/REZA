#!/bin/bash
set -e

echo "Adding safe mirror-gold headings to V11 only..."

mkdir -p frontend/assets/css

cat > frontend/assets/css/mirror-gold-headings.css <<'CSS'
/* Safe mirror-gold effect: headings only, no layout changes */

.mirror-gold-heading,
.hero-shopify h1,
.page-hero h1,
.section-title h2 {
  color: transparent !important;
  background: linear-gradient(
    115deg,
    #6b420c 0%,
    #b77a21 18%,
    #fff1bd 34%,
    #d8a13d 48%,
    #7a4a0f 62%,
    #f7d98e 78%,
    #a86b19 100%
  ) !important;
  background-size: 240% auto !important;
  -webkit-background-clip: text !important;
  background-clip: text !important;
  -webkit-text-fill-color: transparent !important;
  animation: rezaMirrorGold 8s linear infinite;
  text-shadow: none !important;
}

@keyframes rezaMirrorGold {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* Mobile-safe: no size/layout edits */
@media (max-width: 768px) {
  .mirror-gold-heading,
  .hero-shopify h1,
  .page-hero h1,
  .section-title h2 {
    background-size: 220% auto !important;
  }
}
CSS

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("frontend").glob("*.html"):
    text = p.read_text(encoding="utf-8")

    if "mirror-gold-headings.css" not in text:
        text = text.replace(
            "</head>",
            '  <link rel="stylesheet" href="assets/css/mirror-gold-headings.css">\n</head>'
        )

    def add_class(match):
        tag = match.group(0)
        if "mirror-gold-heading" in tag:
            return tag
        if 'class="' in tag:
            return re.sub(
                r'class="([^"]*)"',
                lambda m: f'class="{m.group(1)} mirror-gold-heading"',
                tag,
                count=1
            )
        return tag.replace("<h1", '<h1 class="mirror-gold-heading"', 1)

    text = re.sub(r"<h1\b[^>]*>", add_class, text)

    p.write_text(text, encoding="utf-8")
    print("Updated:", p)
PY

git add .
git commit -m "Add safe mirror gold headings to V11"
git push

echo "Done. Redeploy reza-frontend only."
