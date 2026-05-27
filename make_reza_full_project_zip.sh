#!/bin/bash
set -e

PROJECT_DIR="$(pwd)"
OUT="$HOME/Desktop/reza-v11-full-project-audit.zip"

rm -f "$OUT"

echo "Creating FULL Reza V11 project audit ZIP..."
echo "Including images, uploads, frontend, admin, backend, CSS, JS, HTML..."
echo "Excluding only node_modules, .git, .env, and logs."

zip -r "$OUT" . \
  -x "*/node_modules/*" \
  -x "node_modules/*" \
  -x "*/.git/*" \
  -x ".git/*" \
  -x "*/.env" \
  -x ".env" \
  -x "*.log" \
  -x "*/.DS_Store" \
  -x ".DS_Store"

echo ""
echo "DONE ✅"
echo "Full audit ZIP created here:"
echo "$OUT"
echo ""
echo "Upload this file to ChatGPT:"
echo "reza-v11-full-project-audit.zip"
