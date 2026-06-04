#!/bin/bash

# Brave Browser installation script (no sudo required)
# Extracts from .deb package which is available on GitHub

set -e  # Keep error handling

# Configuration
BRAVE_VERSION="latest"
INSTALL_DIR="$HOME/.local/share/brave"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
CONFIG_DIR="$HOME/.config/BraveSoftware"
CACHE_DIR="$HOME/.cache/BraveSoftware"

# Cleanup flags
CLEAN_OLD_INSTALL="yes"
CLEAN_CONFIG="no"
CLEAN_CACHE="yes"
BACKUP_CONFIG="yes"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Helper function to check if directory exists and is non-empty
dir_has_content() {
    local dir="$1"
    [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]
}

# Clean up old installation
clean_old_installation() {
    print_status "Cleaning up old Brave installation files..."
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_info "✓ Removed $INSTALL_DIR"
    fi
    
    if [ -f "$BIN_DIR/brave" ] || [ -L "$BIN_DIR/brave" ]; then
        rm -f "$BIN_DIR/brave"
        print_info "✓ Removed launcher"
    fi
    
    if [ -f "$DESKTOP_DIR/brave-browser.desktop" ]; then
        rm -f "$DESKTOP_DIR/brave-browser.desktop"
        print_info "✓ Removed desktop entry"
    fi
}

# Backup configuration
backup_config() {
    if [ "$BACKUP_CONFIG" != "yes" ]; then
        return 0
    fi
    
    local backup_dir="$HOME/.brave_backup_$(date +%Y%m%d_%H%M%S)"
    local has_backup=false
    
    print_status "Checking for existing Brave configuration..."
    
    # Use the helper function to check directories safely
    if dir_has_content "$CONFIG_DIR"; then
        print_info "Found configuration to backup"
        mkdir -p "$backup_dir" 2>/dev/null
        cp -r "$CONFIG_DIR" "$backup_dir/" 2>/dev/null && has_backup=true
    fi
    
    if dir_has_content "$CACHE_DIR"; then
        if [ "$has_backup" = false ]; then
            mkdir -p "$backup_dir" 2>/dev/null
        fi
        cp -r "$CACHE_DIR" "$backup_dir/" 2>/dev/null && has_backup=true
    fi
    
    if [ "$has_backup" = true ]; then
        print_status "✓ Backup completed at $backup_dir"
    else
        print_info "No existing configuration to backup"
    fi
}

# Clean config and cache
clean_config_and_cache() {
    if [ "$CLEAN_CONFIG" = "yes" ] && [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        print_status "✓ Config removed"
    fi
    
    if [ "$CLEAN_CACHE" = "yes" ] && [ -d "$CACHE_DIR" ]; then
        rm -rf "$CACHE_DIR"
        print_status "✓ Cache removed"
    fi
}

# Main cleanup
perform_cleanup() {
    echo ""
    print_info "=========================================="
    print_info "Starting Brave cleanup process"
    print_info "=========================================="
    
    # Backup config (won't fail if nothing to backup)
    backup_config || true  # Don't exit if backup fails
    
    # Clean config and cache
    clean_config_and_cache || true
    
    # Clean old installation
    clean_old_installation || true
    
    # Kill Brave processes if running (don't fail if none)
    if pgrep -u "$USER" "brave" > /dev/null 2>&1; then
        pkill -u "$USER" "brave" 2>/dev/null || true
        print_status "✓ Brave processes terminated"
    else
        print_info "No Brave processes running"
    fi
    
    print_status "Cleanup completed!"
    echo ""
}

# Create directories
create_directories() {
    print_status "Creating directories..."
    mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR"
    print_status "✓ Directories created"
}

# Detect platform
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    
    case "$OS" in
        Linux) OS="linux" ;;
        *) print_error "Unsupported OS: $OS"; exit 1 ;;
    esac
    
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) 
            print_warning "Unknown architecture: $ARCH, defaulting to amd64"
            ARCH="amd64"
            ;;
    esac
    
    print_status "Detected platform: $OS-$ARCH"
}

