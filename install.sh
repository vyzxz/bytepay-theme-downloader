#!/bin/bash

# BytePays Theme Installer
# VyzxStudios
# Version: 2.0.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
API_URL="bot-1.hexgame.fun:25591/api"  # CHANGE THIS TO YOUR DOMAIN
PAYMENTER_PATH="/var/www/paymenter"
THEME_NAME="bytepays"
TEMP_DIR="/tmp/bytepays-install"

# Banner
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║     🚀 BytePays Theme Installer v2.0.0                            ║"
echo "║     By VyzxStudios                                                ║"
echo "║                                                                   ║"
echo "║     Premium Paymenter Theme with Futuristic Design                ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo -e "${YELLOW}   Please run: sudo bash install.sh${NC}"
    exit 1
fi

# Check if Paymenter exists
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 1: Checking Paymenter installation...${NC}"

if [ ! -d "$PAYMENTER_PATH" ]; then
    echo -e "${RED}❌ Paymenter not found at $PAYMENTER_PATH${NC}"
    echo -e "${YELLOW}   Please make sure Paymenter is installed first.${NC}"
    echo -e "${YELLOW}   Expected location: $PAYMENTER_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Paymenter found at $PAYMENTER_PATH${NC}"

# Check Paymenter version
if [ -f "$PAYMENTER_PATH/artisan" ]; then
    PAYMENTER_VERSION=$(cd $PAYMENTER_PATH && php artisan --version 2>/dev/null | grep -oP '[\d\.]+' | head -1)
    echo -e "${GREEN}✅ Paymenter version: $PAYMENTER_VERSION${NC}"
fi

# Check for required tools
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Step 2: Checking required tools...${NC}"

TOOLS_MISSING=0
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}📦 Installing curl...${NC}"
    apt-get update && apt-get install -y curl
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install curl${NC}"
        TOOLS_MISSING=1
    fi
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}📦 Installing unzip...${NC}"
    apt-get install -y unzip
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to install unzip${NC}"
        TOOLS_MISSING=1
    fi
fi

if [ $TOOLS_MISSING -eq 1 ]; then
    echo -e "${RED}❌ Required tools could not be installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required tools are installed${NC}"

# Get user input
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}📝 Please enter your license details:${NC}"
echo ""
echo -e "${YELLOW}📧 Email address:${NC}"
read -r email

echo -e "${YELLOW}🔑 License key:${NC}"
read -r license_key

# Validate input
if [[ -z "$email" || -z "$license_key" ]]; then
    echo -e "${RED}❌ Email and license key are required${NC}"
    exit 1
fi

# Create temp directory
mkdir -p "$TEMP_DIR"

# Step 3: Verify license
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 3: Verifying license key...${NC}"
echo -e "${CYAN}   Email: $email${NC}"
echo -e "${CYAN}   License: $license_key${NC}"

response=$(curl -s -X POST "$API_URL/activate" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"key\":\"$license_key\"}")

if echo "$response" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ License verified successfully!${NC}"
else
    echo -e "${RED}❌ Invalid license key${NC}"
    echo -e "${YELLOW}   Response: $response${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 4: Download theme
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⬇️  Step 4: Downloading BytePays Theme...${NC}"

download_url="$API_URL/download?key=$license_key"
curl -# -L -o "$TEMP_DIR/theme.zip" "$download_url"

if [ -f "$TEMP_DIR/theme.zip" ] && [ -s "$TEMP_DIR/theme.zip" ]; then
    file_size=$(du -h "$TEMP_DIR/theme.zip" | cut -f1)
    echo -e "${GREEN}✅ Theme downloaded successfully (${file_size})${NC}"
else
    echo -e "${RED}❌ Failed to download theme${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 5: Validate theme package
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Step 5: Validating theme package...${NC}"

if unzip -t "$TEMP_DIR/theme.zip" &> /dev/null; then
    echo -e "${GREEN}✅ Theme package is valid${NC}"
else
    echo -e "${RED}❌ Theme package is corrupted${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 6: Backup existing theme
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💾 Step 6: Backing up existing theme...${NC}"

