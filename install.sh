#!/bin/bash

# BytePays Theme Installer v3.2 (Stable + Production Ready)
# By VyzxStudios

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
API_URL="http://bot-1.hexgame.fun:25591/api"
PAYMENTER_PATH="/var/www/paymenter"
THEME_NAME="bytepays"
TEMP_DIR="/tmp/bytepays-install"

EMAIL=""
LICENSE_KEY=""
NON_INTERACTIVE=0
GENERATE_NEW=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --key)
            LICENSE_KEY="$2"
            shift 2
            ;;
        --generate)
            GENERATE_NEW=1
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=1
            shift
            ;;
        --api)
            API_URL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: sudo bash install.sh [OPTIONS]"
            echo "Options:"
            echo "  --email EMAIL        Your email address"
            echo "  --key KEY            Your license key"
            echo "  --generate           Generate new license"
            echo "  --api URL            API URL"
            echo "  --non-interactive    Run without prompts"
            echo "  --help               Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Banner
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║     🚀 BytePays Theme Installer v3.2                              ║"
echo "║     By VyzxStudios                                                ║"
echo "║                                                                   ║"
echo "║     Premium Paymenter Theme | Auto-build | Vite Ready             ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo -e "${YELLOW}   Please run: sudo bash install.sh${NC}"
    exit 1
fi

# ==================== STEP 1: FIX PACKAGES ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 1: Fixing package system...${NC}"

apt --fix-broken install -y >/dev/null 2>&1 || true
apt update -qq

echo -e "${GREEN}✅ Package system fixed${NC}"

# ==================== STEP 2: INSTALL BASIC DEPS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Step 2: Installing basic dependencies...${NC}"

apt install -y curl unzip git >/dev/null 2>&1

echo -e "${GREEN}✅ Basic dependencies installed${NC}"

# ==================== STEP 3: FIX NODE.JS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ Step 3: Setting up Node.js...${NC}"

# Remove conflicting packages
apt remove -y npm nodejs >/dev/null 2>&1 || true
apt autoremove -y >/dev/null 2>&1 || true

# Install Node.js from NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
apt install -y nodejs >/dev/null 2>&1

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo -e "${GREEN}✅ Node.js: $NODE_VERSION | npm: $NPM_VERSION${NC}"

# ==================== STEP 4: CHECK PAYMENTER ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 4: Checking Paymenter installation...${NC}"

if [ ! -d "$PAYMENTER_PATH" ]; then
    echo -e "${RED}❌ Paymenter not found at $PAYMENTER_PATH${NC}"
    echo -e "${YELLOW}   Please install Paymenter first: https://paymenter.org${NC}"
    exit 1
fi

if [ ! -f "$PAYMENTER_PATH/artisan" ]; then
    echo -e "${RED}❌ Paymenter installation appears incomplete${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Paymenter found at $PAYMENTER_PATH${NC}"

# Get Paymenter version
PAYMENTER_VERSION=$(cd $PAYMENTER_PATH && php artisan --version 2>/dev/null | grep -oP '[\d\.]+' | head -1)
echo -e "${GREEN}✅ Paymenter version: $PAYMENTER_VERSION${NC}"

# ==================== STEP 5: GET LICENSE DETAILS ====================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📝 License Details${NC}"
echo ""

# Get email
if [[ -z "$EMAIL" ]]; then
    if [ $NON_INTERACTIVE -eq 1 ]; then
        echo -e "${RED}❌ Email required in non-interactive mode${NC}"
        exit 1
    fi
    echo -e "${YELLOW}📧 Email address:${NC}"
    read -r EMAIL
fi

# Validate email
if [[ -z "$EMAIL" ]]; then
    echo -e "${RED}❌ Email is required${NC}"
    exit 1
fi

# Create temp directory
mkdir -p "$TEMP_DIR"

# Handle license key
if [[ -z "$LICENSE_KEY" ]]; then
    if [ $GENERATE_NEW -eq 1 ] || [ $NON_INTERACTIVE -eq 0 ]; then
        GENERATE_NEW=1
    fi
fi

