#!/bin/bash

# BytePays Theme Installer
# VyzxStudios
# Version: 2.1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
API_URL="http://bot-1.hexgame.fun:25591/api"
PAYMENTER_PATH="/var/www/paymenter"
THEME_NAME="bytepays"
TEMP_DIR="/tmp/bytepays-install"

# Parse command line arguments
EMAIL=""
LICENSE_KEY=""
NON_INTERACTIVE=0
GENERATE_NEW=0

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
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --email EMAIL        Your email address"
            echo "  --key KEY            Your existing license key"
            echo "  --generate           Generate a new license key"
            echo "  --api URL            API URL (default: $API_URL)"
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

# Detect web server user
if id "www-data" &>/dev/null; then
    WEB_USER="www-data"
elif id "nginx" &>/dev/null; then
    WEB_USER="nginx"
else
    WEB_USER="www-data"
fi

# Banner
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║     🚀 BytePays Theme Installer v2.1.0                            ║"
echo "║     By VyzxStudios                                                ║"
echo "║                                                                   ║"
echo "║     Premium Paymenter Theme with Futuristic Design                ║"
echo "║     ✨ Auto-build | Permissions | Cache clear                     ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo -e "${YELLOW}   Please run: sudo bash install.sh${NC}"
    exit 1
fi

# Step 1: Fix package system and install dependencies
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 1: Setting up environment...${NC}"

# Fix any broken packages first
echo -e "${YELLOW}   Checking for broken packages...${NC}"
apt --fix-broken install -y -qq 2>/dev/null

# Install basic tools (NO NPM INSTALLATION HERE!)
echo -e "${YELLOW}   Installing basic tools...${NC}"
apt install -y curl unzip git -qq 2>/dev/null

# Handle Node.js properly
echo -e "${YELLOW}   Checking Node.js installation...${NC}"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}   Node.js already installed: $NODE_VERSION${NC}"
    
    # Check if npm works
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        echo -e "${GREEN}   npm already installed: $NPM_VERSION${NC}"
    else
        echo -e "${YELLOW}   npm not found, reinstalling Node.js...${NC}"
        apt remove -y nodejs npm 2>/dev/null
        apt autoremove -y 2>/dev/null
        NEED_NODE_INSTALL=1
    fi
else
    echo -e "${YELLOW}   Node.js not found, installing...${NC}"
    NEED_NODE_INSTALL=1
fi

# Install Node.js if needed
if [ $NEED_NODE_INSTALL -eq 1 ]; then
    echo -e "${YELLOW}   Installing Node.js 20.x (includes npm)...${NC}"
    
    # Remove any existing node/npm packages
    apt remove -y nodejs npm 2>/dev/null
    apt autoremove -y 2>/dev/null
    
    # Install from NodeSource (includes npm)
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs -qq 2>/dev/null
    
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        echo -e "${GREEN}   Node.js: $(node --version) | npm: $(npm --version)${NC}"
    else
        echo -e "${RED}   Failed to install Node.js/npm${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Environment ready${NC}"

# Step 2: Check Paymenter
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 2: Checking Paymenter installation...${NC}"

if [ ! -d "$PAYMENTER_PATH" ]; then
    echo -e "${RED}❌ Paymenter not found at $PAYMENTER_PATH${NC}"
    echo -e "${YELLOW}   Please install Paymenter first: https://paymenter.org${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Paymenter found at $PAYMENTER_PATH${NC}"

if [ -f "$PAYMENTER_PATH/artisan" ]; then
    PAYMENTER_VERSION=$(cd $PAYMENTER_PATH && php artisan --version 2>/dev/null | grep -oP '[\d\.]+' | head -1)
    echo -e "${GREEN}✅ Paymenter version: $PAYMENTER_VERSION${NC}"
fi

# Step 3: Get user input
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}📝 License Details:${NC}"
echo ""

# Get email
if [[ -n "$EMAIL" ]]; then
    echo -e "${GREEN}✅ Using email: $EMAIL${NC}"
else
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
NEED_GENERATION=0

if [[ -n "$LICENSE_KEY" ]]; then
    echo -e "${GREEN}✅ Using provided license key: $LICENSE_KEY${NC}"
elif [[ $GENERATE_NEW -eq 1 ]]; then
    NEED_GENERATION=1
elif [ $NON_INTERACTIVE -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}🔑 Do you have a license key? (y/n)${NC}"
    read -r has_key
    if [[ "$has_key" == "n" || "$has_key" == "N" ]]; then
        NEED_GENERATION=1
    else
        echo -e "${YELLOW}🔑 Enter your license key:${NC}"
        read -r LICENSE_KEY
    fi
fi

