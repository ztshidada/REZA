#!/bin/bash
set -e

python3 - <<'PY'
from pathlib import Path

p = Path("backend/src/server.js")
text = p.read_text()

debug_route = r'''
app.get("/api/debug/yoco-key", (req, res) => {
  const key = process.env.YOCO_SECRET_KEY || process.env.YOCO_LIVE_SECRET_KEY || "";
  res.json({
    success: true,
    present: Boolean(key),
    prefix: key ? key.slice(0, 12) : "",
    length: key.length,
    startsWithSkLive: key.startsWith("sk_live_"),
    startsWithYocoLive: key.startsWith("yoco_live_"),
    startsWithSkTest: key.startsWith("sk_test_"),
    startsWithYocoTest: key.startsWith("yoco_test_")
  });
});
'''

if "/api/debug/yoco-key" not in text:
    marker = 'app.use("/api/payments", paymentRoutes);'
    if marker in text:
        text = text.replace(marker, debug_route + "\n\n" + marker, 1)
    else:
        text += "\n\n" + debug_route

p.write_text(text)
PY

git add .
git commit -m "Add safe Yoco key prefix diagnostic"
git push