# Get latest version
get_latest_version() {
    if [ "$BRAVE_VERSION" = "latest" ]; then
        print_status "Fetching latest Brave version..."
        
        # Try GitHub API first
        LATEST_RELEASE=$(curl -s https://api.github.com/repos/brave/brave-browser/releases/latest 2>/dev/null)
        BRAVE_VERSION=$(echo "$LATEST_RELEASE" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 | sed 's/^v//')
        
        # If that fails, try an alternative approach
        if [ -z "$BRAVE_VERSION" ]; then
            print_info "GitHub API failed, trying alternative method..."
            BRAVE_VERSION=$(curl -s https://api.github.com/repos/brave/brave-browser/releases 2>/dev/null | grep -o '"tag_name": *"v[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
        fi
        
        if [ -z "$BRAVE_VERSION" ]; then
            # Fallback to known version
            print_warning "Could not fetch latest version, using 1.90.128"
            BRAVE_VERSION="1.90.128"
        else
            print_status "Latest version: $BRAVE_VERSION"
        fi
    fi
}

# Check if file is a valid deb package
is_valid_deb() {
    local file="$1"
    [ -f "$file" ] && file "$file" 2>/dev/null | grep -q "Debian binary package"
}

# Download and extract Brave from .deb package
download_brave() {
    local temp_dir=$(mktemp -d)
    local download_success=false
    local deb_file=""
    
    print_status "Downloading Brave Browser v${BRAVE_VERSION} for ${OS}-${ARCH}..."
    
    cd "$temp_dir"
    
    # Try different .deb package naming patterns
    local patterns=(
        "brave-browser_${BRAVE_VERSION}_${ARCH}.deb"
        "brave-browser-${BRAVE_VERSION}-${ARCH}.deb"
        "brave-browser_${BRAVE_VERSION}_amd64.deb"
    )
    
    for pattern in "${patterns[@]}"; do
        local download_url="https://github.com/brave/brave-browser/releases/download/v${BRAVE_VERSION}/${pattern}"
        print_info "Trying: $pattern"
        
        # Download and check if successful
        if curl -L -s -o "$pattern" -w "%{http_code}" "$download_url" 2>/dev/null | grep -q "200"; then
            if is_valid_deb "$pattern"; then
                download_success=true
                deb_file="$pattern"
                print_status "✓ Successfully downloaded: $pattern"
                break
            else
                # Remove invalid file
                rm -f "$pattern"
            fi
        fi
    done
    
    if [ "$download_success" = false ]; then
        print_error "Could not download .deb package"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_status "Extracting .deb package..."
    
    # Check for ar command
    if ! command -v ar &> /dev/null; then
        print_error "ar command not found. Please install binutils."
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract .deb (ar might fail if file is corrupted)
    if ! ar x "$deb_file" 2>/dev/null; then
        print_error "Failed to extract .deb package"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find and extract data.tar.*
    local data_tar=$(find . -maxdepth 1 -type f -name "data.tar.*" 2>/dev/null | head -1)
    
    if [ -z "$data_tar" ]; then
        print_error "No data.tar file found in .deb"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract based on compression type
    if [[ "$data_tar" == *.xz ]]; then
        tar -xf "$data_tar" 2>/dev/null
    elif [[ "$data_tar" == *.gz ]]; then
        tar -zxf "$data_tar" 2>/dev/null
    elif [[ "$data_tar" == *.bz2 ]]; then
        tar -jxf "$data_tar" 2>/dev/null
    else
        tar -xf "$data_tar" 2>/dev/null
    fi
    
    # Find the brave binary
    local brave_bin=$(find . -path "*/opt/brave.com/brave/brave" -type f 2>/dev/null | head -1)
    
    if [ -z "$brave_bin" ]; then
        brave_bin=$(find . -name "brave" -type f 2>/dev/null | head -1)
    fi
    
    if [ -z "$brave_bin" ]; then
        print_error "Could not find brave binary in extracted .deb"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_status "Copying Brave files to $INSTALL_DIR..."
    
    # Get the directory containing brave binary
    local brave_dir=$(dirname "$brave_bin")
    
    # Copy the entire brave directory structure
    cp -r "$brave_dir"/* "$INSTALL_DIR/" 2>/dev/null || true
    
    # Copy additional resource directories
    local resources_dir=$(find . -path "*/usr/share/brave*" -type d 2>/dev/null | head -1)
    if [ -n "$resources_dir" ] && [ -d "$resources_dir" ]; then
        cp -r "$resources_dir"/* "$INSTALL_DIR/" 2>/dev/null || true
    fi
    
    # Copy additional libraries if needed
    local lib_dir=$(find . -path "*/usr/lib/brave*" -type d 2>/dev/null | head -1)
    if [ -n "$lib_dir" ] && [ -d "$lib_dir" ]; then
        cp -r "$lib_dir"/* "$INSTALL_DIR/" 2>/dev/null || true
    fi
    
    # Ensure binary is executable
    if [ -f "$INSTALL_DIR/brave" ]; then
        chmod +x "$INSTALL_DIR/brave"
    elif [ -f "$INSTALL_DIR/brave-browser" ]; then
        chmod +x "$INSTALL_DIR/brave-browser"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    # Verify the installation
    if [ -f "$INSTALL_DIR/brave" ] || [ -f "$INSTALL_DIR/brave-browser" ]; then
        print_status "✓ Brave extracted successfully"
        return 0
    else
        print_error "Brave binary not found after extraction"
        return 1
    fi
}

# Create launcher script
create_launcher() {
    local launcher="$BIN_DIR/brave"
    
    print_status "Creating launcher script..."
    
    cat > "$launcher" << 'EOF'
#!/bin/bash
# Brave Browser launcher

INSTALL_DIR="$HOME/.local/share/brave"

# Set LD_LIBRARY_PATH to include Brave's libraries if needed
if [ -d "$INSTALL_DIR/lib" ]; then
    export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
fi

# Try different binary names
if [ -f "$INSTALL_DIR/brave" ]; then
    exec "$INSTALL_DIR/brave" "$@"
elif [ -f "$INSTALL_DIR/brave-browser" ]; then
    exec "$INSTALL_DIR/brave-browser" "$@"
else
    # Try to find brave binary recursively
    BRAVE_BIN=$(find "$INSTALL_DIR" -name "brave" -type f -executable 2>/dev/null | head -1)
    if [ -n "$BRAVE_BIN" ]; then
        exec "$BRAVE_BIN" "$@"
    else
        echo "Error: Brave executable not found in $INSTALL_DIR"
        echo "Please reinstall Brave using the installation script."
        exit 1
    fi
fi
EOF
    
    chmod +x "$launcher"
    
    if [ -f "$launcher" ] && [ -x "$launcher" ]; then
        print_status "✓ Launcher created at $launcher"
        return 0
    else
        print_error "Failed to create launcher"
        return 1
    fi
}

# Install icon
install_icon() {
    print_status "Installing Brave icon..."
    
    local icon_found=false
    
    # Check in installation directory
    for icon in $(find "$INSTALL_DIR" -name "*.png" -size +10k 2>/dev/null | grep -i "brave\|product_logo" | head -3); do
        if [ -f "$icon" ]; then
            cp "$icon" "$ICON_DIR/brave-browser.png" 2>/dev/null && icon_found=true && break
        fi
    done
    
    # If not found, download from official source
    if [ "$icon_found" = false ]; then
        curl -s -o "$ICON_DIR/brave-browser.png" "https://brave.com/static-assets/images/brave-logo-icon.png" && icon_found=true
    fi
    
    if [ "$icon_found" = true ]; then
        print_status "✓ Icon installed"
        return 0
    else
        print_warning "Could not install icon"
        return 0  # Not a fatal error
    fi
}

# Create desktop entry
create_desktop_entry() {
    local desktop_file="$DESKTOP_DIR/brave-browser.desktop"
    
    print_status "Creating desktop entry..."
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Brave Browser
GenericName=Web Browser
Comment=Fast, secure, and private web browser
Exec=$BIN_DIR/brave %U
Icon=$ICON_DIR/brave-browser.png
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;
StartupWMClass=Brave-browser
StartupNotify=true
EOF
    
    chmod +x "$desktop_file"
    
    if [ -f "$desktop_file" ]; then
        print_status "✓ Desktop entry created"
        return 0
    else
        print_warning "Could not create desktop entry"
        return 0  # Not a fatal error
    fi
}

# Update PATH in bashrc
update_bashrc() {
    local bashrc="$HOME/.bashrc"
    local path_export='export PATH="$HOME/.local/bin:$PATH"'
    
    # Check if PATH already contains .local/bin
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        # Check if bashrc exists and doesn't have the entry
        if [ -f "$bashrc" ]; then
            if ! grep -q "\.local/bin" "$bashrc" 2>/dev/null; then
                echo "" >> "$bashrc"
                echo "# Added by Brave installer" >> "$bashrc"
                echo "$path_export" >> "$bashrc"
                print_status "✓ PATH added to .bashrc"
            fi
        else
            # Create bashrc if it doesn't exist
            echo "$path_export" > "$bashrc"
            print_status "✓ .bashrc created with PATH"
        fi
    else
        print_info "~/.local/bin already in PATH"
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local errors=0
    
    # Check launcher
    if [ ! -f "$BIN_DIR/brave" ] || [ ! -x "$BIN_DIR/brave" ]; then
        print_error "Launcher not found or not executable"
        errors=$((errors + 1))
    else
        print_status "✓ Launcher is ready"
    fi
    
    # Check brave binary
    local brave_bin=$(find "$INSTALL_DIR" -name "brave" -type f -executable 2>/dev/null | head -1)
    if [ -z "$brave_bin" ]; then
        print_error "Brave binary not found in $INSTALL_DIR"
        errors=$((errors + 1))
    else
        print_status "✓ Brave binary found: $brave_bin"
        
        # Test run with --version (don't fail if it doesn't work)
        if "$brave_bin" --version &> /dev/null; then
            local version=$("$brave_bin" --version 2>&1)
            print_status "✓ $version"
        else
            print_warning "Could not get version, but binary exists"
        fi
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "✓ Installation verified successfully"
        return 0
    else
        print_error "Installation verification failed with $errors error(s)"
        return 1
    fi
}

# Main function
main() {
    echo ""
    print_info "=========================================="
    print_info "Brave Browser Installation Script"
    print_info "=========================================="
    
    echo ""
    read -p "Remove old Brave files before installing? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        perform_cleanup
    else
        print_info "Skipping cleanup"
        echo ""
    fi
    
    print_info "Starting installation..."
    echo ""
    
    create_directories
    detect_platform
    get_latest_version
    
    if download_brave; then
        print_status "✓ Brave downloaded and extracted successfully"
    else
        print_error "Failed to download Brave Browser"
        exit 1
    fi
    
    create_launcher
    install_icon
    create_desktop_entry
    update_bashrc
    
    if verify_installation; then
        echo ""
        print_status "Installation complete!"
        echo "================================================"
        echo ""
        print_status "To use Brave Browser:"
        echo "  1. Run: source ~/.bashrc (or open new terminal)"
        echo "  2. Type: brave"
        echo ""
        print_status "Or run directly: $BIN_DIR/brave"
        echo ""
        
        export PATH="$HOME/.local/bin:$PATH"
        
        read -p "Launch Brave Browser now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Launching Brave Browser..."
            "$BIN_DIR/brave" &
            sleep 2
            print_status "Brave Browser launched!"
        fi
    else
        print_error "Installation failed. Please check the errors above."
        exit 1
    fi
}

# Run main
main
