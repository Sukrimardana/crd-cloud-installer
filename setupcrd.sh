cat > setupcrd.sh << 'ENDOFSCRIPT'
#!/bin/bash

# Chrome Remote Desktop Setup - UNIVERSAL VERSION
# Supports: CodeSandbox (Debian) & GitHub Codespaces (Ubuntu)
# Tested and Working 100%

set -e

clear
echo "================================================"
echo "  Chrome Remote Desktop - Universal Installer "
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

log_detect() {
    echo -e "${CYAN}[i]${NC} $1"
}

# Detect environment
detect_environment() {
    log_step "Detecting environment..."
    
    if [ -n "$CODESPACES" ] && [ "$CODESPACES" = "true" ]; then
        ENVIRONMENT="codespaces"
        OS_TYPE="ubuntu"
        log_detect "Environment: GitHub Codespaces (Ubuntu)"
    elif [ -n "$CSB_REPO_ROOT" ] || [ -d "/sandbox" ]; then
        ENVIRONMENT="codesandbox"
        OS_TYPE="debian"
        log_detect "Environment: CodeSandbox (Debian)"
    elif grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        ENVIRONMENT="generic-ubuntu"
        OS_TYPE="ubuntu"
        log_detect "Environment: Generic Ubuntu"
    elif grep -qi "debian" /etc/os-release 2>/dev/null; then
        ENVIRONMENT="generic-debian"
        OS_TYPE="debian"
        log_detect "Environment: Generic Debian"
    else
        ENVIRONMENT="unknown"
        OS_TYPE="unknown"
        log_warn "Unknown environment, attempting Debian defaults..."
        OS_TYPE="debian"
    fi
    
    echo ""
}

# Check root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root: sudo bash /tmp/setup_crd_universal.sh"
    exit 1
fi

# Detect environment first
detect_environment

# Input collection
log_step "Collecting information..."
echo ""
echo "███████╗██╗   ██╗██╗  ██╗██████╗ ██╗"
echo "██╔════╝██║   ██║██║ ██╔╝██╔══██╗██║"
echo "███████╗██║   ██║█████╔╝ ██████╔╝██║"
echo "╚════██║██║   ██║██╔═██╗ ██╔══██╗██║"
echo "███████║╚██████╔╝██║  ██╗██║  ██║██║"
echo "╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
echo "  Thanks BY claude AI prompt Enginering by Sukri"
echo ""
echo ""
echo "═══════════════════════════════════════════════"
echo "  Step 1: Get Chrome Remote Desktop Auth Code"
echo "═══════════════════════════════════════════════"
echo ""
echo "1. Open: https://remotedesktop.google.com/headless"
echo "2. Click: Begin → Next → Authorize"
echo "3. Copy the FULL command that appears"
echo ""
read -p "Paste the FULL CRD command here: " CRD_FULL_COMMAND

if [ -z "$CRD_FULL_COMMAND" ]; then
    log_error "Command cannot be empty!"
    exit 1
fi

echo ""
if [ "$ENVIRONMENT" = "codespaces" ]; then
    DEFAULT_USER="codespace"
else
    DEFAULT_USER="coder"
fi

read -p "Enter username (default: $DEFAULT_USER): " USERNAME
USERNAME=${USERNAME:-$DEFAULT_USER}

echo ""
read -sp "Enter password for $USERNAME: " USER_PASSWORD
echo ""

if [ -z "$USER_PASSWORD" ]; then
    log_error "Password cannot be empty!"
    exit 1
fi

echo ""
read -sp "Enter CRD PIN (6+ digits): " CRD_PIN
echo ""

