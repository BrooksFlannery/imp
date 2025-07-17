#!/bin/bash

# IMP (Implementation Management Platform) - Installation Script
# Makes it easy to install IMP and set up the alias

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

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Detect shell - prioritize $SHELL environment variable
detect_shell() {
    # First check the $SHELL environment variable (most reliable)
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
    
    # Fallback to checking shell variables
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

# Install IMP alias
install_alias() {
    local shell_type=$(detect_shell)
    local config_file=$(get_shell_config "$shell_type")
    
    log "Detected shell: $shell_type"
    log "Config file: $config_file"
    
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
        success "Removed existing alias"
    fi
    
    # Add new alias
    echo "" >> "$config_file"
    echo "# IMP (Implementation Management Platform) alias" >> "$config_file"
    echo "alias imp=\"$SCRIPT_DIR/imp.sh\"" >> "$config_file"
    
    success "Added IMP alias to $config_file"
    
    # Reload shell config
    log "Reloading shell configuration..."
    source "$config_file"
    
    success "IMP alias installed successfully!"
    log "You can now use 'imp' from any project directory"
    log "Try: imp --help"
}

# Validate IMP installation
validate_installation() {
    log "Validating IMP installation..."
    
    local missing_files=()
    
    for file in imp.sh imp-init.sh imp-plan.sh imp-spawner.sh imp-finish.sh imp-agent.prompt imp-plan-prompt.txt; do
        if [ ! -f "$SCRIPT_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        error "Missing required IMP files: ${missing_files[*]}"
        error "Please ensure you're running this script from the IMP directory"
        exit 1
    fi
    
    success "All required IMP files present"
}

# Main installation
main() {
    log "Installing IMP (Implementation Management Platform)..."
    log "Installation directory: $SCRIPT_DIR"
    
    # Validate installation
    validate_installation
    
    # Install alias
    install_alias
    
    echo ""
    success "Installation complete!"
    echo ""
    echo "Usage examples:"
    echo "  imp my-spec.md                    # Initialize or continue implementation"
    echo "  imp --help                        # Show help"
    echo "  imp version                       # Show version"
    echo ""
    echo "Note: You may need to restart your terminal or run 'source ~/.zshrc'"
    echo "      for the alias to be available in new shell sessions."
    echo ""
    echo "One-liner installation for others:"
    echo "  curl -sSL https://raw.githubusercontent.com/brooksflannery/imp/main/install.sh | bash"
}

# Run main function
main "$@" 