#!/bin/bash
set -e
echo "✨ Installing Reza V11 Champagne Luxury..."
cd backend
npm install
cd ..
echo ""
echo "✅ Setup complete."
echo ""
echo "Run in 3 terminals:"
echo "1) cd ~/Downloads/reza-v11-champagne-luxury/backend && npm start"
echo "2) cd ~/Downloads/reza-v11-champagne-luxury/frontend && python3 -m http.server 5173"
echo "3) cd ~/Downloads/reza-v11-champagne-luxury/admin && python3 -m http.server 5174"
echo ""
echo "Customer: http://localhost:5173"
echo "Admin: http://localhost:5174/login.html"
echo "API: http://localhost:10000/api/health"
