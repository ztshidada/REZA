#!/usr/bin/env bash
set -e

echo "== Adding Testimony page + updating physical address =="

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "backup-before-testimony-$STAMP"
cp -R frontend "backup-before-testimony-$STAMP/frontend"

mkdir -p frontend/assets/images/testimonies

# Try to copy testimony images from Downloads if they exist.
# If nothing is found, the page will still work, but images must be added later.
find "$HOME/Downloads" -maxdepth 1 -type f \( \
  -iname "*WhatsApp Image 2026-05-29 at 12.30*.jpeg" -o \
  -iname "*WhatsApp Image 2026-05-29 at 12.31*.jpeg" -o \
  -iname "*PHOTO-2026-05-30-18-08-02*.jpg" \
\) -print0 2>/dev/null | while IFS= read -r -d '' img; do
  base="$(basename "$img")"
  safe="$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9._-')"
  cp "$img" "frontend/assets/images/testimonies/$safe"
done

cat > frontend/testimony.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Testimonies | Reza Holdings</title>
  <meta name="description" content="Real customer testimonies and product results from Reza Skincare." />
  <link rel="stylesheet" href="css/app.css" />
  <link rel="stylesheet" href="reza-style.css" />
  <style>
    :root{
      --rez-gold:#c89334;
      --rez-dark:#23160f;
      --rez-cream:#fff7ed;
      --rez-soft:#fffaf3;
      --rez-line:rgba(35,22,15,.12);
    }

    body{
      background:
        radial-gradient(circle at top left, rgba(200,147,52,.16), transparent 34%),
        linear-gradient(180deg,#fffaf3,#fff);
      color:var(--rez-dark);
    }

    .testimony-hero{
      padding:72px 18px 34px;
      text-align:center;
      max-width:1100px;
      margin:0 auto;
    }

    .testimony-kicker{
      display:inline-flex;
      padding:8px 14px;
      border-radius:999px;
      background:rgba(200,147,52,.14);
      color:#8a5b14;
      font-weight:900;
      letter-spacing:.08em;
      text-transform:uppercase;
      font-size:12px;
      margin-bottom:16px;
    }

    .testimony-hero h1{
      font-size:clamp(42px,8vw,88px);
      line-height:.9;
      margin:0;
      letter-spacing:-.06em;
    }

    .testimony-hero p{
      max-width:760px;
      margin:18px auto 0;
      color:rgba(35,22,15,.72);
      font-size:clamp(16px,2vw,20px);
      line-height:1.65;
    }

    .testimony-address{
      max-width:980px;
      margin:0 auto 26px;
      padding:0 18px;
    }

    .address-card{
      display:grid;
      grid-template-columns:1fr auto;
      gap:16px;
      align-items:center;
      background:#fff;
      border:1px solid var(--rez-line);
      border-radius:28px;
      padding:18px 20px;
      box-shadow:0 18px 50px rgba(35,22,15,.08);
    }

    .address-card strong{
      display:block;
      font-size:18px;
      margin-bottom:4px;
    }

    .address-card span{
      color:rgba(35,22,15,.68);
      font-weight:750;
    }

    .address-pill{
      border-radius:999px;
      padding:12px 18px;
      background:linear-gradient(135deg,#f5d36b,#c89334);
      color:#241812;
      font-weight:1000;
      white-space:nowrap;
    }

    .testimony-wrap{
      max-width:1180px;
      margin:0 auto;
      padding:20px 18px 80px;
    }

    .testimony-grid{
      display:grid;
      grid-template-columns:repeat(3,minmax(0,1fr));
      gap:18px;
    }

    .testimony-card{
      background:#fff;
      border:1px solid var(--rez-line);
      border-radius:28px;
      overflow:hidden;
      box-shadow:0 18px 50px rgba(35,22,15,.08);
      transition:.25s ease;
    }

    .testimony-card:hover{
      transform:translateY(-4px);
      box-shadow:0 26px 70px rgba(35,22,15,.13);
    }

    .testimony-card.featured{
      grid-column:span 2;
    }

    .testimony-card img{
      width:100%;
      height:330px;
      object-fit:cover;
      display:block;
      background:#f3eadc;
    }

    .testimony-card.featured img{
      height:460px;
    }

    .testimony-body{
      padding:18px;
    }

    .testimony-body h3{
      margin:0 0 8px;
      font-size:20px;
      letter-spacing:-.02em;
    }

    .testimony-body p{
      margin:0;
      color:rgba(35,22,15,.68);
      line-height:1.55;
      font-size:14px;
    }

    .disclaimer{
      margin:28px auto 0;
      max-width:980px;
      border:1px solid rgba(200,147,52,.22);
      background:rgba(255,247,237,.82);
      border-radius:24px;
      padding:16px 18px;
      color:rgba(35,22,15,.72);
      line-height:1.55;
      font-size:14px;
      text-align:center;
    }

    .empty-testimony{
      grid-column:1/-1;
      background:#fff;
      border:1px dashed rgba(35,22,15,.22);
      border-radius:28px;
      padding:28px;
      text-align:center;
      color:rgba(35,22,15,.68);
    }

    @media(max-width:900px){
      .testimony-grid{
        grid-template-columns:1fr;
      }

      .testimony-card.featured{
        grid-column:span 1;
      }

      .testimony-card img,
      .testimony-card.featured img{
        height:auto;
        max-height:none;
      }

      .address-card{
        grid-template-columns:1fr;
      }

      .address-pill{
        text-align:center;
      }
    }
  </style>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="index.html">REZA</a>
    <nav class="site-nav">
      <a href="index.html">Home</a>
      <a href="shop.html">Shop</a>
      <a href="testimony.html">Testimony</a>
      <a href="contact.html">Contact</a>
    </nav>
  </header>

  <main>
    <section class="testimony-hero">
      <div class="testimony-kicker">Real customer feedback</div>
      <h1>Testimony</h1>
      <p>
        See customer feedback and visible skincare journeys shared by Reza users.
        Results are personal and may differ from person to person.
      </p>
    </section>

    <section class="testimony-address">
      <div class="address-card">
        <div>
          <strong>Visit our physical store</strong>
          <span>Reza kiosk next to Shoprite</span>
        </div>
        <div class="address-pill">Reza Skincare</div>
      </div>
    </section>

    <section class="testimony-wrap">
      <div class="testimony-grid" id="testimonyGrid">
        <div class="empty-testimony">
          Testimony images will appear here. Add images inside
          <b>frontend/assets/images/testimonies/</b>.
        </div>
      </div>

      <div class="disclaimer">
        Customer testimonies are shared for product experience and marketing purposes.
        Reza products are cosmetic/wellness products and are not intended to diagnose,
        treat, cure, or prevent medical conditions.
      </div>
    </section>
  </main>

  <script>
    const testimonyImages = [
      "whatsapp-image-2026-05-29-at-12.30.31.jpeg",
      "whatsapp-image-2026-05-29-at-12.30.32-1.jpeg",
      "whatsapp-image-2026-05-29-at-12.30.32-2.jpeg",
      "whatsapp-image-2026-05-29-at-12.30.32-3.jpeg",
      "whatsapp-image-2026-05-29-at-12.30.32.jpeg",
      "whatsapp-image-2026-05-29-at-12.30.33.jpeg",
      "whatsapp-image-2026-05-29-at-12.31.30-1.jpeg",
      "whatsapp-image-2026-05-29-at-12.31.30-2.jpeg",
      "whatsapp-image-2026-05-29-at-12.31.30.jpeg",
      "photo-2026-05-30-18-08-02.jpg"
    ];

    const grid = document.getElementById("testimonyGrid");

    function makeCard(src, index){
      const card = document.createElement("article");
      card.className = "testimony-card" + (index === 0 ? " featured" : "");

      const img = document.createElement("img");
      img.src = "assets/images/testimonies/" + src;
      img.alt = "Reza customer testimony result";
      img.loading = "lazy";

      img.onerror = () => {
        card.remove();
        if(!grid.querySelector(".testimony-card")){
          grid.innerHTML = `
            <div class="empty-testimony">
              No testimony images found yet. Please add your images inside
              <b>frontend/assets/images/testimonies/</b>.
            </div>
          `;
        }
      };

      const body = document.createElement("div");
      body.className = "testimony-body";
      body.innerHTML = `
        <h3>Customer Testimony</h3>
        <p>Shared Reza Skincare product experience. Results may vary.</p>
      `;

      card.appendChild(img);
      card.appendChild(body);
      return card;
    }

    grid.innerHTML = "";
    testimonyImages.forEach((src, index) => grid.appendChild(makeCard(src, index)));
  </script>
</body>
</html>
HTML

python3 - <<'PY'
from pathlib import Path
import re

frontend = Path("frontend")

# Add Testimony link to navs where possible
for f in frontend.glob("*.html"):
    text = f.read_text(errors="ignore")
    if "testimony.html" not in text:
        # Insert after shop.html link if found
        text = re.sub(
            r'(<a[^>]+href=["\']shop\.html["\'][^>]*>.*?</a>)',
            r'\1\n      <a href="testimony.html">Testimony</a>',
            text,
            count=1,
            flags=re.I | re.S
        )
    f.write_text(text)

# Add/update physical address on contact page
contact = frontend / "contact.html"
if contact.exists():
    text = contact.read_text(errors="ignore")

    address_block = """
<section class="reza-location-update" style="max-width:1100px;margin:28px auto;padding:0 18px;">
  <div style="background:#fff;border:1px solid rgba(35,22,15,.12);border-radius:26px;padding:22px;box-shadow:0 18px 50px rgba(35,22,15,.08);">
    <h2 style="margin:0 0 8px;">Physical Address</h2>
    <p style="margin:0;font-size:18px;font-weight:800;">Reza kiosk next to Shoprite</p>
  </div>
</section>
"""

    if "reza-location-update" not in text:
        text = text.replace("</main>", address_block + "\n</main>") if "</main>" in text else text.replace("</body>", address_block + "\n</body>")
    else:
        text = re.sub(
            r'<section class="reza-location-update".*?</section>',
            address_block.strip(),
            text,
            flags=re.S
        )

    # Replace common old address text if present
    text = re.sub(r'Physical Address\s*</h2>\s*<p[^>]*>.*?</p>', 'Physical Address</h2>\n    <p style="margin:0;font-size:18px;font-weight:800;">Reza kiosk next to Shoprite</p>', text, flags=re.S)
    contact.write_text(text)

print("Testimony page created and address updated.")
PY

echo "== Done =="
echo "Now test:"
echo "python3 -m http.server 5173"
echo "Open: http://localhost:5173/frontend/testimony.html"
