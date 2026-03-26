#!/bin/bash

# BytePays Installer PRO v3.0
# Fully fixed: Node, npm, build, assets, fallback

set -e

API_URL="http://bot-1.hexgame.fun:25591/api"
PAYMENTER_PATH="/var/www/paymenter"
THEME_NAME="bytepays"
TEMP_DIR="/tmp/bytepays-install"

echo "🚀 BytePays Installer PRO"

# --- FIX BROKEN PACKAGES ---
apt --fix-broken install -y >/dev/null 2>&1 || true
apt update -qq

# --- BASIC DEPENDENCIES ---
apt install -y curl unzip git >/dev/null

# --- NODE FIX (CRITICAL) ---
echo "⚡ Fixing Node environment..."

apt remove -y npm nodejs >/dev/null 2>&1 || true
apt autoremove -y >/dev/null 2>&1 || true

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs >/dev/null

echo "Node: $(node -v)"
echo "NPM: $(npm -v)"

# --- CHECK PAYMENTER ---
if [ ! -d "$PAYMENTER_PATH" ]; then
    echo "❌ Paymenter not found"
    exit 1
fi

# --- DOWNLOAD THEME ---
mkdir -p $TEMP_DIR
curl -L -o $TEMP_DIR/theme.zip "$API_URL/download?key=YOUR_KEY"

unzip -q $TEMP_DIR/theme.zip -d $PAYMENTER_PATH/themes/$THEME_NAME

# --- FIX PERMISSIONS ---
chown -R www-data:www-data $PAYMENTER_PATH
chmod -R 755 $PAYMENTER_PATH

# --- BUILD THEME ---
echo "⚡ Building theme..."

cd $PAYMENTER_PATH/themes/$THEME_NAME

if [ -f "package.json" ]; then
    npm install
    npm run build
fi

# --- 🔥 IMPORTANT: MOVE ASSETS TO ROOT ---
echo "📦 Moving assets..."

# Copy build output to public
if [ -d "dist" ]; then
    cp -r dist/* $PAYMENTER_PATH/public/
fi

if [ -d "build" ]; then
    cp -r build/* $PAYMENTER_PATH/public/build/
fi

# If vite build inside theme
if [ -f "vite.config.js" ]; then
    mkdir -p $PAYMENTER_PATH/public/build
    cp -r public/build/* $PAYMENTER_PATH/public/build/ 2>/dev/null || true
fi

# --- BUILD MAIN PROJECT ---
echo "⚡ Building main Paymenter..."

cd $PAYMENTER_PATH

if [ -f "package.json" ]; then
    npm install
    npm run build
fi

# --- FIX VIEWS ISSUE ---
echo "🧠 Fixing view fallback..."

# If home view missing, fallback to default
if [ ! -f "$PAYMENTER_PATH/resources/views/home.blade.php" ]; then
    cp $PAYMENTER_PATH/themes/default/views/home.blade.php \
       $PAYMENTER_PATH/resources/views/home.blade.php 2>/dev/null || true
fi

# --- CLEAR CACHE ---
php artisan optimize:clear

# --- FINAL CHECK ---
if [ ! -f "$PAYMENTER_PATH/public/build/manifest.json" ]; then
    echo "❌ Vite build missing"
    exit 1
fi

echo "✅ INSTALL COMPLETE"