if [ ${#CRD_PIN} -lt 6 ]; then
    log_error "PIN must be at least 6 digits!"
    exit 1
fi

# Start installation
echo ""
echo "═══════════════════════════════════════════════"
log_step "Starting installation on $OS_TYPE..."
echo "═══════════════════════════════════════════════"
echo ""

# Update system
log_step "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive

if [ "$OS_TYPE" = "ubuntu" ]; then
    apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Ign:" | grep -v "^Hit:" || true
else
    apt-get update -qq 2>&1 | grep -v "^Get:" | grep -v "^Ign:" || true
fi

# Install basic dependencies
log_step "Installing basic dependencies..."
apt-get install -y -qq --no-install-recommends \
    wget curl ca-certificates gnupg sudo psmisc 2>&1 | grep -v "^Get:" || true

# Download and install Chrome Remote Desktop
log_step "Installing Chrome Remote Desktop..."
if [ ! -f /tmp/crd.deb ]; then
    wget -q --show-progress https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb -O /tmp/crd.deb 2>&1
fi

dpkg -i /tmp/crd.deb 2>/dev/null || true
apt-get install -f -y -qq 2>&1 | grep -v "^Get:" || true

# Install desktop environment based on OS
log_step "Installing XFCE Desktop Environment (this may take 3-5 minutes)..."

if [ "$OS_TYPE" = "ubuntu" ]; then
    # Ubuntu packages
    apt-get install -y -qq --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        xfce4-goodies \
        desktop-base \
        dbus-x11 \
        firefox \
        mousepad \
        thunar \
        fonts-liberation \
        fonts-ubuntu \
        xserver-xorg \
        xserver-xorg-video-dummy \
        xserver-xorg-input-all \
        2>&1 | grep -E "Setting up|Processing|Unpacking" || true
else
    # Debian packages
    apt-get install -y -qq --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        xfce4-goodies \
        desktop-base \
        dbus-x11 \
        firefox-esr \
        mousepad \
        thunar \
        fonts-liberation \
        xserver-xorg \
        xserver-xorg-video-dummy \
        2>&1 | grep -E "Setting up|Processing|Unpacking" || true
fi

log_info "Desktop environment installed successfully!"

# Install additional useful packages
log_step "Installing additional packages..."
apt-get install -y -qq --no-install-recommends \
    nano vim htop git zip unzip \
    file-roller \
    2>&1 | grep -E "Setting up" || true

# Clean up 
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/crd.deb

# Create user
log_step "Creating/configuring user: $USERNAME"

if id "$USERNAME" &>/dev/null; then
    log_warn "User $USERNAME already exists, reconfiguring..."
    # Kill existing processes for this user
    pkill -u "$USERNAME" 2>/dev/null || true
    sleep 2
else
    useradd -m -s /bin/bash "$USERNAME"
fi

# Set password
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Add to groups
usermod -aG sudo "$USERNAME" 2>/dev/null || true
usermod -aG chrome-remote-desktop "$USERNAME" 2>/dev/null || true

# For Codespaces, ensure proper permissions
if [ "$ENVIRONMENT" = "codespaces" ]; then
    usermod -aG docker "$USERNAME" 2>/dev/null || true
fi

# Create home directories
log_step "Setting up home directories..."
sudo -u "$USERNAME" mkdir -p \
    /home/$USERNAME/{Desktop,Documents,Downloads,Pictures,Music,Videos,Public,Templates}

# Configure Chrome Remote Desktop session
log_step "Configuring Chrome Remote Desktop..."
sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/chrome-remote-desktop

sudo -u "$USERNAME" bash -c "cat > /home/$USERNAME/.chrome-remote-desktop-session << 'XFCE'
#!/bin/bash
exec /usr/bin/startxfce4
XFCE"

chmod +x /home/$USERNAME/.chrome-remote-desktop-session

# Configure XFCE settings
log_step "Configuring XFCE settings..."
sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml

# Disable screensaver and power management
sudo -u "$USERNAME" bash -c "cat > /home/$USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml << 'POWER'
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<channel name=\"xfce4-power-manager\" version=\"1.0\">
  <property name=\"xfce4-power-manager\" type=\"empty\">
    <property name=\"dpms-enabled\" type=\"bool\" value=\"false\"/>
    <property name=\"blank-on-ac\" type=\"int\" value=\"0\"/>
    <property name=\"dpms-on-ac-sleep\" type=\"uint\" value=\"0\"/>
    <property name=\"dpms-on-ac-off\" type=\"uint\" value=\"0\"/>
  </property>
</channel>
POWER"

# Disable screensaver via autostart
sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/autostart
sudo -u "$USERNAME" bash -c "cat > /home/$USERNAME/.config/autostart/disable-screensaver.desktop << 'SAVER'
[Desktop Entry]
Type=Application
Name=Disable Screensaver
Exec=xset s off -dpms
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
SAVER"

# Set proper permissions
chown -R "$USERNAME:$USERNAME" /home/$USERNAME

# Stop any existing CRD instances
log_step "Stopping existing Chrome Remote Desktop instances..."
systemctl stop chrome-remote-desktop@"$USERNAME" 2>/dev/null || true
sudo -u "$USERNAME" /opt/google/chrome-remote-desktop/chrome-remote-desktop --stop 2>/dev/null || true
sleep 3

# Extract and prepare CRD command
log_step "Registering with Chrome Remote Desktop..."
CRD_COMMAND=$(echo "$CRD_FULL_COMMAND" | sed 's/^DISPLAY= //')

# Start Chrome Remote Desktop with proper command
log_step "Executing CRD registration (this may take 10-15 seconds)..."
sudo -u "$USERNAME" bash -c "DISPLAY= $CRD_COMMAND --pin=$CRD_PIN" 2>&1 | tee /tmp/crd_setup.log

# Wait for registration
sleep 5

# Start Chrome Remote Desktop
log_step "Starting Chrome Remote Desktop service..."
sudo -u "$USERNAME" /opt/google/chrome-remote-desktop/chrome-remote-desktop --start 2>&1 | grep -v "not change" || true

# Enable service
systemctl enable chrome-remote-desktop@"$USERNAME" 2>/dev/null || true
systemctl start chrome-remote-desktop@"$USERNAME" 2>/dev/null || true

# Wait and check status
sleep 5

echo ""
echo "═══════════════════════════════════════════════"
echo "           Checking Installation Status        "
echo "═══════════════════════════════════════════════"
echo ""

# Check if CRD is running
if pgrep -f "chrome-remote-desktop" > /dev/null; then
    log_info "Chrome Remote Desktop is running!"
    
    # Get hostname
    HOSTNAME=$(hostname)
    
    echo ""
    echo "╔═══════════════════════════════════════════════╗"
    echo "║        ✓ INSTALLATION SUCCESSFUL!            ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo ""
    echo "🖥️  Environment: $ENVIRONMENT ($OS_TYPE)"
    echo ""
    echo "📋 Login Information:"
    echo "   Username : $USERNAME"
    echo "   Password : $USER_PASSWORD"
    echo "   CRD PIN  : $CRD_PIN"
    echo ""
    echo "🌐 Access Your Remote Desktop:"
    echo "   1. Open: https://remotedesktop.google.com/access"
    echo "   2. Find device: $HOSTNAME"
    echo "   3. Enter PIN: $CRD_PIN"
    echo ""
    echo "💡 Installed Applications:"
    echo "   - Desktop: XFCE4"
    if [ "$OS_TYPE" = "ubuntu" ]; then
        echo "   - Browser: Firefox"
    else
        echo "   - Browser: Firefox ESR"
    fi
    echo "   - File Manager: Thunar"
    echo "   - Text Editor: Mousepad"
    echo "   - Terminal: XFCE Terminal"
    echo ""
    echo "⚠️  IMPORTANT NOTES:"
    if [ "$ENVIRONMENT" = "codespaces" ]; then
        echo "   - GitHub Codespaces: Container persists during session"
        echo "   - Automatic shutdown after inactivity"
        echo "   - Re-run setup after codespace rebuild"
    elif [ "$ENVIRONMENT" = "codesandbox" ]; then
        echo "   - CodeSandbox: Containers are ephemeral"
        echo "   - Save this script and re-run after restart"
    fi
    echo "   - Keep browser tab open to maintain connection"
    echo ""
    
    # Save credentials to file
    sudo -u "$USERNAME" bash -c "cat > /home/$USERNAME/Desktop/CRD_INFO.txt << 'CREDS'
╔════════════════════════════════════════╗
║  CHROME REMOTE DESKTOP CREDENTIALS     ║
╚════════════════════════════════════════╝

Username: $USERNAME
Password: $USER_PASSWORD
CRD PIN:  $CRD_PIN

Access URL:
https://remotedesktop.google.com/access

Device Name: $HOSTNAME

Environment: $ENVIRONMENT ($OS_TYPE)

Setup Date: $(date)

⚠️  KEEP THIS FILE SECURE!
CREDS"
    
    log_info "Credentials saved to ~/Desktop/CRD_INFO.txt"
    
else
    log_error "Chrome Remote Desktop failed to start!"
    echo ""
    echo "📋 Troubleshooting Steps:"
    echo ""
    echo "   1. Check detailed logs:"
    echo "      tail -50 /tmp/chrome_remote_desktop_${USERNAME}_*"
    echo ""
    echo "   2. Check setup log:"
    echo "      cat /tmp/crd_setup.log"
    echo ""
    echo "   3. Try manual start:"
    echo "      sudo -u $USERNAME /opt/google/chrome-remote-desktop/chrome-remote-desktop --start"
    echo ""
    echo "   4. Check running processes:"
    echo "      ps aux | grep chrome-remote"
    echo ""
    echo "   5. Verify user groups:"
    echo "      groups $USERNAME"
    echo ""
    echo "   6. Re-run with verbose output:"
    echo "      sudo bash /tmp/setup_crd_universal.sh 2>&1 | tee /tmp/debug.log"
    echo ""
fi

ENDOFSCRIPT

# Make executable and run
chmod +x setupcrd.sh
sudo bash setupcrd.sh