# ==================== STEP 6: GENERATE LICENSE ====================
if [[ $GENERATE_NEW -eq 1 ]] && [[ -z "$LICENSE_KEY" ]]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔑 Step 5: Generating new license key...${NC}"
    
    response=$(curl -s -X POST "$API_URL/generate-free" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\"}")
    
    if echo "$response" | grep -q '"success":true'; then
        LICENSE_KEY=$(echo "$response" | grep -o '"licenseKey":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✅ License generated successfully!${NC}"
        echo -e "${CYAN}   Key: $LICENSE_KEY${NC}"
        echo -e "${YELLOW}   📧 Also sent to: $EMAIL${NC}"
    else
        echo -e "${RED}❌ Failed to generate license${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# If still no license key, ask for it
if [[ -z "$LICENSE_KEY" ]]; then
    echo -e "${YELLOW}🔑 Enter your license key:${NC}"
    read -r LICENSE_KEY
fi

if [[ -z "$LICENSE_KEY" ]]; then
    echo -e "${RED}❌ No license key provided${NC}"
    exit 1
fi

# ==================== STEP 7: VERIFY LICENSE ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 6: Verifying license...${NC}"

verify=$(curl -s -X POST "$API_URL/activate" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"key\":\"$LICENSE_KEY\"}")

if echo "$verify" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ License verified successfully${NC}"
else
    echo -e "${RED}❌ Invalid license key${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# ==================== STEP 8: DOWNLOAD THEME ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⬇️  Step 7: Downloading theme...${NC}"

curl -# -L -o "$TEMP_DIR/theme.zip" "$API_URL/download?key=$LICENSE_KEY"

if [ ! -f "$TEMP_DIR/theme.zip" ] || [ ! -s "$TEMP_DIR/theme.zip" ]; then
    echo -e "${RED}❌ Download failed${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

FILE_SIZE=$(du -h "$TEMP_DIR/theme.zip" | cut -f1)
echo -e "${GREEN}✅ Downloaded ($FILE_SIZE)${NC}"

# ==================== STEP 9: BACKUP EXISTING ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💾 Step 8: Backing up existing theme...${NC}"

if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    BACKUP_NAME="${THEME_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
    mv "$PAYMENTER_PATH/themes/$THEME_NAME" "$PAYMENTER_PATH/themes/$BACKUP_NAME"
    echo -e "${GREEN}✅ Backup created: $BACKUP_NAME${NC}"
fi

# ==================== STEP 10: EXTRACT THEME ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 9: Installing theme...${NC}"

mkdir -p "$PAYMENTER_PATH/themes"
unzip -q "$TEMP_DIR/theme.zip" -d "$PAYMENTER_PATH/themes/$THEME_NAME"

echo -e "${GREEN}✅ Theme extracted${NC}"

# ==================== STEP 11: BUILD THEME ASSETS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ Step 10: Building theme assets...${NC}"

cd "$PAYMENTER_PATH/themes/$THEME_NAME"

if [ -f "package.json" ]; then
    echo -e "${YELLOW}   Installing dependencies...${NC}"
    npm install --silent 2>/dev/null
    
    echo -e "${YELLOW}   Building...${NC}"
    npm run build --silent 2>/dev/null || true
fi

# ==================== STEP 12: COPY ASSETS TO PUBLIC ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 11: Moving assets to public...${NC}"

# Handle dist folder
if [ -d "dist" ]; then
    cp -r dist/* "$PAYMENTER_PATH/public/" 2>/dev/null || true
    echo -e "${GREEN}✅ dist assets copied${NC}"
fi

# Handle build folder
if [ -d "build" ]; then
    mkdir -p "$PAYMENTER_PATH/public/build"
    cp -r build/* "$PAYMENTER_PATH/public/build/" 2>/dev/null || true
    echo -e "${GREEN}✅ build assets copied${NC}"
fi

# Handle vite build output
if [ -d "public/build" ]; then
    mkdir -p "$PAYMENTER_PATH/public/build"
    cp -r public/build/* "$PAYMENTER_PATH/public/build/" 2>/dev/null || true
    echo -e "${GREEN}✅ vite assets copied${NC}"
fi

# ==================== STEP 13: BUILD MAIN PAYMENTER ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ Step 12: Building Paymenter assets...${NC}"

cd "$PAYMENTER_PATH"

if [ -f "package.json" ]; then
    echo -e "${YELLOW}   Installing dependencies...${NC}"
    npm install --silent 2>/dev/null
    
    echo -e "${YELLOW}   Building...${NC}"
    npm run build --silent 2>/dev/null || true
fi

# ==================== STEP 14: FIX PERMISSIONS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Step 13: Setting permissions...${NC}"

chown -R www-data:www-data "$PAYMENTER_PATH"
chmod -R 755 "$PAYMENTER_PATH"
chmod -R 775 "$PAYMENTER_PATH/storage" 2>/dev/null || true
chmod -R 775 "$PAYMENTER_PATH/bootstrap/cache" 2>/dev/null || true

echo -e "${GREEN}✅ Permissions set${NC}"

# ==================== STEP 15: REGISTER THEME IN PAYMENTER ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚙️  Step 14: Registering theme in Paymenter...${NC}"

# Set theme in database
cd "$PAYMENTER_PATH"

php artisan tinker --execute="
try {
    \$exists = \DB::table('settings')->where('key', 'theme')->exists();
    if (\$exists) {
        \DB::table('settings')->where('key', 'theme')->update(['value' => '$THEME_NAME']);
    } else {
        \DB::table('settings')->insert(['key' => 'theme', 'value' => '$THEME_NAME']);
    }
    echo 'Theme registered successfully\n';
} catch (Exception \$e) {
    echo 'Error: ' . \$e->getMessage() . '\n';
}
" 2>/dev/null || true

# ==================== STEP 16: CREATE MISSING VIEWS ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📄 Step 15: Ensuring views exist...${NC}"

# Create home view if missing
if [ ! -f "$PAYMENTER_PATH/resources/views/home.blade.php" ]; then
    echo -e "${YELLOW}   Creating home view...${NC}"
    cat > "$PAYMENTER_PATH/resources/views/home.blade.php" << 'EOF'
@extends('layouts.app')

@section('content')
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">{{ __('Dashboard') }}</div>
                <div class="card-body">
                    @if (session('status'))
                        <div class="alert alert-success" role="alert">
                            {{ session('status') }}
                        </div>
                    @endif
                    {{ __('You are logged in!') }}
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
EOF
    echo -e "${GREEN}✅ Home view created${NC}"
fi

# ==================== STEP 17: CLEAR CACHES ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧹 Step 16: Clearing caches...${NC}"

php artisan optimize:clear
php artisan view:clear
php artisan cache:clear
php artisan config:clear
php artisan route:clear

echo -e "${GREEN}✅ Caches cleared${NC}"

# ==================== STEP 18: VERIFY BUILD ====================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✅ Step 17: Verifying installation...${NC}"

# Check Vite manifest
if [ -f "$PAYMENTER_PATH/public/build/manifest.json" ]; then
    echo -e "${GREEN}✅ Vite manifest found${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Vite manifest not found${NC}"
    echo -e "${YELLOW}   Run 'npm run build' manually if theme doesn't work${NC}"
fi

# Check theme files
if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    FILE_COUNT=$(find "$PAYMENTER_PATH/themes/$THEME_NAME" -type f | wc -l)
    echo -e "${GREEN}✅ $FILE_COUNT theme files installed${NC}"
else
    echo -e "${RED}❌ Theme installation failed${NC}"
    exit 1
fi

# ==================== STEP 19: CLEANUP ====================
rm -rf "$TEMP_DIR"

# ==================== SUCCESS MESSAGE ====================
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║  🎉 INSTALLATION COMPLETE! 🎉                                     ║"
echo "║                                                                   ║"
echo "║  BytePays Theme installed successfully!                           ║"
echo "║                                                                   ║"
echo "║  📍 Location: $PAYMENTER_PATH/themes/$THEME_NAME                  ║"
echo "║  🔑 License: $LICENSE_KEY                                         ║"
echo "║                                                                   ║"
echo "║  🎨 Next Steps:                                                   ║"
echo "║     1. Login to Paymenter admin panel                             ║"
echo "║     2. Go to Settings → Theme                                     ║"
echo "║     3. Select 'BytePays Theme'                                    ║"
echo "║     4. Save changes                                               ║"
echo "║                                                                   ║"
echo "║  🔄 If theme doesn't appear, run:                                 ║"
echo "║     cd $PAYMENTER_PATH && php artisan config:clear                ║"
echo "║                                                                   ║"
echo "║  🚀 Your site is now running BytePays Theme!                      ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

exit 0
