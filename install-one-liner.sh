#!/bin/bash

# IMP (Implementation Management Platform) - One-Liner Installer
# Copy-paste this entire script or run: curl -sSL https://raw.githubusercontent.com/brooksflannery/imp/main/install-one-liner.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[IMP INSTALL]${NC} $1"
}

error() {
    echo -e "${RED}[IMP ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[IMP SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[IMP WARNING]${NC} $1"
}

# IMP repository URL
IMP_REPO="https://github.com/brooksflannery/imp.git"
IMP_DIR="$HOME/.imp"

# Detect shell
detect_shell() {
    if [ -n "$SHELL" ]; then
        case "$SHELL" in
            */zsh)
                echo "zsh"
                return 0
                ;;
            */bash)
                echo "bash"
                return 0
                ;;
        esac
    fi
    
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Get shell config file
get_shell_config() {
    local shell_type="$1"
    case "$shell_type" in
        "zsh")
            echo "$HOME/.zshrc"
            ;;
        "bash")
            echo "$HOME/.bashrc"
            ;;
        *)
            error "Unsupported shell: $shell_type"
            exit 1
            ;;
    esac
}

# Check if alias already exists
check_existing_alias() {
    local config_file="$1"
    if grep -q "alias imp=" "$config_file"; then
        return 0  # Alias exists
    else
        return 1  # Alias doesn't exist
    fi
}

# Install IMP
install_imp() {
    local shell_type=$(detect_shell)
    local config_file=$(get_shell_config "$shell_type")
    
    log "Installing IMP (Implementation Management Platform)..."
    log "Detected shell: $shell_type"
    log "Config file: $config_file"
    
    # Create IMP directory if it doesn't exist
    if [ ! -d "$IMP_DIR" ]; then
        log "Cloning IMP repository..."
        git clone "$IMP_REPO" "$IMP_DIR"
        success "Cloned IMP repository to $IMP_DIR"
    else
        log "IMP directory already exists, updating..."
        cd "$IMP_DIR"
        git pull origin main
        success "Updated IMP repository"
    fi
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        warning "Config file $config_file does not exist. Creating it..."
        touch "$config_file"
    fi
    
    # Check if alias already exists
    if check_existing_alias "$config_file"; then
        warning "IMP alias already exists in $config_file"
        echo "Current alias:"
        grep "alias imp=" "$config_file"
        echo ""
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation cancelled"
            exit 0
        fi
        
        # Remove existing alias
        sed -i.bak '/alias imp=/d' "$config_file"
        sed -i.bak '/IMP (Implementation Management Platform) alias/d' "$config_file"
        success "Removed existing alias"
    fi
    
    # Add new alias
    echo "" >> "$config_file"
    echo "# IMP (Implementation Management Platform) alias" >> "$config_file"
    echo "alias imp=\"$IMP_DIR/imp.sh\"" >> "$config_file"
    
    success "Added IMP alias to $config_file"
    
    # Reload shell config
    log "Reloading shell configuration..."
    source "$config_file"
    
    success "IMP alias installed successfully!"
    log "You can now use 'imp' from any project directory"
    log "Try: imp --help"
}

# Main installation
main() {
    # Check for required dependencies
    if ! command -v git >/dev/null 2>&1; then
        error "Git is required but not installed. Please install Git first."
        exit 1
    fi
    
    # Install IMP
    install_imp
    
    echo ""
    success "Installation complete!"
    echo ""
    echo "Usage examples:"
    echo "  imp my-spec.md                    # Initialize or continue implementation"
    echo "  imp --help                        # Show help"
    echo "  imp version                       # Show version"
    echo ""
    echo "Note: You may need to restart your terminal or run 'source $config_file'"
    echo "      for the alias to be available in new shell sessions."
}

# Run main function
main "$@" 