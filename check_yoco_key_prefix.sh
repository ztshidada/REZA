#!/bin/bash
set -e

echo "This checks only the prefix locally if you have backend/.env."
echo "It will NOT print the full key."

if [ -f backend/.env ]; then
  KEY=$(grep -E "^YOCO_SECRET_KEY=" backend/.env | cut -d= -f2- | tr -d '"' | tr -d "'")
  echo "Local YOCO_SECRET_KEY prefix:"
  echo "$KEY" | cut -c1-12
  echo "Length:"
  echo -n "$KEY" | wc -c
else
  echo "No backend/.env found locally."
fi