# Generate new license if needed
if [[ $NEED_GENERATION -eq 1 ]]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔑 Step 3: Generating new license key...${NC}"
    
    response=$(curl -s -X POST "$API_URL/generate-free" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$EMAIL\"}")
    
    if echo "$response" | grep -q '"success":true'; then
        LICENSE_KEY=$(echo "$response" | grep -o '"licenseKey":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✅ License generated!${NC}"
        echo -e "${CYAN}   Key: $LICENSE_KEY${NC}"
        echo -e "${YELLOW}   📧 Sent to: $EMAIL${NC}"
    else
        echo -e "${RED}❌ Failed to generate license${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

if [[ -z "$LICENSE_KEY" ]]; then
    echo -e "${RED}❌ No license key provided${NC}"
    exit 1
fi

# Step 4: Test API
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 4: Testing API connection...${NC}"

if curl -s --connect-timeout 5 "$API_URL/health" &> /dev/null; then
    echo -e "${GREEN}✅ API reachable${NC}"
else
    echo -e "${RED}❌ Cannot reach API at $API_URL${NC}"
    exit 1
fi

# Step 5: Verify license
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 5: Verifying license...${NC}"

response=$(curl -s -X POST "$API_URL/activate" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"key\":\"$LICENSE_KEY\"}")

if echo "$response" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ License verified!${NC}"
else
    echo -e "${RED}❌ Invalid license key${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 6: Download theme
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⬇️  Step 6: Downloading theme...${NC}"

curl -# -L -o "$TEMP_DIR/theme.zip" "$API_URL/download?key=$LICENSE_KEY"

if [ ! -s "$TEMP_DIR/theme.zip" ]; then
    echo -e "${RED}❌ Download failed${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "${GREEN}✅ Downloaded ($(du -h $TEMP_DIR/theme.zip | cut -f1))${NC}"

# Step 7: Validate package
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 7: Validating package...${NC}"

if unzip -t "$TEMP_DIR/theme.zip" &> /dev/null; then
    echo -e "${GREEN}✅ Package valid${NC}"
else
    echo -e "${RED}❌ Corrupted package${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 8: Backup existing
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💾 Step 8: Backing up...${NC}"

if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    backup_name="bytepays_backup_$(date +%Y%m%d_%H%M%S)"
    mv "$PAYMENTER_PATH/themes/$THEME_NAME" "$PAYMENTER_PATH/themes/$backup_name"
    echo -e "${GREEN}✅ Backup: $backup_name${NC}"
fi

# Step 9: Extract
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 9: Installing theme...${NC}"

mkdir -p "$PAYMENTER_PATH/themes"
unzip -q "$TEMP_DIR/theme.zip" -d "$PAYMENTER_PATH/themes/$THEME_NAME"
echo -e "${GREEN}✅ Extracted${NC}"

# Step 10: Fix permissions
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Step 10: Setting permissions...${NC}"

chown -R $WEB_USER:$WEB_USER "$PAYMENTER_PATH"
chmod -R 755 "$PAYMENTER_PATH"
chmod -R 775 "$PAYMENTER_PATH/storage" 2>/dev/null
chmod -R 775 "$PAYMENTER_PATH/bootstrap/cache" 2>/dev/null
echo -e "${GREEN}✅ Permissions set (owner: $WEB_USER)${NC}"

# Step 11: Build theme assets (CRITICAL!)
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ Step 11: Building theme assets...${NC}"

cd "$PAYMENTER_PATH"

# Check if theme has package.json
if [ -f "themes/$THEME_NAME/package.json" ]; then
    echo -e "${YELLOW}   Installing dependencies...${NC}"
    
    # Save current user for npm operations
    CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
    if [ -n "$CURRENT_USER" ]; then
        chown -R $CURRENT_USER:$CURRENT_USER "themes/$THEME_NAME"
    fi
    
    cd "themes/$THEME_NAME"
    npm install --silent 2>&1 | grep -v "added\|removed\|updated"
    
    if grep -q '"build"' package.json 2>/dev/null; then
        echo -e "${YELLOW}   Building...${NC}"
        npm run build --silent 2>&1 | grep -v "✓\|built"
    fi
    
    cd "$PAYMENTER_PATH"
    chown -R $WEB_USER:$WEB_USER "themes/$THEME_NAME"
    echo -e "${GREEN}✅ Theme built${NC}"
else
    echo -e "${YELLOW}   No package.json found, skipping build${NC}"
fi

# Step 12: Build main Paymenter assets
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ Step 12: Building main assets...${NC}"

cd "$PAYMENTER_PATH"

# Save current user for npm
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -n "$CURRENT_USER" ]; then
    chown -R $CURRENT_USER:$CURRENT_USER "$PAYMENTER_PATH"
fi

if [ -f "package.json" ]; then
    echo -e "${YELLOW}   Installing dependencies...${NC}"
    npm install --silent 2>&1 | grep -v "added\|removed\|updated"
    
    echo -e "${YELLOW}   Building...${NC}"
    npm run build --silent 2>&1 | grep -v "✓\|built"
fi

# Restore permissions
chown -R $WEB_USER:$WEB_USER "$PAYMENTER_PATH"
echo -e "${GREEN}✅ Main assets built${NC}"

# Step 13: Clear cache
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧹 Step 13: Clearing cache...${NC}"

cd "$PAYMENTER_PATH"
php artisan view:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
php artisan config:clear 2>/dev/null
php artisan optimize:clear 2>/dev/null

echo -e "${GREEN}✅ Cache cleared${NC}"

# Step 14: Verify
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✅ Step 14: Verifying installation...${NC}"

if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    file_count=$(find "$PAYMENTER_PATH/themes/$THEME_NAME" -type f | wc -l)
    echo -e "${GREEN}✅ $file_count files installed${NC}"
    
    # Check for manifest (Vite build output)
    if [ -f "$PAYMENTER_PATH/public/build/manifest.json" ]; then
        echo -e "${GREEN}✅ Vite manifest found${NC}"
    fi
else
    echo -e "${RED}❌ Installation failed${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

# Success!
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
echo "║     1. Login to Paymenter admin                                   ║"
echo "║     2. Settings → Theme                                           ║"
echo "║     3. Select 'BytePays Theme'                                    ║"
echo "║     4. Save changes                                               ║"
echo "║                                                                   ║"
echo "║  🚀 Your site is now running BytePays Theme!                      ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

exit 0