if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    backup_name="bytepays_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}   Existing theme found, creating backup...${NC}"
    mv "$PAYMENTER_PATH/themes/$THEME_NAME" "$PAYMENTER_PATH/themes/$backup_name"
    echo -e "${GREEN}✅ Backup created: $backup_name${NC}"
else
    echo -e "${GREEN}   No existing theme found${NC}"
fi

# Step 7: Extract theme
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 Step 7: Installing BytePays Theme...${NC}"

# Create themes directory if it doesn't exist
mkdir -p "$PAYMENTER_PATH/themes"

# Extract theme
unzip -q "$TEMP_DIR/theme.zip" -d "$PAYMENTER_PATH/themes/$THEME_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Theme extracted successfully${NC}"
else
    echo -e "${RED}❌ Failed to extract theme${NC}"
    # Restore backup if extraction failed
    if [ -d "$PAYMENTER_PATH/themes/$backup_name" ]; then
        mv "$PAYMENTER_PATH/themes/$backup_name" "$PAYMENTER_PATH/themes/$THEME_NAME"
        echo -e "${YELLOW}   Restored from backup${NC}"
    fi
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 8: Set permissions
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 Step 8: Setting permissions...${NC}"

# Detect web server user
if id "www-data" &>/dev/null; then
    WEB_USER="www-data"
elif id "nginx" &>/dev/null; then
    WEB_USER="nginx"
else
    WEB_USER="www-data"
fi

chown -R $WEB_USER:$WEB_USER "$PAYMENTER_PATH/themes/$THEME_NAME"
chmod -R 755 "$PAYMENTER_PATH/themes/$THEME_NAME"

echo -e "${GREEN}✅ Permissions set (owner: $WEB_USER)${NC}"

# Step 9: Verify installation
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}✅ Step 9: Verifying installation...${NC}"

if [ -d "$PAYMENTER_PATH/themes/$THEME_NAME" ]; then
    # Check for theme.json
    if [ -f "$PAYMENTER_PATH/themes/$THEME_NAME/theme.json" ]; then
        echo -e "${GREEN}✅ Theme configuration found${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: theme.json not found${NC}"
    fi
    
    # Count files
    file_count=$(find "$PAYMENTER_PATH/themes/$THEME_NAME" -type f | wc -l)
    echo -e "${GREEN}✅ $file_count files installed${NC}"
else
    echo -e "${RED}❌ Installation verification failed${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TEMP_DIR"

# Success message
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║  🎉 INSTALLATION COMPLETE! 🎉                                     ║"
echo "║                                                                   ║"
echo "║  BytePays Theme has been installed successfully!                  ║"
echo "║                                                                   ║"
echo "║  📍 Location: $PAYMENTER_PATH/themes/$THEME_NAME                  ║"
echo "║                                                                   ║"
echo "║  🎨 Next Steps:                                                   ║"
echo "║     1. Login to Paymenter admin panel                             ║"
echo "║     2. Go to Settings → Theme                                     ║"
echo "║     3. Select 'BytePays Theme'                                    ║"
echo "║     4. Save changes                                               ║"
echo "║                                                                   ║"
echo "║  🔄 Clear cache (optional):                                       ║"
echo "║     cd $PAYMENTER_PATH                                            ║"
echo "║     php artisan cache:clear                                       ║"
echo "║     php artisan view:clear                                        ║"
echo "║                                                                   ║"
echo "║  Thank you for choosing BytePays Theme!                           ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Ask to clear cache
echo ""
echo -e "${YELLOW}Would you like to clear Paymenter cache now? (y/n)${NC}"
read -r clear_cache

if [[ "$clear_cache" == "y" || "$clear_cache" == "Y" ]]; then
    echo -e "${BLUE}Clearing cache...${NC}"
    cd "$PAYMENTER_PATH"
    php artisan cache:clear
    php artisan view:clear
    php artisan config:clear
    echo -e "${GREEN}✅ Cache cleared!${NC}"
fi

echo ""
echo -e "${CYAN}🚀 Enjoy your new BytePays Theme!${NC}"
echo ""

exit 0
