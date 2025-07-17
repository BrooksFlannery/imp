#!/bin/bash

# IMP (Implementation Management Platform) - Uninstall Script
# Removes IMP from the user's system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[IMP UNINSTALL]${NC} $1"
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

# IMP installation directory
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

# Remove alias from shell config
remove_alias() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        warning "Config file $config_file does not exist"
        return 0
    fi
    
    # Check if alias exists
    if grep -q "alias imp=" "$config_file"; then
        log "Removing IMP alias from $config_file"
        
        # Create backup
        cp "$config_file" "$config_file.imp-backup-$(date +%Y%m%d-%H%M%S)"
        
        # Remove alias and comment lines
        sed -i.bak '/alias imp=/d' "$config_file"
        sed -i.bak '/IMP (Implementation Management Platform) alias/d' "$config_file"
        
        # Remove empty lines that might be left
        sed -i.bak '/^$/d' "$config_file"
        
        success "Removed IMP alias from $config_file"
        log "Backup created at: $config_file.imp-backup-$(date +%Y%m%d-%H%M%S)"
    else
        log "No IMP alias found in $config_file"
    fi
}

# Remove IMP installation directory
remove_imp_dir() {
    if [ -d "$IMP_DIR" ]; then
        log "Removing IMP installation directory: $IMP_DIR"
        rm -rf "$IMP_DIR"
        success "Removed IMP installation directory"
    else
        log "IMP installation directory not found: $IMP_DIR"
    fi
}

# Check for other IMP installations
check_other_installations() {
    local other_locations=()
    
    # Check for binary in ~/bin
    if [ -f "$HOME/bin/imp" ]; then
        other_locations+=("$HOME/bin/imp")
    fi
    
    # Check for binary in /usr/local/bin
    if [ -f "/usr/local/bin/imp" ]; then
        other_locations+=("/usr/local/bin/imp")
    fi
    
    # Check for binary in /opt/homebrew/bin (Apple Silicon Homebrew)
    if [ -f "/opt/homebrew/bin/imp" ]; then
        other_locations+=("/opt/homebrew/bin/imp")
    fi
    
    # Check for binary in /usr/local/bin (Intel Homebrew)
    if [ -f "/usr/local/bin/imp" ]; then
        other_locations+=("/usr/local/bin/imp")
    fi
    
    if [ ${#other_locations[@]} -ne 0 ]; then
        warning "Found other IMP installations:"
        for location in "${other_locations[@]}"; do
            echo "  - $location"
        done
        echo ""
        read -p "Do you want to remove these as well? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for location in "${other_locations[@]}"; do
                log "Removing: $location"
                rm -f "$location"
                success "Removed: $location"
            done
        fi
    fi
}

# Main uninstall function
main() {
    log "Uninstalling IMP (Implementation Management Platform)..."
    
    # Detect shell
    local shell_type=$(detect_shell)
    local config_file=$(get_shell_config "$shell_type")
    
    log "Detected shell: $shell_type"
    log "Config file: $config_file"
    
    # Confirm uninstall
    echo ""
    warning "This will remove IMP from your system:"
    echo "  - Remove IMP alias from $config_file"
    echo "  - Delete IMP installation directory: $IMP_DIR"
    echo "  - Remove any other IMP binaries found"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstall cancelled"
        exit 0
    fi
    
    # Remove alias from shell config
    remove_alias "$config_file"
    
    # Remove IMP installation directory
    remove_imp_dir
    
    # Check for other installations
    check_other_installations
    
    # Reload shell config to remove alias from current session
    log "Reloading shell configuration..."
    source "$config_file" 2>/dev/null || true
    
    echo ""
    success "IMP has been uninstalled successfully!"
    echo ""
    echo "To complete the uninstall:"
    echo "  1. Restart your terminal or run 'source $config_file'"
    echo "  2. The 'imp' command will no longer be available"
    echo ""
    echo "If you want to reinstall IMP later, run:"
    echo "  curl -sSL https://raw.githubusercontent.com/brooksflannery/imp/main/install-one-liner.sh | bash"
}

# Run main function
main "$@" 